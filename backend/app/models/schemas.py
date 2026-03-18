from pydantic import BaseModel
from typing import Optional
from datetime import datetime


# ── Upload ──────────────────────────────────────────────────────────────────

class UploadResponse(BaseModel):
    document_id: str
    filename: str
    file_type: str
    page_count: int
    chunk_count: int
    message: str


# ── Chat ────────────────────────────────────────────────────────────────────

class ChatRequest(BaseModel):
    document_id: str
    question: str
    chat_history: list[dict] = []   # [{"role": "user"|"assistant", "content": "..."}]


class ChatResponse(BaseModel):
    answer: str
    sources: list[dict]             # [{page, text_preview}]
    document_id: str


# ── Summary ─────────────────────────────────────────────────────────────────

class SummaryRequest(BaseModel):
    document_id: str
    summary_type: str = "general"   # general | key_points | invoice | contract


class SummaryResponse(BaseModel):
    document_id: str
    summary_type: str
    summary: str
    structured_data: Optional[dict] = None


# ── Document management ──────────────────────────────────────────────────────

class DocumentInfo(BaseModel):
    document_id: str
    filename: str
    file_type: str
    page_count: int
    chunk_count: int
    uploaded_at: datetime


class DeleteResponse(BaseModel):
    document_id: str
    message: str
