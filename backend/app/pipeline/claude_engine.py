"""
LLM Engine (Gemini)
Handles RAG-based Q&A and document summarization using Google Gemini.
Supports streaming responses via Server-Sent Events (SSE).
"""

import json
import google.generativeai as genai
from app.core.config       import settings
from app.pipeline.embedder import VectorStore
import logging

logger = logging.getLogger(__name__)

# Configure Gemini once at module load
genai.configure(api_key=settings.gemini_api_key)


# ── System prompts ────────────────────────────────────────────────────────────

RAG_SYSTEM_PROMPT = """You are DocuMind, an intelligent document assistant.
You answer questions strictly based on the provided document context.
- If the answer is in the context, answer clearly and cite the page number.
- If the answer is NOT in the context, say: "I couldn't find that in the document."
- Be concise, structured, and professional.
- When referencing data, quote it exactly from the context."""

SUMMARY_PROMPTS = {
    "general": """Provide a clear, structured summary of this document.
Include: main topic, key points, important facts, and conclusions.""",

    "key_points": """Extract the top 5-10 key points from this document.
Format as a numbered list. Be concise.""",

    "invoice": """Extract all structured data from this invoice:
- Invoice number, date, due date
- Vendor/client information
- Line items (description, quantity, unit price, total)
- Subtotal, taxes, grand total
Return as structured JSON.""",

    "contract": """Analyze this contract and extract:
- Parties involved
- Contract type and purpose
- Key terms and obligations
- Important dates and deadlines
- Payment terms (if any)
- Termination clauses
- Key risks or red flags
Return in a clear structured format.""",
}


class ClaudeEngine:
    """
    Handles all LLM interactions via Gemini:
      - Streaming RAG Q&A (question + retrieved context → streamed answer)
      - Document summarization (general, key_points, invoice, contract)
    """

    def __init__(self):
        self.vector_store = VectorStore()

    # ── RAG Chat (Streaming) ──────────────────────────────────────────────────

    def stream_chat(self, document_id: str, question: str, chat_history: list[dict]):
        """
        Generator that yields SSE-formatted text chunks.
        Usage in FastAPI: return StreamingResponse(engine.stream_chat(...))
        """
        try:
            # 1. Retrieve relevant chunks
            chunks = self.vector_store.search(question, document_id)
            if not chunks:
                yield "data: I couldn't find relevant content in the document for your question.\n\n"
                yield "event: done\ndata: [DONE]\n\n"
                return

            # 2. Build context block
            context_text = "\n\n".join(
                f"[Page {c['page']}]\n{c['text']}" for c in chunks
            )

            # 3. Stream sources metadata first
            sources = [{"page": c["page"], "text_preview": c["text"][:120] + "..."} for c in chunks]
            yield f"event: sources\ndata: {json.dumps(sources)}\n\n"

            # 4. Build Gemini contents (history + current question with context)
            contents = self._build_contents(question, context_text, chat_history)

            # 5. Stream answer tokens from Gemini
            model = genai.GenerativeModel(
                model_name=settings.gemini_model,
                system_instruction=RAG_SYSTEM_PROMPT,
            )
            response = model.generate_content(contents, stream=True)
            for chunk in response:
                if chunk.text:
                    escaped = chunk.text.replace("\n", "\\n")
                    yield f"data: {escaped}\n\n"

        except Exception as e:
            logger.error(f"stream_chat error: {e}", exc_info=True)
            yield f"data: Error: {str(e)}\n\n"

        yield "event: done\ndata: [DONE]\n\n"

    # ── Summarization (Non-streaming) ─────────────────────────────────────────

    def summarize(self, document_id: str, summary_type: str = "general") -> dict:
        """Generate a structured summary of a document."""
        chunks = self.vector_store.search(
            query="document summary overview main content",
            document_id=document_id,
            top_k=15,
        )

        if not chunks:
            return {"summary": "No content found for this document.", "structured_data": None}

        chunks.sort(key=lambda x: (x["page"], 0))
        full_text = "\n\n".join(f"[Page {c['page']}]\n{c['text']}" for c in chunks)

        prompt   = SUMMARY_PROMPTS.get(summary_type, SUMMARY_PROMPTS["general"])
        model    = genai.GenerativeModel(model_name=settings.gemini_model)
        response = model.generate_content(f"{prompt}\n\n--- DOCUMENT CONTENT ---\n{full_text}")
        summary_text = response.text

        structured_data = None
        if summary_type in ("invoice", "contract"):
            structured_data = self._try_parse_json(summary_text)

        return {"summary": summary_text, "structured_data": structured_data}

    # ── Helpers ───────────────────────────────────────────────────────────────

    @staticmethod
    def _build_contents(question: str, context: str, history: list[dict]) -> list[dict]:
        """Convert chat history + current question into Gemini contents format."""
        contents = []
        for msg in history:
            role = "model" if msg.get("role") == "assistant" else "user"
            contents.append({"role": role, "parts": [{"text": msg.get("content", "")}]})
        contents.append({
            "role": "user",
            "parts": [{"text": f"Document context:\n{context}\n\nQuestion: {question}"}],
        })
        return contents

    @staticmethod
    def _try_parse_json(text: str) -> dict | None:
        import re
        match = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", text, re.DOTALL)
        raw = match.group(1) if match else text
        try:
            return json.loads(raw)
        except Exception:
            return None
