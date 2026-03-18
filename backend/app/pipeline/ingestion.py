"""
Ingestion Orchestrator — Phase 4 (Supabase-backed registry)
Ties together: Extractor → Chunker → Embedder → VectorStore
Document metadata is now stored in Supabase instead of a local JSON file.
"""

import uuid
from pathlib import Path
from datetime import datetime, timezone

from app.pipeline.extractor       import DocumentExtractor
from app.pipeline.chunker         import DocumentChunker
from app.pipeline.embedder        import VectorStore
from app.core.config              import settings
from app.core.supabase_client     import get_admin_client
import logging

logger = logging.getLogger(__name__)


class IngestionPipeline:
    """
    Full pipeline:
      1. Save uploaded file to disk
      2. Extract text / tables (PDF or image)
      3. Chunk into overlapping windows
      4. Embed + store in ChromaDB
      5. Register document metadata in Supabase
    """

    def __init__(self):
        self.extractor    = DocumentExtractor()
        self.chunker      = DocumentChunker()
        self.vector_store = VectorStore()

    # ── Internal helpers ───────────────────────────────────────────────────────

    def _db(self):
        return get_admin_client()

    # ── Public API ─────────────────────────────────────────────────────────────

    def ingest(self, file_path: str, original_filename: str,
               user_id: str, file_size_bytes: int = 0) -> dict:
        document_id = str(uuid.uuid4())
        logger.info(f"[Pipeline] START  {original_filename} → {document_id} (user={user_id})")

        # Stage 1: Extract
        logger.info("[Pipeline] Stage 1: Extracting ...")
        extracted  = self.extractor.extract(file_path)
        pages      = extracted["pages"]
        file_meta  = extracted["metadata"]

        # Stage 2: Chunk
        logger.info("[Pipeline] Stage 2: Chunking ...")
        chunks = self.chunker.chunk(pages, document_id)

        # Stage 3: Embed + Store in ChromaDB
        logger.info("[Pipeline] Stage 3: Embedding + storing ...")
        file_info   = {"filename": original_filename, "file_type": file_meta["file_type"]}
        chunk_count = self.vector_store.add_chunks(chunks, document_id, file_info)

        # Stage 4: Register in Supabase
        row = {
            "id":               document_id,
            "user_id":          user_id,
            "filename":         original_filename,
            "file_type":        file_meta["file_type"],
            "chunk_count":      chunk_count,
            "file_size_bytes":  file_size_bytes,
        }
        self._db().table("documents").insert(row).execute()

        logger.info(f"[Pipeline] DONE  {chunk_count} chunks for {document_id}")

        return {
            "document_id":    document_id,
            "filename":       original_filename,
            "file_type":      file_meta["file_type"],
            "page_count":     file_meta["page_count"],
            "chunk_count":    chunk_count,
            "file_path":      file_path,
            "file_size_bytes": file_size_bytes,
            "uploaded_at":    datetime.now(timezone.utc).isoformat(),
        }

    def delete(self, document_id: str, user_id: str) -> bool:
        # Fetch the row first (scoped by user for safety)
        result = (
            self._db()
            .table("documents")
            .select("*")
            .eq("id", document_id)
            .eq("user_id", user_id)
            .execute()
        )
        if not result.data:
            return False

        doc = result.data[0]

        # Remove from ChromaDB
        self.vector_store.delete_document(document_id)

        # Remove file from disk
        try:
            # Reconstruct file path from upload dir + any stored path clue
            # The file was stored as storage/uploads/<uuid><ext>
            # We just scan uploads dir for files whose name starts with document_id prefix
            upload_dir = Path(settings.upload_dir)
            for f in upload_dir.iterdir():
                if f.stem == document_id or document_id in f.stem:
                    f.unlink(missing_ok=True)
                    break
        except Exception as e:
            logger.warning(f"Could not delete file: {e}")

        # Delete from Supabase
        self._db().table("documents").delete().eq("id", document_id).eq("user_id", user_id).execute()
        return True

    def list_documents(self, user_id: str) -> list[dict]:
        result = (
            self._db()
            .table("documents")
            .select("*")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .execute()
        )
        return [self._row_to_doc(r) for r in (result.data or [])]

    def get_document(self, document_id: str, user_id: str) -> dict | None:
        result = (
            self._db()
            .table("documents")
            .select("*")
            .eq("id", document_id)
            .eq("user_id", user_id)
            .execute()
        )
        if not result.data:
            return None
        return self._row_to_doc(result.data[0])

    # ── Helpers ────────────────────────────────────────────────────────────────

    @staticmethod
    def _row_to_doc(row: dict) -> dict:
        return {
            "document_id":    row["id"],
            "filename":       row["filename"],
            "file_type":      row["file_type"],
            "chunk_count":    row["chunk_count"],
            "file_size_bytes": row.get("file_size_bytes", 0),
            "uploaded_at":    row["created_at"],
        }
