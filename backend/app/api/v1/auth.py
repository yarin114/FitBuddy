"""
Auth routes
------------
POST /api/v1/auth/register
  Called by Flutter immediately after Supabase sign-up.
  Creates the user row in PostgreSQL using the verified Supabase JWT.
  Idempotent: returns the existing row if the user already registered.
"""

import logging

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from app.core.dependencies import DBDep
from app.core.supabase_auth import verify_supabase_token
from app.models.user import User
from app.schemas.user import UserOnboardRequest, UserResponse
from app.services.macro_service import _calculate_macro_targets

from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from typing import Annotated
from fastapi import Depends

logger = logging.getLogger(__name__)
router = APIRouter()

_bearer = HTTPBearer(auto_error=True)


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(
    body: UserOnboardRequest,
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(_bearer)],
    db: DBDep,
) -> UserResponse:
    """
    Create a new user profile linked to the caller's Supabase UID.
    Idempotent: returns 200 if the user already exists.
    """
    try:
        claims = verify_supabase_token(credentials.credentials)
        supabase_uid: str = claims["sub"]
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired Supabase token.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Idempotency check
    result = await db.execute(select(User).where(User.supabase_uid == supabase_uid))
    existing = result.scalar_one_or_none()
    if existing:
        return UserResponse.from_orm(existing)

    # Calculate macro targets from physical profile (has sensible defaults for all fields)
    targets = _calculate_macro_targets(body)

    user = User(
        supabase_uid=supabase_uid,
        name=body.name,
        email=body.email,
        date_of_birth=body.date_of_birth,
        gender=body.gender,
        weight_kg=body.weight_kg,
        height_cm=body.height_cm,
        goal_weight_kg=body.goal_weight_kg,
        activity_level=body.activity_level,
        timezone=body.timezone,
        **targets,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    logger.info("New user registered: supabase_uid=%s", supabase_uid)
    return UserResponse.from_orm(user)
