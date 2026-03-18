"""
Chat Routes
POST /chat/         — streaming RAG Q&A
POST /chat/summary  — generate document summary
"""

from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse

from app.models.schemas      import ChatRequest, SummaryRequest, SummaryResponse
from app.pipeline.claude_engine import ClaudeEngine
from app.pipeline.ingestion  import IngestionPipeline
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/chat", tags=["Chat"])

engine   = ClaudeEngine()
pipeline = IngestionPipeline()


@router.post("/")
def chat(request: ChatRequest):
    """
    Stream an answer to a question about a document.
    Returns Server-Sent Events (SSE):
      - event: sources  → JSON list of retrieved chunks
      - data: <token>   → streamed answer tokens
      - event: done     → stream end signal
    """
    doc = pipeline.get_document(request.document_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")

    return StreamingResponse(
        engine.stream_chat(
            document_id  = request.document_id,
            question     = request.question,
            chat_history = request.chat_history,
        ),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",   # disable nginx buffering
        },
    )


@router.post("/summary", response_model=SummaryResponse)
def summarize(request: SummaryRequest):
    """
    Generate a document summary.
    summary_type: general | key_points | invoice | contract
    """
    doc = pipeline.get_document(request.document_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")

    valid_types = {"general", "key_points", "invoice", "contract"}
    if request.summary_type not in valid_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid summary_type. Choose from: {valid_types}",
        )

    result = engine.summarize(request.document_id, request.summary_type)

    return SummaryResponse(
        document_id     = request.document_id,
        summary_type    = request.summary_type,
        summary         = result["summary"],
        structured_data = result.get("structured_data"),
    )
