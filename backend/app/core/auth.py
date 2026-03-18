"""
FastAPI dependency: extracts and verifies a Supabase JWT from
the Authorization: Bearer <token> header.

Returns the authenticated user_id (UUID string).
"""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.core.supabase_client import get_anon_client
import logging

logger = logging.getLogger(__name__)

_bearer = HTTPBearer()


def get_current_user_id(
    credentials: HTTPAuthorizationCredentials = Depends(_bearer),
) -> str:
    """
    Verify the Supabase access token and return the user's UUID.
    Raises 401 if the token is missing, expired, or invalid.
    """
    token = credentials.credentials
    try:
        client = get_anon_client()
        response = client.auth.get_user(token)
        if response is None or response.user is None:
            raise ValueError("No user in response")
        return str(response.user.id)
    except Exception as e:
        logger.warning(f"JWT verification failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )
