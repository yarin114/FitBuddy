"""
Macro Service
--------------
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

# ── Activity multipliers (Mifflin-St Jeor standard) ──────────────────────────
_ACTIVITY_MULTIPLIERS: dict[str, float] = {
    "sedentary":   1.2,    # desk job, little/no exercise
    "light":       1.375,  # light exercise 1–3x/week
    "moderate":    1.55,   # moderate exercise 3–5x/week
    "active":      1.725,  # hard exercise 6–7x/week
    "very_active": 1.9,    # athlete / physical job
}


async def get_or_create_today_log(db: AsyncSession, user: User) -> DailyLog:
    """
    Return today's DailyLog for the user, creating it if it doesn't exist yet.
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
        await db.flush()

    return log


def compute_budget(user: User, log: DailyLog) -> MacroBudget:
    """
    Derive the remaining macro budget from the user's targets and today's consumption.
    Targets default to 0 if onboarding is incomplete.
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
    Mifflin-St Jeor BMR → TDEE → goal adjustment → macro split.

    ``profile`` can be a UserOnboardRequest, UserProfileRequest, or any object
    with the same fields.  Falls back to sensible defaults for missing values.

    Goal adjustments:
      lose_weight  → TDEE − 500 kcal  (≈ 0.5 kg/week loss)
      maintain     → TDEE
      gain_muscle  → TDEE + 500 kcal  (lean bulk)

    Macro splits:
      lose_weight  → 35 % protein / 35 % carbs / 30 % fat
      maintain     → 30 % protein / 40 % carbs / 30 % fat
      gain_muscle  → 30 % protein / 45 % carbs / 25 % fat
    """
    weight   = getattr(profile, "weight_kg",      None) or 75.0
    height   = getattr(profile, "height_cm",      None) or 170.0
    gender   = getattr(profile, "gender",         None) or "other"
    activity = getattr(profile, "activity_level", None) or "sedentary"
    goal     = getattr(profile, "goal",           None) or "lose_weight"

    # ── Age ────────────────────────────────────────────────────────────────
    age = 30
    dob = getattr(profile, "date_of_birth", None)
    if dob:
        age = (date.today() - dob).days // 365

    # ── BMR (Mifflin-St Jeor) ──────────────────────────────────────────────
    if gender == "male":
        bmr = 10 * weight + 6.25 * height - 5 * age + 5
    elif gender == "female":
        bmr = 10 * weight + 6.25 * height - 5 * age - 161
    else:
        bmr = 10 * weight + 6.25 * height - 5 * age - 78

    # ── TDEE ───────────────────────────────────────────────────────────────
    multiplier = _ACTIVITY_MULTIPLIERS.get(activity, 1.2)
    tdee = bmr * multiplier

    # ── Goal adjustment ────────────────────────────────────────────────────
    if goal == "lose_weight":
        target_calories = max(1200, int(tdee - 500))
    elif goal == "gain_muscle":
        target_calories = int(tdee + 500)
    else:  # maintain
        target_calories = int(tdee)

    # ── Macro split ────────────────────────────────────────────────────────
    if goal == "lose_weight":
        protein_g = int((target_calories * 0.35) / 4)
        carbs_g   = int((target_calories * 0.35) / 4)
        fat_g     = int((target_calories * 0.30) / 9)
    elif goal == "gain_muscle":
        protein_g = int((target_calories * 0.30) / 4)
        carbs_g   = int((target_calories * 0.45) / 4)
        fat_g     = int((target_calories * 0.25) / 9)
    else:  # maintain
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
    """Increment the daily log's running totals by the meal's macros."""
    log.calories_consumed  += calories
    log.protein_consumed_g += protein_g
    log.carbs_consumed_g   += carbs_g
    log.fat_consumed_g     += fat_g
    log.last_meal_at        = datetime.now(timezone.utc)
    await db.flush()
