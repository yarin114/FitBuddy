"""
User routes
------------
GET  /api/v1/users/me             — return current user profile
PUT  /api/v1/users/me             — partial update (name, fcm_token, etc.)
PUT  /api/v1/users/profile        — onboarding completion: save physical stats
PUT  /api/v1/users/me/fcm-token   — register / refresh FCM token
"""

import logging
from datetime import date

from fastapi import APIRouter, status

from app.core.dependencies import CurrentUser, DBDep
from app.schemas.user import UserProfileRequest, UserResponse, UserUpdateRequest
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
    """Partial profile update — recalculates macro targets if physical fields change."""
    update_data = body.model_dump(exclude_none=True)

    for field, value in update_data.items():
        setattr(user, field, value)

    physical_fields = {"weight_kg", "height_cm", "goal_weight_kg", "activity_level", "goal"}
    if update_data.keys() & physical_fields:
        recalc = _calculate_macro_targets_from_user(user)
        for field, value in recalc.items():
            setattr(user, field, value)

    await db.commit()
    await db.refresh(user)
    return UserResponse.from_orm(user)


@router.put("/profile", response_model=UserResponse, status_code=status.HTTP_200_OK)
async def complete_profile(
    body: UserProfileRequest,
    user: CurrentUser,
    db: DBDep,
) -> UserResponse:
    """
    Called once after onboarding: saves physical stats, calculates personalised
    macro targets with the full Mifflin-St Jeor formula, and marks
    onboarding_completed = True.
    """
    # Approximate date_of_birth from age (Jan 1 of birth year)
    birth_year = date.today().year - body.age
    user.date_of_birth   = date(birth_year, 1, 1)
    user.gender          = body.gender
    user.weight_kg       = body.weight_kg
    user.height_cm       = body.height_cm
    user.activity_level  = body.activity_level
    user.goal            = body.goal
    user.timezone        = body.timezone
    user.onboarding_completed = True

    targets = _calculate_macro_targets(body)
    for field, value in targets.items():
        setattr(user, field, value)

    await db.commit()
    await db.refresh(user)

    logger.info(
        "Onboarding complete: user=%s goal=%s calories=%d",
        user.id, user.goal, user.daily_calorie_target,
    )
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


# ── Helpers ───────────────────────────────────────────────────────────────────

def _calculate_macro_targets_from_user(user) -> dict:
    """Re-derive macro targets from the user's current physical stats."""

    class _ProfileProxy:
        weight_kg      = user.weight_kg
        height_cm      = user.height_cm
        gender         = user.gender
        activity_level = user.activity_level
        goal           = user.goal
        date_of_birth  = user.date_of_birth

    return _calculate_macro_targets(_ProfileProxy())
