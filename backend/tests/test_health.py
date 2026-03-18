"""
Tests for health + root endpoints.
These run without any external dependencies.
"""


def test_root_returns_welcome(client):
    """GET / should return welcome message and version."""
    res = client.get("/")
    assert res.status_code == 200
    data = res.json()
    assert data["message"] == "Welcome to DocuMind AI"
    assert "version" in data
    assert data["docs"] == "/docs"


def test_health_returns_ok(client):
    """GET /health should return status ok."""
    res = client.get("/health")
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "ok"
    assert data["service"] == "DocuMind AI"
