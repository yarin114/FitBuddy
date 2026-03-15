"""
Supabase JWT verification.

Supabase issues HS256 JWTs signed with the project's JWT secret
(Project Settings → API → JWT Secret).

Usage:
    from app.core.supabase_auth import verify_supabase_token

    claims = verify_supabase_token(raw_token)
    supabase_uid = claims["sub"]   # UUID string — matches users.supabase_uid
"""

import logging

import jwt  # PyJWT

from app.core.config import get_settings

logger = logging.getLogger(__name__)


def verify_supabase_token(id_token: str) -> dict:
    """
    Decode and verify a Supabase JWT.

    Returns the decoded claims dict (includes ``sub`` = Supabase user UUID).

    Raises ``jwt.PyJWTError`` (and subclasses) on any verification failure —
    callers should catch and raise HTTP 401.
    """
    settings = get_settings()
    return jwt.decode(
        id_token,
        settings.supabase_jwt_secret,
        algorithms=["HS256"],
        audience="authenticated",
    )
