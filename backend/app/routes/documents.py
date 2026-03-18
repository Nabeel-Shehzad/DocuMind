"""
Document Routes
POST /documents/upload  — ingest a PDF or image
GET  /documents/        — list all documents
GET  /documents/{id}    — get document info
DELETE /documents/{id}  — delete document
"""

import shutil
import uuid
from pathlib import Path

from fastapi import APIRouter, UploadFile, File, HTTPException, status
from app.models.schemas    import UploadResponse, DocumentInfo, DeleteResponse
from app.pipeline.ingestion import IngestionPipeline
from app.core.config        import settings
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/documents", tags=["Documents"])

pipeline = IngestionPipeline()

ALLOWED_EXTENSIONS = {".pdf", ".png", ".jpg", ".jpeg", ".tiff", ".bmp", ".webp"}
MAX_BYTES = settings.max_upload_size_mb * 1024 * 1024


@router.post("/upload", response_model=UploadResponse, status_code=status.HTTP_201_CREATED)
async def upload_document(file: UploadFile = File(...)):
    """Upload and ingest a document (PDF or image)."""

    # Validate extension
    suffix = Path(file.filename).suffix.lower()
    if suffix not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type '{suffix}'. Allowed: {ALLOWED_EXTENSIONS}",
        )

    # Validate size
    content = await file.read()
    if len(content) > MAX_BYTES:
        raise HTTPException(
            status_code=413,
            detail=f"File too large. Max size: {settings.max_upload_size_mb} MB",
        )

    # Save to disk with a unique name
    safe_name = f"{uuid.uuid4()}{suffix}"
    save_path = Path(settings.upload_dir) / safe_name
    save_path.write_bytes(content)

    try:
        result = pipeline.ingest(str(save_path), file.filename)
    except Exception as e:
        save_path.unlink(missing_ok=True)   # clean up on failure
        logger.error(f"Ingestion failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Ingestion failed: {str(e)}")

    return UploadResponse(
        document_id = result["document_id"],
        filename    = result["filename"],
        file_type   = result["file_type"],
        page_count  = result["page_count"],
        chunk_count = result["chunk_count"],
        message     = "Document ingested successfully.",
    )


@router.get("/", response_model=list[DocumentInfo])
def list_documents():
    """Return all ingested documents."""
    return pipeline.list_documents()


@router.get("/{document_id}", response_model=DocumentInfo)
def get_document(document_id: str):
    """Get metadata for a single document."""
    doc = pipeline.get_document(document_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    return doc


@router.delete("/{document_id}", response_model=DeleteResponse)
def delete_document(document_id: str):
    """Delete a document and all its embeddings."""
    deleted = pipeline.delete(document_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Document not found")
    return DeleteResponse(document_id=document_id, message="Document deleted successfully.")
