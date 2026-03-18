"""
Claude Engine
Handles RAG-based Q&A and document summarization using Anthropic Claude.
Supports streaming responses via Server-Sent Events (SSE).
"""

import anthropic
from app.core.config  import settings
from app.pipeline.embedder import VectorStore
import logging

logger = logging.getLogger(__name__)

client = anthropic.Anthropic(api_key=settings.anthropic_api_key)


# ── System prompts ───────────────────────────────────────────────────────────

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
    Handles all LLM interactions:
      - Streaming RAG Q&A (question + retrieved context → streamed answer)
      - Document summarization (general, key_points, invoice, contract)
    """

    def __init__(self):
        self.vector_store = VectorStore()

    # ── RAG Chat (Streaming) ─────────────────────────────────────────────────

    def stream_chat(self, document_id: str, question: str, chat_history: list[dict]):
        """
        Generator that yields SSE-formatted text chunks.
        Usage in FastAPI: return StreamingResponse(engine.stream_chat(...))
        """
        # 1. Retrieve relevant chunks
        chunks = self.vector_store.search(question, document_id)
        if not chunks:
            yield "data: I couldn't find relevant content in the document for your question.\n\n"
            return

        # 2. Build context block
        context_text = "\n\n".join(
            f"[Page {c['page']}]\n{c['text']}" for c in chunks
        )

        # 3. Build messages
        messages = self._build_messages(question, context_text, chat_history)

        # 4. Stream from Claude
        sources = [{"page": c["page"], "text_preview": c["text"][:120] + "..."} for c in chunks]

        # First, stream the source metadata as a special SSE event
        import json
        yield f"event: sources\ndata: {json.dumps(sources)}\n\n"

        # Then stream the answer tokens
        with client.messages.stream(
            model=settings.claude_model,
            max_tokens=settings.max_tokens,
            system=RAG_SYSTEM_PROMPT,
            messages=messages,
        ) as stream:
            for text in stream.text_stream:
                # Escape newlines for SSE format
                escaped = text.replace("\n", "\\n")
                yield f"data: {escaped}\n\n"

        yield "event: done\ndata: [DONE]\n\n"

    # ── Summarization (Non-streaming) ────────────────────────────────────────

    def summarize(self, document_id: str, summary_type: str = "general") -> dict:
        """Generate a structured summary of a document."""
        # Retrieve many chunks to cover the full document
        chunks = self.vector_store.search(
            query="document summary overview main content",
            document_id=document_id,
            top_k=15,
        )

        if not chunks:
            return {"summary": "No content found for this document.", "structured_data": None}

        # Sort by page to maintain reading order
        chunks.sort(key=lambda x: (x["page"], 0))
        full_text = "\n\n".join(f"[Page {c['page']}]\n{c['text']}" for c in chunks)

        prompt = SUMMARY_PROMPTS.get(summary_type, SUMMARY_PROMPTS["general"])

        response = client.messages.create(
            model=settings.claude_model,
            max_tokens=settings.max_tokens,
            messages=[
                {
                    "role": "user",
                    "content": f"{prompt}\n\n--- DOCUMENT CONTENT ---\n{full_text}",
                }
            ],
        )

        summary_text = response.content[0].text

        # For invoice/contract, try to parse structured JSON
        structured_data = None
        if summary_type in ("invoice", "contract"):
            structured_data = self._try_parse_json(summary_text)

        return {
            "summary":         summary_text,
            "structured_data": structured_data,
        }

    # ── Helpers ──────────────────────────────────────────────────────────────

    def _build_messages(
        self,
        question: str,
        context: str,
        history: list[dict],
    ) -> list[dict]:
        messages = list(history)   # preserve previous turns
        messages.append({
            "role": "user",
            "content": (
                f"Document context:\n{context}\n\n"
                f"Question: {question}"
            ),
        })
        return messages

    def _try_parse_json(self, text: str) -> dict | None:
        import json, re
        # Extract JSON block if wrapped in markdown
        match = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", text, re.DOTALL)
        raw = match.group(1) if match else text
        try:
            return json.loads(raw)
        except Exception:
            return None
