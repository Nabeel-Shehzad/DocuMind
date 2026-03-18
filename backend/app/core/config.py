from pydantic_settings import BaseSettings
from pathlib import Path


class Settings(BaseSettings):
    # Gemini
    gemini_api_key: str

    # Supabase
    supabase_url: str = ""
    supabase_anon_key: str = ""
    supabase_service_key: str = ""   # service_role key — backend admin access

    # App
    app_env: str = "development"
    upload_dir: str = "storage/uploads"
    chroma_dir: str = "storage/chroma_db"
    max_upload_size_mb: int = 20

    # RAG
    chunk_size: int = 512
    chunk_overlap: int = 64
    top_k_results: int = 5

    # Gemini model
    gemini_model: str = "gemini-3-flash-preview"
    max_tokens: int = 2048

    class Config:
        env_file = ".env"


settings = Settings()

# Ensure storage directories exist
Path(settings.upload_dir).mkdir(parents=True, exist_ok=True)
Path(settings.chroma_dir).mkdir(parents=True, exist_ok=True)
