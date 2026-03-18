"""
Pytest configuration and shared fixtures.
"""

import os
import shutil
import pytest
from fastapi.testclient import TestClient

# ── Set test environment BEFORE importing app ─────────────────────────────────
os.environ["ANTHROPIC_API_KEY"]    = "test-key-placeholder"
os.environ["APP_ENV"]              = "testing"
os.environ["UPLOAD_DIR"]           = "storage/test_uploads"
os.environ["CHROMA_DIR"]           = "storage/test_chroma"
os.environ["SUPABASE_URL"]         = "https://test.supabase.co"
os.environ["SUPABASE_ANON_KEY"]    = "test-anon-key"
os.environ["SUPABASE_SERVICE_KEY"] = "test-service-key"

# Create test directories immediately so the app can write to them
os.makedirs("storage/test_uploads", exist_ok=True)
os.makedirs("storage/test_chroma",  exist_ok=True)

TEST_USER_ID = "00000000-0000-0000-0000-000000000001"


@pytest.fixture(scope="session")
def client():
    """
    FastAPI test client — shared across the whole test session.
    The auth dependency is overridden so no real JWT is needed.
    """
    from app.main import app
    from app.core.auth import get_current_user_id

    # Override auth: every request is treated as TEST_USER_ID
    app.dependency_overrides[get_current_user_id] = lambda: TEST_USER_ID

    with TestClient(app) as c:
        yield c

    app.dependency_overrides.clear()


@pytest.fixture(autouse=True)
def clean_test_storage():
    """Recreate clean test storage dirs before each test."""
    for d in ["storage/test_uploads", "storage/test_chroma"]:
        shutil.rmtree(d, ignore_errors=True)
        os.makedirs(d, exist_ok=True)
    yield
    for d in ["storage/test_uploads", "storage/test_chroma"]:
        shutil.rmtree(d, ignore_errors=True)
