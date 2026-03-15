# MEMORY.md

This file tracks the current state of the FitBuddy project. It is updated after every `git push` to reflect what has been built, what is in progress, and what comes next.

---

## Project Status: `NOT STARTED`

## Last Updated
- Date: 2026-03-15
- After push: N/A — project not yet initialized

---

## What Has Been Built
- Nothing yet. The repository contains only:
  - `CLAUDE.md` — project guidance for Claude Code
  - `RULES.md` — development rules
  - `MEMORY.md` — this file

---

## Current Focus
- Project scaffolding (backend + Flutter app structure)

---

## What Comes Next
1. Initialize Flutter project under `mobile/`
2. Initialize FastAPI project under `backend/`
3. Set up PostgreSQL models
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
