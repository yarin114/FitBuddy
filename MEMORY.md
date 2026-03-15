# MEMORY.md

This file tracks the current state of the FitBuddy project. It is updated after every `git push` to reflect what has been built, what is in progress, and what comes next.

---

## Project Status: `IN PROGRESS — BACKEND PHASE 2`

## Last Updated
- Date: 2026-03-15
- After push: Dynamic Macro Engine fully implemented and pushed

---

## What Has Been Built
- `CLAUDE.md`, `RULES.md`, `MEMORY.md`, `ARCHITECTURE.md` — project foundation
- `backend/` — full FastAPI backend:
  - **Models:** User, DailyLog, Meal, UserBehaviorPattern, PushNotificationLog, SosSession, AIInteraction
  - **Core:** config, async DB engine, Firebase Admin, `get_current_user` dependency
  - **Schemas:** user, macros, meal, sos (all implemented)
  - **Services:** macro_service (budget calc, Mifflin-St Jeor BMR), notification_service (FCM)
  - **AI Agent:** macro_engine.py — Claude 3.5 Sonnet via Tool Use, budget guard, totals validation
  - **System prompt:** agents/prompts/macro_v1.txt (versioned)
  - **Routes:** POST /meals/generate ✅, POST /meals/log ✅, GET /meals/today ✅, GET /meals/history ✅, GET /macros/today ✅, POST /auth/register ✅, GET/PUT /users/me ✅
  - **Workers:** push_worker + behavior_analyzer (full implementation)
  - **Alembic:** async env.py

## GitHub Remote
- https://github.com/yarin114/FitBuddy.git (branch: `main`)

## Architectural Decisions (locked)
- LLM: Anthropic Claude 3.5 Sonnet (`claude-3-5-sonnet-20241022`)
- LLM structured output: Tool Use (not beta structured-outputs — only supported on Sonnet 4.5+)
- Deployment: Docker on Render / Railway
- Push worker: APScheduler inside FastAPI (no Celery/Redis)
- Flutter state management: Riverpod
- Phase 1 scope: text cravings + push daemon + SOS WebSocket (no photo scan)

## Key Technical Notes
- `_calculate_macro_targets` uses Mifflin-St Jeor BMR with 500 kcal deficit
- Macro split: 30% protein / 40% carbs / 30% fat
- Budget guard tolerances: ±30 kcal, ±5g macros
- All LLM prompts versioned in `agents/prompts/`

---

## Current Focus
- SOS / CBT WebSocket module (cbt_agent.py + /ws/sos route)

---

## What Comes Next
1. SOS WebSocket route (`api/v1/sos.py`) + `agents/cbt_agent.py` + `prompts/cbt_v1.txt`
2. Push agent LLM call (`agents/push_agent.py`)
3. Alembic first migration + `alembic.ini` config
4. Dockerfile + docker-compose
5. Flutter mobile app scaffold

---

## Known Decisions & Context
- LLM responses for macro engine must return structured JSON (never free text)
- All LLM prompts live in `backend/agents/prompts/` as versioned files
- CRON workers must be stateless per run
- WebSocket sessions authenticated via Firebase ID token on handshake
