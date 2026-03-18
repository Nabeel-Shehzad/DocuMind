"""
Pytest configuration and shared fixtures.
"""

import os
import shutil
import pytest
from fastapi.testclient import TestClient

# Set test environment BEFORE importing app (so config loads test values)
os.environ["ANTHROPIC_API_KEY"] = "test-key-placeholder"
os.environ["APP_ENV"]           = "testing"
os.environ["UPLOAD_DIR"]        = "storage/test_uploads"
os.environ["CHROMA_DIR"]        = "storage/test_chroma"

# Create test directories immediately so the app can write to them
os.makedirs("storage/test_uploads", exist_ok=True)
os.makedirs("storage/test_chroma",  exist_ok=True)


@pytest.fixture(scope="session")
def client():
    """FastAPI test client — shared across the whole test session."""
    from app.main import app
    with TestClient(app) as c:
        yield c


@pytest.fixture(autouse=True)
def clean_test_storage():
    """Recreate clean test storage dirs before each test."""
    for d in ["storage/test_uploads", "storage/test_chroma"]:
        shutil.rmtree(d, ignore_errors=True)
        os.makedirs(d, exist_ok=True)
    yield
    for d in ["storage/test_uploads", "storage/test_chroma"]:
        shutil.rmtree(d, ignore_errors=True)
