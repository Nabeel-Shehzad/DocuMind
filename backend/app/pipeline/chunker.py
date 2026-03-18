"""
Chunker Pipeline Stage
Raw pages → overlapping text chunks with metadata
"""

from app.core.config import settings
import logging

logger = logging.getLogger(__name__)


class DocumentChunker:
    """
    Stage 2 of the ingestion pipeline.
    Splits extracted page text into overlapping chunks for embedding.

    Each chunk: {"chunk_id": str, "text": str, "page": int, "chunk_index": int}
    """

    def __init__(
        self,
        chunk_size: int  = settings.chunk_size,
        overlap: int     = settings.chunk_overlap,
    ):
        self.chunk_size = chunk_size
        self.overlap    = overlap

    def chunk(self, pages: list[dict], document_id: str) -> list[dict]:
        chunks = []
        chunk_index = 0

        for page_data in pages:
            page_num = page_data["page"]
            text     = page_data["text"]

            # Include table data as plain text alongside page text
            table_text = self._tables_to_text(page_data.get("tables", []))
            full_text  = f"{text}\n\n{table_text}".strip() if table_text else text

            if not full_text:
                continue

            page_chunks = self._split_text(full_text)
            for chunk_text in page_chunks:
                chunks.append({
                    "chunk_id":    f"{document_id}_p{page_num}_c{chunk_index}",
                    "text":        chunk_text,
                    "page":        page_num,
                    "chunk_index": chunk_index,
                })
                chunk_index += 1

        logger.info(f"[Chunker] {len(chunks)} chunks from {len(pages)} pages")
        return chunks

    # ── Helpers ──────────────────────────────────────────────────────────────

    def _split_text(self, text: str) -> list[str]:
        """Sliding-window character split with overlap."""
        chunks = []
        start  = 0
        length = len(text)

        while start < length:
            end   = min(start + self.chunk_size, length)
            chunk = text[start:end].strip()
            if chunk:
                chunks.append(chunk)
            if end == length:
                break
            start += self.chunk_size - self.overlap   # slide forward with overlap

        return chunks

    def _tables_to_text(self, tables: list) -> str:
        """Convert pdfplumber table rows into readable plain text."""
        lines = []
        for table in tables:
            for row in table:
                row_text = " | ".join(str(cell) if cell else "" for cell in row)
                lines.append(row_text)
            lines.append("")          # blank line between tables
        return "\n".join(lines).strip()
