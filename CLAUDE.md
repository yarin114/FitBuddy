# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Rules

All development rules are defined in [`RULES.md`](./RULES.md). Read and follow them before taking any action.

The current project state (what's built, what's in progress, what's next) is tracked in [`MEMORY.md`](./MEMORY.md). Always read it before making any change.

---

## Project Overview

**FitBuddy** — an AI-powered nutrition coaching app for iOS and Android. It generates personalized recipes in real time based on the user's remaining macro budget, proactively pushes meal reminders, and provides a real-time CBT (cognitive behavioral therapy) intervention module for emotional eating.

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile client | Flutter (single codebase for iOS + Android) |
| Backend API | Python / FastAPI |
| Database | PostgreSQL |
| Auth + Push | Firebase (Authentication + Cloud Messaging) |
| AI models | OpenAI GPT-4o or Anthropic Claude 3.5 via API |
| Real-time | WebSockets (FastAPI native) |
| Background jobs | CRON-based workers (e.g., APScheduler or Celery) |

## Repository Structure (Intended)

```
fitbuddy/
├── mobile/          # Flutter app
├── backend/         # FastAPI server
│   ├── api/         # Route handlers
│   ├── agents/      # LLM agent logic
│   ├── workers/     # Background CRON/push workers
│   ├── models/      # SQLAlchemy DB models
│   └── core/        # Config, DB session, Firebase init
└── infra/           # Docker, env configs
```

## Common Commands

### Backend
```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload              # run dev server
pytest                                 # run all tests
pytest tests/test_macro_engine.py      # run single test file
```

### Flutter
```bash
cd mobile
flutter pub get                        # install dependencies
flutter run                            # run on connected device/emulator
flutter test                           # run all tests
flutter test test/macro_widget_test.dart  # run single test
flutter build apk                      # Android release build
flutter build ios                      # iOS release build
```

## Core System Architecture

### 1. Dynamic Macro Engine
- User input: free text, photo of fridge, or a craving button ("I want chocolate / pasta / meat")
- The backend holds the user's daily calorie + macro budget (protein / carb / fat) in PostgreSQL, updated on every logged meal
- A **rigid system prompt** is sent to the LLM with the remaining budget and the user's desire; the LLM must return a recipe with exact gram quantities that fits the remaining macros
- Output: a recipe object stored in DB and returned to the Flutter client

### 2. Proactive Push Agent (Coach Daemon)
- A **background worker** (CRON, runs every ~15 min) queries all users for:
  - Current time vs. their historical meal-logging patterns
  - Whether "black hole" hours are approaching (times when the user historically overeats or skips meals)
- When a risky window is detected, the LLM generates a **personalized** push message (includes user's name, specific situation, and a ready recipe)
- Message is delivered via **Firebase Cloud Messaging (FCM)**
- Personalization example: *"Ziv, I saw that you haven't eaten yet. This is a critical time. Here's a recipe for a chicken wrap that takes 5 minutes — I added it to your screen."*

### 3. SOS / Real-Time CBT Module
- Triggered by: user tapping "I'm about to break down" button or opening the mini-chat
- Opens a **WebSocket** connection (FastAPI `websockets`) between Flutter and the backend
- LLM receives a special system prompt flagging the user is in nutritional distress and activates a CBT protocol:
  - Asks guiding questions
  - Helps user distinguish physiological hunger from emotional hunger
  - Interrupts the act of eating through structured dialogue
- Session logs stored in PostgreSQL for future personalization

## Key Design Constraints

- LLM responses for the macro engine **must** return structured JSON (use `response_format` / function calling), never free text, so macros can be parsed reliably
- The CRON worker must be stateless per run — read from DB, act, write result back; no in-memory state between runs
- WebSocket sessions for the CBT module should be tied to `user_id` and authenticated via Firebase ID token on handshake
- All LLM system prompts live in a dedicated `backend/agents/prompts/` directory as versioned `.txt` or `.py` files — never hardcoded inline
