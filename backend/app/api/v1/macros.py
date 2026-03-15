"""
Macros routes
──────────────
GET /api/v1/macros/today  — return today's macro budget (remaining vs consumed)
"""

from fastapi import APIRouter

from app.core.dependencies import CurrentUser, DBDep
from app.schemas.macros import DailyLogResponse
from app.services.macro_service import compute_budget, get_or_create_today_log

router = APIRouter()


@router.get(
    "/today",
    response_model=DailyLogResponse,
    summary="Get today's macro budget and consumption",
)
async def get_today_macros(user: CurrentUser, db: DBDep) -> DailyLogResponse:
    """
    Called by the Flutter dashboard on app open to populate the macro ring.
    Creates an empty DailyLog if this is the user's first request of the day.
    """
    daily_log = await get_or_create_today_log(db, user)
    budget = compute_budget(user, daily_log)
    await db.commit()  # persist newly created log if applicable

    return DailyLogResponse(id=daily_log.id, log_date=daily_log.log_date, budget=budget)
