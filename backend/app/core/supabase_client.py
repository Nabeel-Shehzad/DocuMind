"""
Supabase client singleton.
- admin_client  : service_role key — bypasses RLS, used for all DB operations
- anon_client   : anon key — used only for JWT verification
"""

from supabase import create_client, Client
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

_admin_client: Client | None = None
_anon_client:  Client | None = None


def get_admin_client() -> Client:
    global _admin_client
    if _admin_client is None:
        if not settings.supabase_url or not settings.supabase_service_key:
            raise RuntimeError("SUPABASE_URL and SUPABASE_SERVICE_KEY must be set")
        _admin_client = create_client(settings.supabase_url, settings.supabase_service_key)
        logger.info("Supabase admin client initialised")
    return _admin_client


def get_anon_client() -> Client:
    global _anon_client
    if _anon_client is None:
        if not settings.supabase_url or not settings.supabase_anon_key:
            raise RuntimeError("SUPABASE_URL and SUPABASE_ANON_KEY must be set")
        _anon_client = create_client(settings.supabase_url, settings.supabase_anon_key)
        logger.info("Supabase anon client initialised")
    return _anon_client
