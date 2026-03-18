# DocuMind AI

> **Intelligent Document Processing** — Upload invoices, contracts, and reports, then ask questions and get AI-powered summaries in real time.

A full-stack portfolio project combining a **FastAPI RAG backend**, a **Flutter mobile frontend**, and a **GitHub Actions CI/CD pipeline**.

---

## What It Does

1. **Upload** a PDF or image document
2. The RAG pipeline extracts text & tables, chunks the content, and embeds it into a local vector store
3. **Chat** with the document — ask any question and get streaming AI answers with source citations
4. **Summarize** — choose from General, Key Points, Invoice Analysis, or Contract Review

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter App (GetX)                        │
│  Home → Upload → Chat → Summary                                  │
│  SSE streaming  │  Dio HTTP client  │  Dark theme                │
└───────────────────────────┬─────────────────────────────────────┘
                            │ REST + SSE
┌───────────────────────────▼─────────────────────────────────────┐
│                      FastAPI Backend                             │
│                                                                  │
│  ┌──────────────────── RAG Pipeline ──────────────────────────┐  │
│  │  Stage 1: Extract   PyMuPDF + pdfplumber + pytesseract     │  │
│  │  Stage 2: Chunk     Sliding-window with overlap            │  │
│  │  Stage 3: Embed     sentence-transformers (MiniLM-L6-v2)   │  │
│  │  Stage 4: Store     ChromaDB (local vector database)       │  │
│  │  Stage 5: Retrieve  Cosine similarity search               │  │
│  │  Stage 6: Generate  Claude API (streaming SSE)             │  │
│  └────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────────┐
│                   GitHub Actions CI/CD                           │
│  Flutter: analyze → test → build APK                            │
│  Backend: pytest → docker build → deploy to Render              │
└─────────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

### Backend
| Layer | Technology |
|-------|-----------|
| Framework | FastAPI + Uvicorn |
| LLM | Claude API (`claude-opus-4-5`) via Anthropic SDK |
| Embeddings | `sentence-transformers/all-MiniLM-L6-v2` (~92 MB, cached) |
| Vector DB | ChromaDB (local persistent) |
| PDF Parsing | PyMuPDF + pdfplumber + pytesseract (OCR) |
| Streaming | Server-Sent Events (SSE) |
| Runtime | Python 3.11+ |

### Frontend
| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x |
| State Management | GetX |
| HTTP Client | Dio |
| SSE Streaming | Dart `StreamTransformer` + `LineSplitter` |
| UI | Dark theme, shimmer loading, flutter_markdown |

### CI/CD
| Stage | Tool |
|-------|------|
| Version Control | Git + GitHub |
| Flutter Pipeline | GitHub Actions (analyze, test, APK build) |
| Backend Pipeline | GitHub Actions (pytest, Docker build, Render deploy) |
| Containerization | Docker |

---

## Project Structure

```
DocuMind/
├── backend/
│   ├── app/
│   │   ├── core/
│   │   │   └── config.py          # Pydantic settings from .env
│   │   ├── models/
│   │   │   └── schemas.py         # Request/Response Pydantic models
│   │   ├── pipeline/
│   │   │   ├── extractor.py       # Stage 1 — PDF/image text extraction
│   │   │   ├── chunker.py         # Stage 2 — Sliding-window chunking
│   │   │   ├── embedder.py        # Stage 3+4 — Embeddings + ChromaDB
│   │   │   ├── ingestion.py       # Pipeline orchestrator
│   │   │   └── claude_engine.py   # LLM streaming + summarization
│   │   ├── routes/
│   │   │   ├── documents.py       # Upload / list / get / delete
│   │   │   └── chat.py            # Chat (SSE) + Summary endpoints
│   │   └── main.py                # FastAPI app + CORS + routers
│   ├── tests/
│   │   ├── conftest.py            # Shared fixtures + test client
│   │   ├── test_health.py         # Health endpoint tests
│   │   ├── test_documents.py      # Document CRUD tests
│   │   └── test_pipeline.py       # Chunker unit tests
│   ├── Dockerfile
│   └── requirements.txt
│
├── frontend/
│   └── lib/
│       ├── app/
│       │   ├── app.dart           # GetMaterialApp + dark theme
│       │   ├── bindings.dart      # GetX dependency injection
│       │   └── routes.dart        # Named routes
│       ├── controllers/           # GetX controllers (business logic)
│       │   ├── document_controller.dart
│       │   ├── upload_controller.dart
│       │   ├── chat_controller.dart
│       │   └── summary_controller.dart
│       ├── core/
│       │   ├── config/api_config.dart
│       │   ├── services/
│       │   │   ├── api_service.dart    # Dio HTTP client
│       │   │   └── sse_service.dart    # SSE stream parser
│       │   └── theme/app_theme.dart
│       ├── models/                # DocumentModel, ChatMessageModel, SummaryModel
│       └── screens/
│           ├── home/              # Document list with shimmer
│           ├── upload/            # File picker + pipeline progress
│           ├── chat/              # SSE streaming chat UI
│           └── summary/          # 4-type summary selector
│
└── .github/
    └── workflows/
        ├── flutter.yml            # Flutter CI (analyze → test → APK)
        └── backend.yml            # Backend CI (pytest → Docker → deploy)
```

---

## Getting Started

### Prerequisites

- Python 3.11+
- Flutter 3.x SDK
- Tesseract OCR — [install guide](https://github.com/UB-Mannheim/tesseract/wiki)
- An [Anthropic API key](https://console.anthropic.com/)

### 1 — Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv venv
venv\Scripts\activate        # Windows
# source venv/bin/activate   # macOS/Linux

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env and add your ANTHROPIC_API_KEY

# Start the server
uvicorn app.main:app --reload --port 8000
```

API docs available at: `http://localhost:8000/docs`

### 2 — Flutter Setup

```bash
cd frontend

# Get packages
flutter pub get

# Run on Android emulator (ensure backend is running)
flutter run

# Build release APK
flutter build apk --release
```

> **Note:** The app connects to `http://10.0.2.2:8000` by default (Android emulator localhost). Update `frontend/lib/core/config/api_config.dart` for a real device or deployed backend.

### 3 — Run Backend Tests

```bash
cd backend
pytest tests/ -v
```

Expected: **20 tests passing** across health, documents, and pipeline stages.

---

## API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/` | Welcome + version |
| `GET` | `/health` | Health check |
| `POST` | `/documents/upload` | Upload PDF/image, run RAG ingestion |
| `GET` | `/documents/` | List all uploaded documents |
| `GET` | `/documents/{id}` | Get document metadata |
| `DELETE` | `/documents/{id}` | Delete document + embeddings |
| `POST` | `/chat/` | Chat with document (SSE streaming) |
| `POST` | `/chat/summary` | Generate document summary |

### Chat Request
```json
{
  "document_id": "abc-123",
  "question": "What is the total invoice amount?",
  "chat_history": []
}
```

### Summary Request
```json
{
  "document_id": "abc-123",
  "summary_type": "invoice"
}
```
`summary_type` options: `general` | `key_points` | `invoice` | `contract`

---

## RAG Pipeline — How It Works

```
PDF / Image
     │
     ▼
┌─────────────┐
│  EXTRACT    │  PyMuPDF text + pdfplumber tables + Tesseract OCR fallback
└──────┬──────┘
       ▼
┌─────────────┐
│   CHUNK     │  Sliding window: 512 tokens, 64 overlap, table text merged
└──────┬──────┘
       ▼
┌─────────────┐
│   EMBED     │  all-MiniLM-L6-v2 → 384-dim vectors
└──────┬──────┘
       ▼
┌─────────────┐
│   STORE     │  ChromaDB with document_id metadata filter
└──────┬──────┘
       ▼  (at query time)
┌─────────────┐
│  RETRIEVE   │  Top-K cosine similarity search scoped to document
└──────┬──────┘
       ▼
┌─────────────┐
│  GENERATE   │  Claude builds answer from context → streams SSE tokens
└─────────────┘
```

---

## Environment Variables

```env
# Required
ANTHROPIC_API_KEY=sk-ant-...

# Storage paths
UPLOAD_DIR=storage/uploads
CHROMA_DIR=storage/chroma_db

# RAG tuning
CHUNK_SIZE=512
CHUNK_OVERLAP=64
TOP_K_RESULTS=5
MAX_UPLOAD_SIZE_MB=20

# App
APP_ENV=development
```

---

## CI/CD Workflows

### Flutter Pipeline (`.github/workflows/flutter.yml`)
Triggers on any change inside `frontend/`

```
flutter analyze  →  flutter test --coverage  →  flutter build apk
```

### Backend Pipeline (`.github/workflows/backend.yml`)
Triggers on any change inside `backend/`

```
pytest (20 tests)  →  docker build (cached layers)  →  Render deploy (main only)
```

---

## Screenshots

> *Coming soon — add screenshots of the Upload, Chat, and Summary screens here.*

---

## What I Learned

- **RAG pipeline** — how chunking strategy and embedding quality directly affect answer accuracy
- **SSE streaming** — building real-time token-by-token responses end-to-end: FastAPI generator → Dio stream → Dart async generator → GetX reactive UI
- **GetX architecture** — controllers as single source of truth, `Rx` observables, permanent service bindings
- **Vector databases** — ChromaDB metadata filtering, cosine similarity, embedding caching
- **CI/CD** — job dependencies, Docker layer caching, deploy hooks, conditional steps

---

## License

MIT — feel free to fork, extend, and make it yours.
