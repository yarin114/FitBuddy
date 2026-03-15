"""
Dynamic Macro Engine — AI Agent
────────────────────────────────
Uses Anthropic Claude 3.5 Sonnet with Tool Use (function calling) to guarantee
a structurally valid JSON recipe that fits the user's remaining macro budget.

Why Tool Use instead of plain text prompting?
- Claude 3.5 Sonnet does not support the new beta structured-outputs API
  (that requires Sonnet 4.5+).
- Tool Use forces the model to populate a strictly-typed JSON schema as the
  function arguments — it literally cannot produce a response in any other format.
- If Claude fails to call the tool, we raise MacroEngineError immediately
  rather than silently returning malformed data.
"""

import logging
import time
from pathlib import Path

import anthropic
from pydantic import ValidationError

from app.core.config import get_settings
from app.schemas.macros import MacroBudget
from app.schemas.meal import Ingredient, MealResponse

logger = logging.getLogger(__name__)
settings = get_settings()

# ── Load system prompt from versioned file ────────────────────────────────────
_PROMPT_PATH = Path(__file__).parent / "prompts" / "macro_v1.txt"
_SYSTEM_PROMPT: str = _PROMPT_PATH.read_text(encoding="utf-8")

# ── Tool schema (the JSON contract Claude must fill) ──────────────────────────
_RECIPE_TOOL: dict = {
    "name": "submit_recipe",
    "description": (
        "Submit the generated recipe. You MUST call this tool. "
        "Every macro value must be the precise arithmetic sum of the ingredients."
    ),
    "input_schema": {
        "type": "object",
        "properties": {
            "name": {
                "type": "string",
                "description": "Short, appetising name for the recipe (max 80 chars).",
            },
            "ingredients": {
                "type": "array",
                "minItems": 1,
                "items": {
                    "type": "object",
                    "properties": {
                        "name":      {"type": "string"},
                        "grams":     {"type": "number", "minimum": 1},
                        "calories":  {"type": "integer", "minimum": 0},
                        "protein_g": {"type": "number", "minimum": 0},
                        "carbs_g":   {"type": "number", "minimum": 0},
                        "fat_g":     {"type": "number", "minimum": 0},
                    },
                    "required": ["name", "grams", "calories", "protein_g", "carbs_g", "fat_g"],
                },
            },
            "instructions": {
                "type": "string",
                "description": "Step-by-step cooking instructions in plain text.",
            },
            "total_calories": {"type": "integer", "minimum": 0},
            "total_protein_g": {"type": "number", "minimum": 0},
            "total_carbs_g":   {"type": "number", "minimum": 0},
            "total_fat_g":     {"type": "number", "minimum": 0},
        },
        "required": [
            "name", "ingredients", "instructions",
            "total_calories", "total_protein_g", "total_carbs_g", "total_fat_g",
        ],
    },
}

# Tolerance for server-side macro validation (grams / kcal)
_CALORIE_TOLERANCE = 30
_MACRO_TOLERANCE_G = 5.0


class MacroEngineError(Exception):
    """Raised when the LLM fails to produce a valid, budget-compliant recipe."""


async def generate_recipe(
    craving: str,
    budget: MacroBudget,
    user_id,  # UUID — used for audit logging by the caller
) -> dict:
    """
    Call Claude 3.5 Sonnet and return a validated recipe dict.

    Returns a dict that maps directly onto the Meal ORM model fields.
    Raises MacroEngineError on any LLM or validation failure.
    """
    client = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)

    user_message = _build_user_message(craving, budget)
    logger.debug("macro_engine: calling LLM for user=%s craving=%r", user_id, craving)

    t0 = time.monotonic()
    try:
        response = await client.messages.create(
            model=settings.llm_model,
            max_tokens=1500,
            system=_SYSTEM_PROMPT,
            tools=[_RECIPE_TOOL],
            # Force the model to call our tool — it cannot respond with plain text.
            tool_choice={"type": "tool", "name": "submit_recipe"},
            messages=[{"role": "user", "content": user_message}],
        )
    except anthropic.APIStatusError as exc:
        logger.error("macro_engine: Anthropic API error: %s", exc)
        raise MacroEngineError(f"LLM API error: {exc.status_code}") from exc
    except anthropic.APIConnectionError as exc:
        logger.error("macro_engine: Anthropic connection error: %s", exc)
        raise MacroEngineError("LLM unreachable. Please try again.") from exc

    latency_ms = int((time.monotonic() - t0) * 1000)
    logger.info(
        "macro_engine: LLM responded in %d ms | tokens in=%d out=%d",
        latency_ms,
        response.usage.input_tokens,
        response.usage.output_tokens,
    )

    # ── Extract tool call ──────────────────────────────────────────────────
    tool_use_block = next(
        (block for block in response.content if block.type == "tool_use"),
        None,
    )
    if tool_use_block is None:
        logger.error("macro_engine: model did not call submit_recipe tool")
        raise MacroEngineError("The AI failed to generate a recipe. Please try again.")

    raw: dict = tool_use_block.input

    # ── Validate ingredient schema with Pydantic ───────────────────────────
    try:
        validated_ingredients = [Ingredient(**ing) for ing in raw.get("ingredients", [])]
    except ValidationError as exc:
        logger.error("macro_engine: ingredient validation failed: %s", exc)
        raise MacroEngineError("Recipe data was malformed. Please try again.") from exc

    # ── Server-side budget guard ───────────────────────────────────────────
    _assert_within_budget(raw, budget)

    # ── Verify totals match ingredient sum ─────────────────────────────────
    _assert_totals_consistent(raw, validated_ingredients)

    return {
        "name": raw["name"],
        "ingredients": [ing.model_dump() for ing in validated_ingredients],
        "instructions": raw["instructions"],
        "total_calories": int(raw["total_calories"]),
        "total_protein_g": int(round(raw["total_protein_g"])),
        "total_carbs_g": int(round(raw["total_carbs_g"])),
        "total_fat_g": int(round(raw["total_fat_g"])),
        # Metadata for the caller to store in AIInteraction
        "_meta": {
            "input_tokens": response.usage.input_tokens,
            "output_tokens": response.usage.output_tokens,
            "latency_ms": latency_ms,
            "prompt_version": "macro_v1",
        },
    }


# ── Private helpers ───────────────────────────────────────────────────────────

def _build_user_message(craving: str, budget: MacroBudget) -> str:
    return (
        f"The user is craving: \"{craving}\"\n\n"
        f"Remaining budget for today:\n"
        f"  Calories : {budget.calories_remaining} kcal\n"
        f"  Protein  : {budget.protein_remaining_g} g\n"
        f"  Carbs    : {budget.carbs_remaining_g} g\n"
        f"  Fat      : {budget.fat_remaining_g} g\n\n"
        "Generate one recipe that satisfies the craving and stays within ALL budget limits. "
        "Call submit_recipe with your answer."
    )


def _assert_within_budget(raw: dict, budget: MacroBudget) -> None:
    """Raise MacroEngineError if any macro exceeds the remaining budget."""
    violations = []
    if raw["total_calories"] > budget.calories_remaining + _CALORIE_TOLERANCE:
        violations.append(
            f"calories {raw['total_calories']} > budget {budget.calories_remaining}"
        )
    if raw["total_protein_g"] > budget.protein_remaining_g + _MACRO_TOLERANCE_G:
        violations.append(
            f"protein {raw['total_protein_g']}g > budget {budget.protein_remaining_g}g"
        )
    if raw["total_carbs_g"] > budget.carbs_remaining_g + _MACRO_TOLERANCE_G:
        violations.append(
            f"carbs {raw['total_carbs_g']}g > budget {budget.carbs_remaining_g}g"
        )
    if raw["total_fat_g"] > budget.fat_remaining_g + _MACRO_TOLERANCE_G:
        violations.append(
            f"fat {raw['total_fat_g']}g > budget {budget.fat_remaining_g}g"
        )
    if violations:
        logger.warning("macro_engine: budget exceeded: %s", violations)
        raise MacroEngineError(
            "The AI generated a recipe that exceeds your macro budget. "
            "Please try again or adjust your craving."
        )


def _assert_totals_consistent(raw: dict, ingredients: list[Ingredient]) -> None:
    """Raise MacroEngineError if the declared totals don't match ingredient sums."""
    sum_cal  = sum(i.calories  for i in ingredients)
    sum_prot = sum(i.protein_g for i in ingredients)
    sum_carb = sum(i.carbs_g   for i in ingredients)
    sum_fat  = sum(i.fat_g     for i in ingredients)

    if abs(raw["total_calories"] - sum_cal) > _CALORIE_TOLERANCE:
        raise MacroEngineError(
            f"Recipe totals are inconsistent (calories: declared {raw['total_calories']}, "
            f"computed {sum_cal}). Please try again."
        )
    for declared, computed, label in [
        (raw["total_protein_g"], sum_prot, "protein"),
        (raw["total_carbs_g"],   sum_carb, "carbs"),
        (raw["total_fat_g"],     sum_fat,  "fat"),
    ]:
        if abs(declared - computed) > _MACRO_TOLERANCE_G:
            raise MacroEngineError(
                f"Recipe totals are inconsistent ({label}: declared {declared}g, "
                f"computed {computed:.1f}g). Please try again."
            )
