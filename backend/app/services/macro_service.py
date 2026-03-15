"""
Macro Service
──────────────
Owns all business logic around daily macro budgets and daily log management.
No HTTP concerns — pure DB + computation.
"""

from datetime import date, datetime, timezone
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.daily_log import DailyLog
from app.models.user import User
from app.schemas.macros import MacroBudget


async def get_or_create_today_log(db: AsyncSession, user: User) -> DailyLog:
    """
    Return today's DailyLog for the user, creating it if it doesn't exist yet.
    Uses SELECT … FOR UPDATE to be safe under concurrent requests.
    """
    today = date.today()
    result = await db.execute(
        select(DailyLog).where(
            DailyLog.user_id == user.id,
            DailyLog.log_date == today,
        )
    )
    log = result.scalar_one_or_none()

    if log is None:
        log = DailyLog(
            user_id=user.id,
            log_date=today,
            calories_consumed=0,
            protein_consumed_g=0,
            carbs_consumed_g=0,
            fat_consumed_g=0,
        )
        db.add(log)
        await db.flush()  # assigns the UUID without committing the transaction

    return log


def compute_budget(user: User, log: DailyLog) -> MacroBudget:
    """
    Derive the remaining macro budget from the user's targets and today's consumption.
    Targets default to 0 if onboarding is incomplete (prevents negative budgets).
    """
    cal_target  = user.daily_calorie_target or 0
    prot_target = user.daily_protein_g      or 0
    carb_target = user.daily_carbs_g        or 0
    fat_target  = user.daily_fat_g          or 0

    return MacroBudget(
        log_date=log.log_date,
        calories_target=cal_target,
        calories_consumed=log.calories_consumed,
        calories_remaining=max(0, cal_target - log.calories_consumed),
        protein_target_g=prot_target,
        protein_consumed_g=log.protein_consumed_g,
        protein_remaining_g=max(0, prot_target - log.protein_consumed_g),
        carbs_target_g=carb_target,
        carbs_consumed_g=log.carbs_consumed_g,
        carbs_remaining_g=max(0, carb_target - log.carbs_consumed_g),
        fat_target_g=fat_target,
        fat_consumed_g=log.fat_consumed_g,
        fat_remaining_g=max(0, fat_target - log.fat_consumed_g),
    )


def _calculate_macro_targets(profile) -> dict:
    """
    Mifflin-St Jeor BMR → TDEE → deficit for weight loss → macro split.

    ``profile`` can be a UserOnboardRequest or any object with the same fields.
    Returns a dict of {daily_calorie_target, daily_protein_g, daily_carbs_g, daily_fat_g}.
    Falls back to sensible defaults if physical data is missing.
    """
    weight  = profile.weight_kg   or 75.0
    height  = profile.height_cm   or 170.0
    gender  = profile.gender      or "other"
    activity = profile.activity_level or "sedentary"

    # Age from date_of_birth
    age = 30
    if profile.date_of_birth:
        from datetime import date
        today = date.today()
        age = (today - profile.date_of_birth).days // 365

    # Mifflin-St Jeor BMR
    if gender == "male":
        bmr = 10 * weight + 6.25 * height - 5 * age + 5
    elif gender == "female":
        bmr = 10 * weight + 6.25 * height - 5 * age - 161
    else:
        bmr = 10 * weight + 6.25 * height - 5 * age - 78  # average

    activity_multipliers = {
        "sedentary": 1.2,
        "light":     1.375,
        "moderate":  1.55,
        "active":    1.725,
    }
    tdee = bmr * activity_multipliers.get(activity, 1.2)

    # 500 kcal/day deficit for ~0.5 kg/week loss
    target_calories = max(1200, int(tdee - 500))

    # Macro split: 30% protein / 40% carbs / 30% fat
    protein_g = int((target_calories * 0.30) / 4)
    carbs_g   = int((target_calories * 0.40) / 4)
    fat_g     = int((target_calories * 0.30) / 9)

    return {
        "daily_calorie_target": target_calories,
        "daily_protein_g":      protein_g,
        "daily_carbs_g":        carbs_g,
        "daily_fat_g":          fat_g,
    }


async def apply_meal_to_log(
    db: AsyncSession,
    log: DailyLog,
    calories: int,
    protein_g: int,
    carbs_g: int,
    fat_g: int,
) -> None:
    """
    Increment the daily log's running totals by the meal's macros
    and update last_meal_at.  Caller is responsible for committing.
    """
    log.calories_consumed  += calories
    log.protein_consumed_g += protein_g
    log.carbs_consumed_g   += carbs_g
    log.fat_consumed_g     += fat_g
    log.last_meal_at        = datetime.now(timezone.utc)
    await db.flush()
