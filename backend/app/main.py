"""
DocuMind AI — FastAPI Application Entry Point
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import documents, chat
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
)

app = FastAPI(
    title="DocuMind AI",
    description="Intelligent Document Processing Pipeline — RAG + Claude AI",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# ── CORS ─────────────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],       # tighten in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ───────────────────────────────────────────────────────────────────
app.include_router(documents.router)
app.include_router(chat.router)


# ── Health check ──────────────────────────────────────────────────────────────
@app.get("/health", tags=["Health"])
def health():
    return {"status": "ok", "service": "DocuMind AI"}


@app.get("/", tags=["Health"])
def root():
    return {
        "message": "Welcome to DocuMind AI",
        "docs":    "/docs",
        "version": "1.0.0",
    }
