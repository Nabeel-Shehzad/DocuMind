"""
Ingestion Orchestrator
Ties together: Extractor → Chunker → Embedder → VectorStore
"""

import uuid
import shutil
import json
from pathlib import Path
from datetime import datetime, timezone

from app.pipeline.extractor import DocumentExtractor
from app.pipeline.chunker   import DocumentChunker
from app.pipeline.embedder  import VectorStore
from app.core.config        import settings
import logging

logger = logging.getLogger(__name__)

# Simple JSON-file document registry (swapped for Supabase in Phase 3)
REGISTRY_PATH = Path(settings.chroma_dir) / "document_registry.json"


def _load_registry() -> dict:
    if REGISTRY_PATH.exists():
        return json.loads(REGISTRY_PATH.read_text())
    return {}


def _save_registry(registry: dict):
    REGISTRY_PATH.write_text(json.dumps(registry, indent=2, default=str))


class IngestionPipeline:
    """
    Full pipeline:
      1. Save uploaded file to disk
      2. Extract text / tables (PDF or image)
      3. Chunk into overlapping windows
      4. Embed + store in ChromaDB
      5. Register document metadata
    """

    def __init__(self):
        self.extractor   = DocumentExtractor()
        self.chunker     = DocumentChunker()
        self.vector_store = VectorStore()

    def ingest(self, file_path: str, original_filename: str) -> dict:
        document_id = str(uuid.uuid4())
        logger.info(f"[Pipeline] START ingestion: {original_filename} → {document_id}")

        # ── Stage 1: Extract ────────────────────────────────────────────────
        logger.info("[Pipeline] Stage 1: Extracting text ...")
        extracted = self.extractor.extract(file_path)
        pages      = extracted["pages"]
        file_meta  = extracted["metadata"]

        # ── Stage 2: Chunk ──────────────────────────────────────────────────
        logger.info("[Pipeline] Stage 2: Chunking ...")
        chunks = self.chunker.chunk(pages, document_id)

        # ── Stage 3: Embed + Store ──────────────────────────────────────────
        logger.info("[Pipeline] Stage 3: Embedding + storing ...")
        file_info = {
            "filename":  original_filename,
            "file_type": file_meta["file_type"],
        }
        chunk_count = self.vector_store.add_chunks(chunks, document_id, file_info)

        # ── Stage 4: Register ───────────────────────────────────────────────
        registry = _load_registry()
        registry[document_id] = {
            "document_id":   document_id,
            "filename":      original_filename,
            "file_type":     file_meta["file_type"],
            "page_count":    file_meta["page_count"],
            "chunk_count":   chunk_count,
            "file_path":     file_path,
            "uploaded_at":   datetime.now(timezone.utc).isoformat(),
        }
        _save_registry(registry)

        logger.info(f"[Pipeline] DONE: {chunk_count} chunks stored for {document_id}")
        return registry[document_id]

    def delete(self, document_id: str) -> bool:
        registry = _load_registry()
        if document_id not in registry:
            return False

        doc = registry.pop(document_id)

        # Remove from vector store
        self.vector_store.delete_document(document_id)

        # Remove file from disk
        try:
            Path(doc["file_path"]).unlink(missing_ok=True)
        except Exception as e:
            logger.warning(f"Could not delete file: {e}")

        _save_registry(registry)
        return True

    def list_documents(self) -> list[dict]:
        return list(_load_registry().values())

    def get_document(self, document_id: str) -> dict | None:
        return _load_registry().get(document_id)
