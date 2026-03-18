"""
Embedder + Vector Store Pipeline Stage
Chunks → embeddings → ChromaDB
"""

import chromadb
from chromadb.config import Settings as ChromaSettings
from sentence_transformers import SentenceTransformer
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

# Singleton model — loaded once at startup
_embed_model: SentenceTransformer | None = None


def get_embed_model() -> SentenceTransformer:
    global _embed_model
    if _embed_model is None:
        logger.info("Loading embedding model: all-MiniLM-L6-v2 ...")
        _embed_model = SentenceTransformer("all-MiniLM-L6-v2")
    return _embed_model


class VectorStore:
    """
    Stage 3 of the ingestion pipeline.
    Embeds chunks and stores them in ChromaDB.
    Also handles similarity search for RAG retrieval.
    """

    COLLECTION_NAME = "documind_docs"

    def __init__(self):
        self.client = chromadb.PersistentClient(
            path=settings.chroma_dir,
            settings=ChromaSettings(anonymized_telemetry=False),
        )
        self.collection = self.client.get_or_create_collection(
            name=self.COLLECTION_NAME,
            metadata={"hnsw:space": "cosine"},
        )
        self.model = get_embed_model()

    # ── Ingest ───────────────────────────────────────────────────────────────

    def add_chunks(self, chunks: list[dict], document_id: str, file_meta: dict) -> int:
        """Embed and store chunks. Returns number of chunks stored."""
        if not chunks:
            return 0

        texts      = [c["text"]     for c in chunks]
        ids        = [c["chunk_id"] for c in chunks]
        metadatas  = [
            {
                "document_id": document_id,
                "page":        c["page"],
                "chunk_index": c["chunk_index"],
                "filename":    file_meta.get("filename", ""),
                "file_type":   file_meta.get("file_type", ""),
            }
            for c in chunks
        ]

        logger.info(f"[Embedder] Embedding {len(texts)} chunks ...")
        embeddings = self.model.encode(texts, show_progress_bar=False).tolist()

        # ChromaDB upsert (safe for re-ingestion)
        self.collection.upsert(
            ids=ids,
            documents=texts,
            embeddings=embeddings,
            metadatas=metadatas,
        )

        logger.info(f"[VectorStore] Stored {len(chunks)} chunks for doc {document_id}")
        return len(chunks)

    # ── Retrieve ─────────────────────────────────────────────────────────────

    def search(self, query: str, document_id: str, top_k: int = settings.top_k_results) -> list[dict]:
        """Embed query and retrieve top-k relevant chunks for a given document."""
        query_embedding = self.model.encode([query], show_progress_bar=False).tolist()[0]

        results = self.collection.query(
            query_embeddings=[query_embedding],
            n_results=top_k,
            where={"document_id": document_id},
            include=["documents", "metadatas", "distances"],
        )

        chunks = []
        for text, meta, distance in zip(
            results["documents"][0],
            results["metadatas"][0],
            results["distances"][0],
        ):
            chunks.append({
                "text":     text,
                "page":     meta.get("page"),
                "score":    round(1 - distance, 4),   # cosine similarity
                "filename": meta.get("filename"),
            })

        return chunks

    # ── Delete ───────────────────────────────────────────────────────────────

    def delete_document(self, document_id: str) -> int:
        """Remove all chunks belonging to a document."""
        existing = self.collection.get(where={"document_id": document_id})
        ids      = existing.get("ids", [])
        if ids:
            self.collection.delete(ids=ids)
        logger.info(f"[VectorStore] Deleted {len(ids)} chunks for doc {document_id}")
        return len(ids)

    def get_document_chunk_count(self, document_id: str) -> int:
        result = self.collection.get(where={"document_id": document_id})
        return len(result.get("ids", []))
