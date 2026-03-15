"""
Notifications routes
---------------------
POST /api/v1/notifications/fcm-token  — register / refresh the device FCM token
"""

from fastapi import APIRouter

from app.core.dependencies import CurrentUser, DBDep
from app.schemas.user import UserUpdateRequest

router = APIRouter()


@router.post("/fcm-token", status_code=204)
async def register_fcm_token(
    body: UserUpdateRequest,
    user: CurrentUser,
    db: DBDep,
) -> None:
    """Store or refresh the FCM device token for push notifications."""
    if body.fcm_token is not None:
        user.fcm_token = body.fcm_token
        await db.commit()
