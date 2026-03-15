from typing import Annotated, AsyncGenerator

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import AsyncSessionLocal
from app.core.firebase_admin import verify_firebase_token
from app.models.user import User

# Extracts "Bearer <token>" from the Authorization header.
# auto_error=True raises HTTP 403 automatically when the header is missing.
_bearer = HTTPBearer(auto_error=True)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    Yield a database session for the duration of a request.
    Rolls back on any unhandled exception so partial writes never persist.
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(_bearer)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    """
    Verify the Firebase ID token and return the matching User row.

    Raises HTTP 401 if the token is invalid/expired.
    Raises HTTP 404 if the Firebase UID has no matching user row
    (the client should trigger the onboarding flow in that case).
    """
    try:
        decoded = verify_firebase_token(credentials.credentials)
        firebase_uid: str = decoded["uid"]
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired authentication token.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    result = await db.execute(select(User).where(User.firebase_uid == firebase_uid))
    user = result.scalar_one_or_none()

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User profile not found. Please complete onboarding.",
        )

    return user


# ── Convenience type aliases for route signatures ────────────────────────────
# Usage:  async def my_route(db: DBDep, user: CurrentUser): ...
DBDep = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[User, Depends(get_current_user)]
