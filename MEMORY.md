# MEMORY.md

This file tracks the current state of the FitBuddy project. It is updated after every `git push` to reflect what has been built, what is in progress, and what comes next.

---

## Project Status: `IN PROGRESS — BACKEND PHASE 1`

## Last Updated
- Date: 2026-03-15
- After push: Backend scaffold complete, pushed to `main`

---

## What Has Been Built
- `CLAUDE.md`, `RULES.md`, `MEMORY.md`, `ARCHITECTURE.md` — project foundation
- `backend/` — full FastAPI backend scaffold:
  - **Models (SQLAlchemy 2.0 async):** User, DailyLog, Meal, UserBehaviorPattern, PushNotificationLog, SosSession, AIInteraction
  - **Core:** config (pydantic-settings), async DB engine, Firebase Admin init, `get_current_user` dependency
  - **Workers:** APScheduler with push_worker (every 15 min) + behavior_analyzer (weekly)
  - **Alembic:** async env.py configured for autogenerate
  - **Stubs:** all API routes, agents, services, schemas (empty, ready to implement)

## GitHub Remote
- https://github.com/yarin114/FitBuddy.git (branch: `main`)

## Architectural Decisions (locked)
- LLM: Anthropic Claude 3.5 Sonnet (`claude-3-5-sonnet-20241022`)
- Deployment: Docker on Render / Railway
- Push worker: APScheduler inside FastAPI (no Celery/Redis)
- Flutter state management: Riverpod
- Phase 1 scope: text cravings + push daemon + SOS WebSocket (no photo scan)

---

## Current Focus
- Implement API route handlers + Pydantic schemas + service layer

---

## What Comes Next
1. Pydantic schemas (user, meal, macros, sos)
2. Service layer: macro_service, notification_service
3. API routes: `/auth`, `/users`, `/macros`, `/meals`
4. LLM agents: macro_engine.py + system prompt
5. SOS WebSocket route + cbt_agent.py
6. Flutter mobile app scaffold
7. Docker + deployment config

---

## Known Decisions & Context
- LLM responses for macro engine must return structured JSON (never free text)
- All LLM prompts live in `backend/agents/prompts/` as versioned files
- CRON workers must be stateless per run
- WebSocket sessions authenticated via Firebase ID token on handshake
