# MEMORY.md

This file tracks the current state of the FitBuddy project. It is updated after every `git push` to reflect what has been built, what is in progress, and what comes next.

---

## Project Status: `PLANNING — AWAITING ARCHITECTURE APPROVAL`

## Last Updated
- Date: 2026-03-15
- After push: Initial blueprint committed and pushed to `main`

---

## What Has Been Built
- `CLAUDE.md` — project guidance for Claude Code
- `RULES.md` — development rules (3 rules)
- `MEMORY.md` — this file
- `ARCHITECTURE.md` — full system architecture blueprint (pending approval)

## GitHub Remote
- https://github.com/yarin114/FitBuddy.git (branch: `main`)

---

## Current Focus
- Architecture approval: waiting for user answers on 5 open questions (see ARCHITECTURE.md § Approval Checklist)

---

## What Comes Next (after approval)
1. Initialize Flutter project under `mobile/`
2. Initialize FastAPI project under `backend/`
3. Set up PostgreSQL models + Alembic migrations
4. Set up Firebase (Auth + FCM)
5. Build Dynamic Macro Engine (API + LLM integration)
6. Build Proactive Push Agent (CRON worker + FCM)
7. Build SOS / CBT real-time module (WebSockets)

---

## Known Decisions & Context
- LLM responses for macro engine must return structured JSON (never free text)
- All LLM prompts live in `backend/agents/prompts/` as versioned files
- CRON workers must be stateless per run
- WebSocket sessions authenticated via Firebase ID token on handshake
