"""
Chat Routes — Phase 4 (auth-protected)
POST /chat/         — streaming RAG Q&A
POST /chat/summary  — generate document summary
"""

from fastapi import APIRouter, HTTPException, Depends
from fastapi.responses import StreamingResponse

from app.models.schemas         import ChatRequest, SummaryRequest, SummaryResponse
from app.pipeline.claude_engine import ClaudeEngine
from app.pipeline.ingestion     import IngestionPipeline
from app.core.auth              import get_current_user_id
import logging

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/chat", tags=["Chat"])

engine   = ClaudeEngine()
pipeline = IngestionPipeline()


@router.post("/")
def chat(
    request: ChatRequest,
    user_id: str = Depends(get_current_user_id),
):
    doc = pipeline.get_document(request.document_id, user_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")

    return StreamingResponse(
        engine.stream_chat(
            document_id=request.document_id,
            question=request.question,
            chat_history=request.chat_history,
        ),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
        },
    )


@router.post("/summary", response_model=SummaryResponse)
def summarize(
    request: SummaryRequest,
    user_id: str = Depends(get_current_user_id),
):
    doc = pipeline.get_document(request.document_id, user_id)
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
        document_id=request.document_id,
        summary_type=request.summary_type,
        summary=result["summary"],
        structured_data=result.get("structured_data"),
    )
