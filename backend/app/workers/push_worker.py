"""
Proactive Push Coach Daemon
────────────────────────────
Runs every N minutes (configured via PUSH_WORKER_INTERVAL_MINUTES).
For each active user it evaluates three trigger conditions and fires a
personalised FCM push notification when a risky window is detected.

This module is intentionally stateless: all state is read from and written
back to the database on each invocation.
"""

import logging
from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.database import AsyncSessionLocal
from app.models.push_log import PushNotificationLog
from app.models.user import User

logger = logging.getLogger(__name__)
settings = get_settings()


async def run() -> None:
    """Entry point called by APScheduler."""
    logger.info("push_worker: starting scan...")
    async with AsyncSessionLocal() as db:
        users = await _get_active_users(db)
        notified = 0
        for user in users:
            sent = await _evaluate_and_notify(db, user)
            if sent:
                notified += 1
    logger.info("push_worker: scanned %d users, sent %d notifications.", len(users), notified)


async def _get_active_users(db: AsyncSession) -> list[User]:
    """Return users who have an FCM token (i.e. the app is installed and they opted in)."""
    result = await db.execute(
        select(User).where(User.fcm_token.isnot(None))
    )
    return list(result.scalars().all())


async def _evaluate_and_notify(db: AsyncSession, user: User) -> bool:
    """
    Evaluate trigger conditions for a single user.
    Returns True if a notification was sent.
    """
    # Lazy import to avoid circular dependency at module load time
    from app.models.behavior_pattern import UserBehaviorPattern
    from app.models.daily_log import DailyLog

    now_utc = datetime.now(timezone.utc)

    # ── Load today's daily log ───────────────────────────────────────────────
    result = await db.execute(
        select(DailyLog).where(
            DailyLog.user_id == user.id,
            DailyLog.log_date == now_utc.date(),
        )
    )
    daily_log = result.scalar_one_or_none()
    if daily_log is None:
        return False  # user has not opened the app today — don't spam

    # ── Load behavior pattern for this hour/day slot ─────────────────────────
    result = await db.execute(
        select(UserBehaviorPattern).where(
            UserBehaviorPattern.user_id == user.id,
            UserBehaviorPattern.hour_of_day == now_utc.hour,
            UserBehaviorPattern.day_of_week == now_utc.weekday(),
        )
    )
    pattern = result.scalar_one_or_none()

    trigger_reason = _detect_trigger(now_utc, daily_log, pattern, user)
    if trigger_reason is None:
        return False

    # ── Spam guard: did we already send a push in the last N hours? ──────────
    cooldown_cutoff = now_utc - timedelta(hours=settings.push_cooldown_hours)
    result = await db.execute(
        select(PushNotificationLog).where(
            PushNotificationLog.user_id == user.id,
            PushNotificationLog.sent_at >= cooldown_cutoff,
        )
    )
    if result.scalar_one_or_none() is not None:
        return False

    # ── Generate personalised message via LLM ───────────────────────────────
    # (push_agent is imported here to avoid loading the Anthropic client at
    #  module level, keeping the scheduler startup fast)
    from app.agents.push_agent import generate_push_message

    calories_remaining = max(
        0,
        (user.daily_calorie_target or 0) - daily_log.calories_consumed,
    )
    message = await generate_push_message(
        user_name=user.name,
        trigger_reason=trigger_reason,
        calories_remaining=calories_remaining,
        last_meal_at=daily_log.last_meal_at,
        current_time=now_utc,
    )

    # ── Send FCM ─────────────────────────────────────────────────────────────
    from app.services.notification_service import send_push

    # Forward suggested_craving (if present) as FCM data payload so the
    # Flutter client can deep-link directly to the Macro Engine with the
    # rescue recipe pre-filled.
    fcm_data: dict | None = None
    if message.get("suggested_craving"):
        fcm_data = {"suggested_craving": message["suggested_craving"]}

    await send_push(
        fcm_token=user.fcm_token,
        title=message["title"],
        body=message["body"],
        data=fcm_data,
    )

    # ── Persist log ──────────────────────────────────────────────────────────
    db.add(
        PushNotificationLog(
            user_id=user.id,
            trigger_reason=trigger_reason,
            message_body=message["body"],
        )
    )
    await db.commit()
    return True


def _detect_trigger(
    now_utc: datetime,
    daily_log,
    pattern,
    user: User,
) -> str | None:
    """
    Return a trigger reason string, or None if no condition is met.
    Order matters: more critical conditions are checked first.
    """
    # 1. Skip risk: haven't eaten in a long time AND pattern says this is dangerous
    if daily_log.last_meal_at is not None:
        hours_since_meal = (now_utc - daily_log.last_meal_at).total_seconds() / 3600
        skip_risk = pattern.skip_risk_score if pattern else 0.0
        if hours_since_meal >= settings.skip_risk_threshold_hours and skip_risk > 0.6:
            return "skip_risk"

    # 2. Overeating risk: pattern says danger AND very little budget left
    if pattern and pattern.overeating_risk_score > 0.7:
        calories_remaining = max(
            0, (user.daily_calorie_target or 0) - daily_log.calories_consumed
        )
        if calories_remaining < 200:
            return "overeating_risk"

    # 3. End-of-day gap: 20:00–21:00 local and large unspent budget
    # (timezone conversion is approximate here; full tz support in v2)
    if now_utc.hour in (20, 21):
        calories_remaining = max(
            0, (user.daily_calorie_target or 0) - daily_log.calories_consumed
        )
        if calories_remaining > 400:
            return "end_of_day_gap"

    return None
