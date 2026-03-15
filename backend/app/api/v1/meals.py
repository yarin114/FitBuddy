"""
Meals routes — the core AI engine endpoint
───────────────────────────────────────────
POST /api/v1/meals/generate   ← Dynamic Macro Engine (primary endpoint)
POST /api/v1/meals/log        ← Manual meal logging
GET  /api/v1/meals/history    ← Paginated meal history
GET  /api/v1/meals/today      ← Today's logged meals
"""

import logging
from typing import List
from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select

from app.agents.macro_engine import MacroEngineError, generate_recipe
from app.agents.meal_parser import MealParserError, parse_meal_text
from app.core.dependencies import CurrentUser, DBDep
from app.models.ai_interaction import AIInteraction
from app.models.meal import Meal
from app.schemas.meal import MealGenerateRequest, MealLogManualRequest, MealLogTextRequest, MealResponse
from app.services.macro_service import (
    apply_meal_to_log,
    compute_budget,
    get_or_create_today_log,
)

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post(
    "/generate",
    response_model=MealResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Generate an AI recipe that fits the user's remaining macro budget",
)
async def generate_meal(
    body: MealGenerateRequest,
    user: CurrentUser,
    db: DBDep,
) -> MealResponse:
    """
    The Dynamic Macro Engine endpoint.

    1. Load (or create) today's DailyLog and compute the remaining macro budget.
    2. Call Claude 3.5 Sonnet via Tool Use — returns a budget-compliant recipe.
    3. Persist the Meal and update the DailyLog running totals atomically.
    4. Persist an AIInteraction audit record.
    5. Return the recipe to the Flutter client.
    """
    # ── Step 1: compute remaining budget ─────────────────────────────────────
    if not user.daily_calorie_target:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Please complete your profile and macro targets before generating meals.",
        )

    daily_log = await get_or_create_today_log(db, user)
    budget = compute_budget(user, daily_log)

    if budget.calories_remaining < 50:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=(
                f"You only have {budget.calories_remaining} kcal remaining today. "
                "There's not enough budget to generate a meaningful meal."
            ),
        )

    # ── Step 2: call the LLM agent ────────────────────────────────────────────
    try:
        recipe_data = await generate_recipe(
            craving=body.craving_input,
            budget=budget,
            user_id=user.id,
        )
    except MacroEngineError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(exc),
        )

    # ── Step 3: persist meal and update daily log (single transaction) ────────
    meta = recipe_data.pop("_meta")

    meal = Meal(
        user_id=user.id,
        daily_log_id=daily_log.id,
        craving_input=body.craving_input,
        source="ai_generated",
        **recipe_data,
    )
    db.add(meal)

    await apply_meal_to_log(
        db=db,
        log=daily_log,
        calories=meal.total_calories,
        protein_g=meal.total_protein_g,
        carbs_g=meal.total_carbs_g,
        fat_g=meal.total_fat_g,
    )

    # ── Step 4: audit log ────────────────────────────────────────────────────
    db.add(
        AIInteraction(
            user_id=user.id,
            module="macro_engine",
            prompt_version=meta["prompt_version"],
            input_tokens=meta["input_tokens"],
            output_tokens=meta["output_tokens"],
            latency_ms=meta["latency_ms"],
        )
    )

    await db.commit()
    await db.refresh(meal)

    logger.info(
        "meal generated: user=%s calories=%d latency=%dms",
        user.id,
        meal.total_calories,
        meta["latency_ms"],
    )
    return MealResponse.model_validate(meal)


@router.post(
    "/log",
    response_model=MealResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Manually log a meal",
)
async def log_meal_manually(
    body: MealLogManualRequest,
    user: CurrentUser,
    db: DBDep,
) -> MealResponse:
    daily_log = await get_or_create_today_log(db, user)

    meal = Meal(
        user_id=user.id,
        daily_log_id=daily_log.id,
        name=body.name,
        ingredients=[ing.model_dump() for ing in body.ingredients],
        instructions=body.instructions,
        total_calories=body.total_calories,
        total_protein_g=body.total_protein_g,
        total_carbs_g=body.total_carbs_g,
        total_fat_g=body.total_fat_g,
        source="manual",
    )
    db.add(meal)

    await apply_meal_to_log(
        db=db,
        log=daily_log,
        calories=meal.total_calories,
        protein_g=meal.total_protein_g,
        carbs_g=meal.total_carbs_g,
        fat_g=meal.total_fat_g,
    )

    await db.commit()
    await db.refresh(meal)
    return MealResponse.model_validate(meal)


@router.post(
    "/log-text",
    response_model=MealResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Log a meal from a plain-text description using AI macro parsing",
)
async def log_meal_from_text(
    body: MealLogTextRequest,
    user: CurrentUser,
    db: DBDep,
) -> MealResponse:
    """
    AI Nutritionist endpoint.

    1. Send the user's free-text description to Claude (Tool Use).
    2. Claude returns structured {meal_name, calories, protein_g, carbs_g, fat_g}.
    3. Persist the Meal and update today's DailyLog running totals atomically.
    4. Return the saved MealResponse.
    """
    try:
        parsed = await parse_meal_text(body.text)
    except MealParserError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(exc),
        )

    daily_log = await get_or_create_today_log(db, user)

    meal = Meal(
        user_id=user.id,
        daily_log_id=daily_log.id,
        name=parsed["meal_name"],
        ingredients=[],
        instructions="",
        total_calories=parsed["calories"],
        total_protein_g=parsed["protein_g"],
        total_carbs_g=parsed["carbs_g"],
        total_fat_g=parsed["fat_g"],
        craving_input=body.text,
        source="ai_parsed",
    )
    db.add(meal)

    await apply_meal_to_log(
        db=db,
        log=daily_log,
        calories=meal.total_calories,
        protein_g=meal.total_protein_g,
        carbs_g=meal.total_carbs_g,
        fat_g=meal.total_fat_g,
    )

    await db.commit()
    await db.refresh(meal)

    logger.info(
        "meal logged via text: user=%s name=%r calories=%d",
        user.id,
        meal.name,
        meal.total_calories,
    )
    return MealResponse.model_validate(meal)


@router.get(
    "/today",
    response_model=List[MealResponse],
    summary="List all meals logged today",
)
async def get_today_meals(user: CurrentUser, db: DBDep) -> List[MealResponse]:
    from datetime import date

    result = await db.execute(
        select(Meal)
        .where(Meal.user_id == user.id)
        .order_by(Meal.logged_at.desc())
    )
    all_meals = result.scalars().all()

    today = date.today()
    today_meals = [m for m in all_meals if m.logged_at.date() == today]
    return [MealResponse.model_validate(m) for m in today_meals]


@router.get(
    "/history",
    response_model=List[MealResponse],
    summary="Paginated meal history",
)
async def get_meal_history(
    user: CurrentUser,
    db: DBDep,
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
) -> List[MealResponse]:
    result = await db.execute(
        select(Meal)
        .where(Meal.user_id == user.id)
        .order_by(Meal.logged_at.desc())
        .limit(limit)
        .offset(offset)
    )
    return [MealResponse.model_validate(m) for m in result.scalars().all()]
