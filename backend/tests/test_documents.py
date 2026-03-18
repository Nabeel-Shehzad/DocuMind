"""
Tests for the document management endpoints.
/documents/upload, /documents/, /documents/{id}, DELETE /documents/{id}
"""

import io
import pytest


# ── List documents ────────────────────────────────────────────────────────────

def test_list_documents_returns_list(client):
    """GET /documents/ should return a list (empty or not)."""
    res = client.get("/documents/")
    assert res.status_code == 200
    assert isinstance(res.json(), list)


# ── Upload validation ─────────────────────────────────────────────────────────

def test_upload_no_file_returns_422(client):
    """POST /documents/upload without a file should return 422."""
    res = client.post("/documents/upload")
    assert res.status_code == 422


def test_upload_unsupported_type_returns_400(client):
    """POST /documents/upload with a .txt file should return 400."""
    fake_file = io.BytesIO(b"hello world")
    res = client.post(
        "/documents/upload",
        files={"file": ("test.txt", fake_file, "text/plain")},
    )
    assert res.status_code == 400
    assert "Unsupported file type" in res.json()["detail"]


def test_upload_oversized_file_returns_413(client):
    """POST /documents/upload with a file > MAX_UPLOAD_SIZE_MB should return 413."""
    # Create a fake file larger than 20 MB
    big_content = b"0" * (21 * 1024 * 1024)
    res = client.post(
        "/documents/upload",
        files={"file": ("big.pdf", io.BytesIO(big_content), "application/pdf")},
    )
    assert res.status_code == 413
    assert "too large" in res.json()["detail"].lower()


# ── Get / delete non-existent document ────────────────────────────────────────

def test_get_nonexistent_document_returns_404(client):
    """GET /documents/{id} for unknown id should return 404."""
    res = client.get("/documents/nonexistent-id-12345")
    assert res.status_code == 404


def test_delete_nonexistent_document_returns_404(client):
    """DELETE /documents/{id} for unknown id should return 404."""
    res = client.delete("/documents/nonexistent-id-12345")
    assert res.status_code == 404


# ── Upload a real minimal PDF ─────────────────────────────────────────────────

@pytest.fixture
def minimal_pdf_bytes():
    """Returns a minimal valid PDF file as bytes."""
    return (
        b"%PDF-1.4\n"
        b"1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n"
        b"2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n"
        b"3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] "
        b"/Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj\n"
        b"4 0 obj\n<< /Length 44 >>\nstream\n"
        b"BT /F1 12 Tf 100 700 Td (Hello DocuMind) Tj ET\n"
        b"endstream\nendobj\n"
        b"5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n"
        b"xref\n0 6\n0000000000 65535 f\n"
        b"trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n0\n%%EOF"
    )


def test_upload_valid_pdf_returns_201(client, minimal_pdf_bytes):
    """POST /documents/upload with a valid PDF should return 201 and document info."""
    res = client.post(
        "/documents/upload",
        files={"file": ("test_doc.pdf", io.BytesIO(minimal_pdf_bytes), "application/pdf")},
    )
    assert res.status_code == 201
    data = res.json()
    assert "document_id" in data
    assert data["filename"]   == "test_doc.pdf"
    assert data["file_type"]  == "pdf"
    assert data["chunk_count"] >= 0
    assert data["message"]    == "Document ingested successfully."
    return data["document_id"]


def test_uploaded_doc_appears_in_list(client, minimal_pdf_bytes):
    """After upload, document should appear in GET /documents/."""
    upload_res = client.post(
        "/documents/upload",
        files={"file": ("list_test.pdf", io.BytesIO(minimal_pdf_bytes), "application/pdf")},
    )
    assert upload_res.status_code == 201
    doc_id = upload_res.json()["document_id"]

    list_res = client.get("/documents/")
    assert list_res.status_code == 200
    ids = [d["document_id"] for d in list_res.json()]
    assert doc_id in ids


def test_delete_uploaded_doc(client, minimal_pdf_bytes):
    """After upload, document should be deletable."""
    upload_res = client.post(
        "/documents/upload",
        files={"file": ("delete_test.pdf", io.BytesIO(minimal_pdf_bytes), "application/pdf")},
    )
    assert upload_res.status_code == 201
    doc_id = upload_res.json()["document_id"]

    del_res = client.delete(f"/documents/{doc_id}")
    assert del_res.status_code == 200
    assert del_res.json()["message"] == "Document deleted successfully."

    # Confirm it's gone
    get_res = client.get(f"/documents/{doc_id}")
    assert get_res.status_code == 404
