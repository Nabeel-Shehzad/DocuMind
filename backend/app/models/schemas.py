from pydantic import BaseModel
from typing import Optional
from datetime import datetime


# ── Upload ────────────────────────────────────────────────────────────────────

class UploadResponse(BaseModel):
    document_id: str
    filename: str
    file_type: str
    page_count: int
    chunk_count: int
    message: str


# ── Chat ──────────────────────────────────────────────────────────────────────

class ChatRequest(BaseModel):
    document_id: str
    question: str
    chat_history: list[dict] = []


class ChatResponse(BaseModel):
    answer: str
    sources: list[dict]
    document_id: str


# ── Summary ───────────────────────────────────────────────────────────────────

class SummaryRequest(BaseModel):
    document_id: str
    summary_type: str = "general"


class SummaryResponse(BaseModel):
    document_id: str
    summary_type: str
    summary: str
    structured_data: Optional[dict] = None


# ── Document management ───────────────────────────────────────────────────────

class DocumentInfo(BaseModel):
    document_id: str
    filename: str
    file_type: str
    chunk_count: int
    file_size_bytes: int = 0
    uploaded_at: datetime


class DeleteResponse(BaseModel):
    document_id: str
    message: str
