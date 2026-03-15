"""
User routes
────────────
GET  /api/v1/users/me          — return current user profile
PUT  /api/v1/users/me          — update profile fields
PUT  /api/v1/users/me/fcm-token — register / refresh FCM token
"""

import logging

from fastapi import APIRouter, status

from app.core.dependencies import CurrentUser, DBDep
from app.schemas.user import UserResponse, UserUpdateRequest
from app.services.macro_service import _calculate_macro_targets

logger = logging.getLogger(__name__)
router = APIRouter()


@router.get("/me", response_model=UserResponse)
async def get_me(user: CurrentUser) -> UserResponse:
    return UserResponse.from_orm(user)


@router.put("/me", response_model=UserResponse)
async def update_me(
    body: UserUpdateRequest,
    user: CurrentUser,
    db: DBDep,
) -> UserResponse:
    update_data = body.model_dump(exclude_none=True)

    for field, value in update_data.items():
        setattr(user, field, value)

    # Recalculate macro targets if physical stats changed
    physical_fields = {"weight_kg", "height_cm", "goal_weight_kg", "activity_level"}
    if update_data.keys() & physical_fields:
        from app.schemas.user import UserOnboardRequest
        # Build a partial onboard request from current user state to recalculate
        recalc = _calculate_macro_targets_from_user(user)
        for field, value in recalc.items():
            setattr(user, field, value)

    await db.commit()
    await db.refresh(user)
    return UserResponse.from_orm(user)


@router.put("/me/fcm-token", status_code=status.HTTP_204_NO_CONTENT)
async def update_fcm_token(
    user: CurrentUser,
    db: DBDep,
    fcm_token: str,
) -> None:
    """Called by Flutter on app launch to keep the FCM token fresh."""
    user.fcm_token = fcm_token
    await db.commit()


def _calculate_macro_targets_from_user(user) -> dict:
    """Re-derive macro targets from the user's current physical stats."""
    from app.schemas.user import UserOnboardRequest
    partial = UserOnboardRequest(
        name=user.name,
        email=user.email,
        date_of_birth=user.date_of_birth,
        gender=user.gender,
        weight_kg=user.weight_kg,
        height_cm=user.height_cm,
        goal_weight_kg=user.goal_weight_kg,
        activity_level=user.activity_level,
        timezone=user.timezone,
    )
    return _calculate_macro_targets(partial)
