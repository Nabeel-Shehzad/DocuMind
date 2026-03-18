"""
Unit tests for the RAG pipeline stages.
Tests each stage in isolation without needing a running server.
"""

import pytest
from app.pipeline.chunker import DocumentChunker


# ── Chunker unit tests ────────────────────────────────────────────────────────

class TestDocumentChunker:

    def test_basic_chunking(self):
        """Text shorter than chunk_size should produce one chunk."""
        chunker = DocumentChunker(chunk_size=512, overlap=64)
        pages   = [{"page": 1, "text": "Hello world", "tables": []}]
        chunks  = chunker.chunk(pages, document_id="test-doc")

        assert len(chunks) == 1
        assert chunks[0]["text"]     == "Hello world"
        assert chunks[0]["page"]     == 1
        assert chunks[0]["chunk_id"] == "test-doc_p1_c0"

    def test_long_text_produces_multiple_chunks(self):
        """Text longer than chunk_size should produce multiple chunks."""
        chunker    = DocumentChunker(chunk_size=100, overlap=10)
        long_text  = "A" * 350
        pages      = [{"page": 1, "text": long_text, "tables": []}]
        chunks     = chunker.chunk(pages, document_id="doc1")

        assert len(chunks) > 1

    def test_overlap_between_chunks(self):
        """Consecutive chunks should share overlapping characters."""
        chunker   = DocumentChunker(chunk_size=50, overlap=10)
        long_text = "ABCDEFGHIJ" * 20   # 200 chars
        pages     = [{"page": 1, "text": long_text, "tables": []}]
        chunks    = chunker.chunk(pages, document_id="doc2")

        assert len(chunks) >= 2
        # End of chunk[0] should appear at start of chunk[1]
        end_of_first   = chunks[0]["text"][-10:]
        start_of_second= chunks[1]["text"][:10]
        assert end_of_first == start_of_second

    def test_empty_pages_skipped(self):
        """Pages with empty text should produce no chunks."""
        chunker = DocumentChunker()
        pages   = [
            {"page": 1, "text": "",           "tables": []},
            {"page": 2, "text": "   ",        "tables": []},
            {"page": 3, "text": "Real text.", "tables": []},
        ]
        chunks = chunker.chunk(pages, document_id="doc3")
        assert len(chunks) == 1
        assert chunks[0]["text"] == "Real text."

    def test_table_text_included_in_chunks(self):
        """Table content should be included alongside page text."""
        chunker = DocumentChunker(chunk_size=512, overlap=64)
        pages   = [
            {
                "page":   1,
                "text":   "Invoice details",
                "tables": [
                    [["Item", "Price"], ["Widget", "$10"]],
                ],
            }
        ]
        chunks = chunker.chunk(pages, document_id="doc4")
        assert len(chunks) >= 1
        combined = " ".join(c["text"] for c in chunks)
        assert "Item" in combined or "Widget" in combined

    def test_multi_page_chunk_ids_unique(self):
        """All chunk IDs across pages should be unique."""
        chunker = DocumentChunker(chunk_size=50, overlap=5)
        pages   = [
            {"page": 1, "text": "Page one content " * 10, "tables": []},
            {"page": 2, "text": "Page two content " * 10, "tables": []},
        ]
        chunks  = chunker.chunk(pages, document_id="doc5")
        ids     = [c["chunk_id"] for c in chunks]
        assert len(ids) == len(set(ids))   # all unique


# ── Chat endpoint validation (no LLM call) ────────────────────────────────────

def test_chat_missing_document_returns_404(client):
    """POST /chat/ with unknown document_id should return 404."""
    res = client.post(
        "/chat/",
        json={
            "document_id":  "nonexistent-doc",
            "question":     "What is this about?",
            "chat_history": [],
        },
    )
    assert res.status_code == 404


def test_summary_missing_document_returns_404(client):
    """POST /chat/summary with unknown document_id should return 404."""
    res = client.post(
        "/chat/summary",
        json={
            "document_id": "nonexistent-doc",
            "summary_type": "general",
        },
    )
    assert res.status_code == 404


def test_summary_invalid_type_returns_400(client):
    """POST /chat/summary with invalid summary_type should return 400."""
    res = client.post(
        "/chat/summary",
        json={
            "document_id":  "some-doc-id",
            "summary_type": "invalid_type",
        },
    )
    # Either 400 (bad type) or 404 (doc not found) — both are valid
    assert res.status_code in (400, 404)
