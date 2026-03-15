"""
Weekly Behavior Pattern Analyzer
──────────────────────────────────
Runs every Sunday at 02:00 UTC.
Aggregates the past 30 days of daily_logs to compute per-user, per-hour,
per-day-of-week risk scores and writes them to user_behavior_patterns.

Stateless per run: reads from DB, computes, upserts results, done.
"""

import logging
from collections import defaultdict
from datetime import date, timedelta

from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import AsyncSessionLocal
from app.models.behavior_pattern import UserBehaviorPattern
from app.models.daily_log import DailyLog
from app.models.meal import Meal
from app.models.user import User

logger = logging.getLogger(__name__)

_LOOKBACK_DAYS = 30
_HIGH_CALORIE_MULTIPLIER = 1.3  # a day where consumed > target * 1.3 counts as overeating


async def run() -> None:
    """Entry point called by APScheduler."""
    logger.info("behavior_analyzer: starting weekly run...")
    async with AsyncSessionLocal() as db:
        users = await _get_all_users(db)
        for user in users:
            await _analyze_user(db, user)
    logger.info("behavior_analyzer: completed for %d users.", len(users))


async def _get_all_users(db: AsyncSession) -> list[User]:
    result = await db.execute(select(User))
    return list(result.scalars().all())


async def _analyze_user(db: AsyncSession, user: User) -> None:
    cutoff = date.today() - timedelta(days=_LOOKBACK_DAYS)

    # Load all logs and their meals for the lookback window
    logs_result = await db.execute(
        select(DailyLog).where(
            DailyLog.user_id == user.id,
            DailyLog.log_date >= cutoff,
        )
    )
    logs = logs_result.scalars().all()

    if not logs:
        return

    # Load meals for the same period to get per-meal timestamps
    meals_result = await db.execute(
        select(Meal).where(
            Meal.user_id == user.id,
            Meal.logged_at >= cutoff,
        )
    )
    meals = meals_result.scalars().all()

    # ── Compute meal frequency per (hour, weekday) slot ──────────────────────
    slot_meal_counts: dict[tuple[int, int], list[int]] = defaultdict(list)
    for meal in meals:
        h = meal.logged_at.hour
        d = meal.logged_at.weekday()
        slot_meal_counts[(h, d)].append(1)

    # ── Compute overeating / skip risk per slot ───────────────────────────────
    target = user.daily_calorie_target or 2000
    overeating_days: set[tuple[int, int]] = set()
    skip_days: set[tuple[int, int]] = set()

    for log in logs:
        weekday = log.log_date.weekday()
        if log.calories_consumed > target * _HIGH_CALORIE_MULTIPLIER:
            # Mark every slot on this day as potentially dangerous
            for h in range(24):
                overeating_days.add((h, weekday))
        if log.last_meal_at is None:
            # No meals logged at all that day — every slot is a skip risk
            for h in range(24):
                skip_days.add((h, weekday))

    total_days = len(logs)

    # ── Upsert into user_behavior_patterns ───────────────────────────────────
    for (hour, weekday), counts in slot_meal_counts.items():
        avg_meals = sum(counts) / total_days
        overeating_risk = (
            len([d for d in logs if d.log_date.weekday() == weekday and
                 d.calories_consumed > target * _HIGH_CALORIE_MULTIPLIER])
            / max(1, len([d for d in logs if d.log_date.weekday() == weekday]))
        )
        skip_risk = (
            len([d for d in logs if d.log_date.weekday() == weekday and
                 d.last_meal_at is None])
            / max(1, len([d for d in logs if d.log_date.weekday() == weekday]))
        )

        stmt = (
            pg_insert(UserBehaviorPattern)
            .values(
                user_id=user.id,
                hour_of_day=hour,
                day_of_week=weekday,
                avg_meals_logged=round(avg_meals, 4),
                overeating_risk_score=round(overeating_risk, 4),
                skip_risk_score=round(skip_risk, 4),
            )
            .on_conflict_do_update(
                constraint="uq_behavior_user_hour_day",
                set_={
                    "avg_meals_logged": round(avg_meals, 4),
                    "overeating_risk_score": round(overeating_risk, 4),
                    "skip_risk_score": round(skip_risk, 4),
                },
            )
        )
        await db.execute(stmt)

    await db.commit()
    logger.debug("behavior_analyzer: upserted patterns for user %s.", user.id)
