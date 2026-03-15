# FitBuddy — System Architecture Blueprint

> Plan Mode document. No implementation code. Approved sections will be built step-by-step.

---

## 1. High-Level System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        FLUTTER CLIENT                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐  │
│  │  Macro   │  │  Meal    │  │   SOS /  │  │   Push     │  │
│  │  Tracker │  │  Feed    │  │   CBT    │  │   Inbox    │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └─────┬──────┘  │
└───────┼─────────────┼─────────────┼───────────────┼─────────┘
        │  REST/HTTPS │             │ WebSocket     │ FCM
        ▼             ▼             ▼               ▼
┌─────────────────────────────────────────────────────────────┐
│                     FASTAPI BACKEND                          │
│  ┌────────────┐  ┌────────────┐  ┌──────────────────────┐   │
│  │  REST API  │  │  WS Server │  │   Background Workers │   │
│  │  (v1/)     │  │  /ws/sos   │  │   (APScheduler)      │   │
│  └─────┬──────┘  └─────┬──────┘  └──────────┬───────────┘   │
│        │               │                    │               │
│  ┌─────▼───────────────▼────────────────────▼────────────┐  │
│  │                  AGENT LAYER                           │  │
│  │   MacroEngine Agent │ PushCoach Agent │ CBT Agent      │  │
│  └─────┬───────────────────────────────────┬─────────────┘  │
└────────┼───────────────────────────────────┼────────────────┘
         │                                   │
    ┌────▼─────┐   ┌──────────┐   ┌─────────▼──────┐
    │ PostgreSQL│   │ Firebase │   │  LLM API       │
    │ (data)    │   │ Auth/FCM │   │  GPT-4o /      │
    └───────────┘   └──────────┘   │  Claude 3.5    │
                                   └────────────────┘
```

**Data flow summary:**
- Flutter authenticates via Firebase Auth → sends `id_token` in every request header
- FastAPI verifies the `id_token` with Firebase Admin SDK on every protected route
- All business data (meals, macros, logs) lives in PostgreSQL
- LLM calls are made server-side only — the client never touches the LLM API directly
- Push notifications flow: Worker → LLM → FCM → device
- SOS module uses a persistent WebSocket connection, not REST

---

## 2. Database Schema

### `users`
| Column | Type | Notes |
|---|---|---|
| id | UUID PK | |
| firebase_uid | VARCHAR UNIQUE | links to Firebase Auth |
| name | VARCHAR | |
| email | VARCHAR UNIQUE | |
| date_of_birth | DATE | |
| gender | VARCHAR | male / female / other |
| weight_kg | FLOAT | current weight |
| height_cm | FLOAT | |
| goal_weight_kg | FLOAT | |
| activity_level | VARCHAR | sedentary / light / moderate / active |
| daily_calorie_target | INT | calculated on onboarding |
| daily_protein_g | INT | |
| daily_carbs_g | INT | |
| daily_fat_g | INT | |
| fcm_token | VARCHAR | updated on app launch |
| timezone | VARCHAR | e.g. "Asia/Jerusalem" |
| created_at | TIMESTAMP | |

### `daily_logs`
One row per user per day. The "macro budget ledger".

| Column | Type | Notes |
|---|---|---|
| id | UUID PK | |
| user_id | UUID FK → users | |
| log_date | DATE | |
| calories_consumed | INT | running total |
| protein_consumed_g | INT | |
| carbs_consumed_g | INT | |
| fat_consumed_g | INT | |
| calories_remaining | INT | computed: target - consumed |
| protein_remaining_g | INT | |
| carbs_remaining_g | INT | |
| fat_remaining_g | INT | |
| last_meal_at | TIMESTAMP | used by push daemon |
| updated_at | TIMESTAMP | |

### `meals`
Generated recipes stored for history and re-use.

| Column | Type | Notes |
|---|---|---|
| id | UUID PK | |
| user_id | UUID FK → users | |
| daily_log_id | UUID FK → daily_logs | |
| name | VARCHAR | e.g. "Chicken Wrap" |
| ingredients | JSONB | `[{name, grams, calories, protein, carbs, fat}]` |
| instructions | TEXT | |
| total_calories | INT | |
| total_protein_g | INT | |
| total_carbs_g | INT | |
| total_fat_g | INT | |
| craving_input | TEXT | what the user asked for |
| source | VARCHAR | manual / ai_generated / photo_scan |
| logged_at | TIMESTAMP | |

### `user_behavior_patterns`
Aggregated pattern data consumed by the push daemon.

| Column | Type | Notes |
|---|---|---|
| id | UUID PK | |
| user_id | UUID FK → users | |
| hour_of_day | INT | 0–23 |
| day_of_week | INT | 0–6 |
| avg_meals_logged | FLOAT | historical average for this slot |
| overeating_risk_score | FLOAT | 0.0–1.0, updated weekly |
| skip_risk_score | FLOAT | 0.0–1.0 |
| updated_at | TIMESTAMP | |

### `push_notification_logs`
| Column | Type | Notes |
|---|---|---|
| id | UUID PK | |
| user_id | UUID FK → users | |
| trigger_reason | VARCHAR | e.g. "skip_risk", "overeating_window" |
| message_body | TEXT | the LLM-generated message |
| meal_id | UUID FK → meals nullable | attached recipe, if any |
| sent_at | TIMESTAMP | |
| opened_at | TIMESTAMP nullable | tracked via deep link |

### `sos_sessions`
| Column | Type | Notes |
|---|---|---|
| id | UUID PK | |
| user_id | UUID FK → users | |
| started_at | TIMESTAMP | |
| ended_at | TIMESTAMP nullable | |
| messages | JSONB | `[{role, content, timestamp}]` full transcript |
| outcome | VARCHAR | resolved / abandoned / escalated |

### `ai_interactions`
Audit log of every LLM call.

| Column | Type | Notes |
|---|---|---|
| id | UUID PK | |
| user_id | UUID FK → users | |
| module | VARCHAR | macro_engine / push_agent / cbt_agent |
| prompt_version | VARCHAR | e.g. "macro_v2" — maps to prompts/ files |
| input_tokens | INT | |
| output_tokens | INT | |
| latency_ms | INT | |
| created_at | TIMESTAMP | |

---

## 3. Backend Folder Structure

```
backend/
├── main.py                        # FastAPI app factory, lifespan hooks
├── requirements.txt
├── .env                           # secrets (never committed)
├── alembic/                       # DB migrations
│   ├── env.py
│   └── versions/
│
├── app/
│   ├── api/
│   │   └── v1/
│   │       ├── __init__.py
│   │       ├── auth.py            # POST /auth/verify
│   │       ├── users.py           # GET/PUT /users/me, onboarding
│   │       ├── macros.py          # GET /macros/today, POST /macros/log
│   │       ├── meals.py           # POST /meals/generate, GET /meals/history
│   │       ├── sos.py             # WS /ws/sos
│   │       └── notifications.py   # POST /notifications/fcm-token
│   │
│   ├── agents/
│   │   ├── macro_engine.py        # LLM call: generate recipe from remaining macros
│   │   ├── push_agent.py          # LLM call: generate personalized push message
│   │   ├── cbt_agent.py           # LLM call: CBT dialogue step
│   │   └── prompts/
│   │       ├── macro_v1.txt       # system prompt for macro engine
│   │       ├── push_coach_v1.txt  # system prompt for push agent
│   │       └── cbt_v1.txt         # system prompt for CBT module
│   │
│   ├── core/
│   │   ├── config.py              # pydantic-settings: env vars
│   │   ├── database.py            # SQLAlchemy async engine + session
│   │   ├── firebase_admin.py      # Firebase Admin SDK init + token verify
│   │   └── dependencies.py        # FastAPI Depends: get_db, get_current_user
│   │
│   ├── models/                    # SQLAlchemy ORM table definitions
│   │   ├── user.py
│   │   ├── daily_log.py
│   │   ├── meal.py
│   │   ├── behavior_pattern.py
│   │   ├── push_log.py
│   │   ├── sos_session.py
│   │   └── ai_interaction.py
│   │
│   ├── schemas/                   # Pydantic request/response models
│   │   ├── user.py
│   │   ├── meal.py
│   │   ├── macros.py
│   │   └── sos.py
│   │
│   ├── services/                  # Pure business logic (no HTTP, no DB)
│   │   ├── macro_service.py       # compute remaining budget, update daily_log
│   │   ├── behavior_service.py    # read/write behavior patterns
│   │   └── notification_service.py # send FCM via Firebase Admin
│   │
│   └── workers/
│       ├── scheduler.py           # APScheduler setup, registers all jobs
│       ├── push_worker.py         # CRON job: scan users, trigger push if needed
│       └── behavior_analyzer.py   # CRON job: weekly pattern aggregation
```

---

## 4. Core API Flow — Dynamic Macro Engine

### Endpoint
```
POST /api/v1/meals/generate
Authorization: Bearer <firebase_id_token>
```

### Request body
```json
{
  "craving_input": "I want something with chocolate",
  "input_type": "text"          // "text" | "photo_b64" | "craving_button"
}
```

### Step-by-step flow

```
Flutter → POST /meals/generate
           │
           ▼
   [1] Firebase token verified → resolve user_id
           │
           ▼
   [2] Load today's daily_log for user
       → calories_remaining, protein_remaining_g, carbs_remaining_g, fat_remaining_g
           │
           ▼
   [3] If input_type == "photo_b64"
       → Vision call to LLM: "What ingredients are visible?"
       → Extract ingredient list as text, continue as text input
           │
           ▼
   [4] Build LLM payload:
       system_prompt = load("prompts/macro_v1.txt")
       user_message  = {
           craving: "chocolate",
           remaining: { calories: 480, protein: 35g, carbs: 50g, fat: 12g }
       }
       response_format = { type: "json_object" }   ← STRICT JSON mode
           │
           ▼
   [5] LLM returns structured JSON:
       {
         "name": "Chocolate Protein Mug Cake",
         "ingredients": [
           { "name": "whey protein", "grams": 30, "calories": 120, "protein": 24, "carbs": 3, "fat": 2 },
           ...
         ],
         "instructions": "...",
         "total_calories": 310,
         "total_protein_g": 34,
         "total_carbs_g": 28,
         "total_fat_g": 8
       }
           │
           ▼
   [6] Validate: total macros ≤ remaining budget (server-side guard)
       If over budget → retry LLM call once with stricter constraint note
           │
           ▼
   [7] INSERT into meals table
       UPDATE daily_log: add consumed macros
       INSERT into ai_interactions (audit log)
           │
           ▼
   [8] Return meal object to Flutter → render recipe card
```

### `prompts/macro_v1.txt` contract
The system prompt must instruct the LLM to:
- Return **only valid JSON**, no prose
- Never exceed the provided macro budget
- Use realistic, purchasable ingredients
- Keep preparation time under 20 minutes unless user specifies otherwise

---

## 5. Proactive Daemon Design (Push Coach)

### Overview
A background service running inside the FastAPI process (via APScheduler) that scans all active users every 15 minutes and sends a personalized push notification if a risky condition is detected.

### Scheduler Setup (`workers/scheduler.py`)
```
APScheduler AsyncIOScheduler
  Job 1: push_worker.run()          → every 15 minutes
  Job 2: behavior_analyzer.run()    → every Sunday 02:00 UTC
```
The scheduler starts in FastAPI's `lifespan` context (startup/shutdown hooks in `main.py`).

### Push Worker Logic (`workers/push_worker.py`)

```
EVERY 15 MINUTES:

[1] Query DB: all users where fcm_token IS NOT NULL
         and last active within last 7 days

[2] For each user (batched, async):

    a) Load today's daily_log
       → calories_consumed, last_meal_at

    b) Load user_behavior_patterns for current hour + day_of_week
       → skip_risk_score, overeating_risk_score

    c) TRIGGER CONDITIONS (any one triggers a push):
       ┌─────────────────────────────────────────────────────┐
       │ SKIP RISK: now - last_meal_at > 5h                  │
       │            AND skip_risk_score > 0.6                │
       ├─────────────────────────────────────────────────────┤
       │ OVEREATING RISK: overeating_risk_score > 0.7        │
       │                  AND calories_remaining < 200       │
       ├─────────────────────────────────────────────────────┤
       │ END OF DAY: time is 20:00–21:00 local               │
       │             AND calories_remaining > 400            │
       └─────────────────────────────────────────────────────┘

    d) If triggered:
       → Check push_notification_logs: was a push sent in last 3h?
         If yes: skip (avoid spam)

       → Call push_agent.py:
           system_prompt = load("prompts/push_coach_v1.txt")
           context = { user_name, trigger_reason, calories_remaining,
                       last_meal_at, current_time }
           → LLM returns: { title, body, attached_recipe (optional) }

       → If attached_recipe: call macro_engine to generate + save a meal
           (pre-populate the user's screen silently)

       → Send FCM via Firebase Admin SDK
           payload: { title, body, data: { meal_id, deep_link } }

       → INSERT into push_notification_logs

[3] Log summary: X users scanned, Y notifications sent
```

### Behavior Analyzer (`workers/behavior_analyzer.py`)

Runs weekly. For each user:
- Aggregates all `daily_logs` over past 30 days
- For each hour-of-day × day-of-week slot: calculates historical meal frequency
- Identifies "black hole" windows → writes `skip_risk_score` + `overeating_risk_score` to `user_behavior_patterns`

---

## 6. SOS / Real-Time CBT Module

### Connection
```
Flutter opens: WS wss://api.fitbuddy.app/ws/sos?token=<firebase_id_token>
```

### Server-side flow
```
[1] On connect:
    → Verify Firebase token from query param
    → Load user profile + today's daily_log
    → Create new sos_sessions row (started_at = now)
    → Send opening CBT message (from cbt_v1.txt prompt)

[2] On each message received:
    → Append {role: "user", content, timestamp} to session messages (JSONB)
    → Build full conversation history
    → Call cbt_agent.py with CBT system prompt + history
    → Stream LLM response back to Flutter token-by-token (SSE-style over WS)
    → Append {role: "assistant", content} to session messages

[3] On disconnect / "I'm okay" button:
    → UPDATE sos_sessions: ended_at, outcome
    → Session transcript persisted for future personalization
```

### CBT System Prompt contract (`prompts/cbt_v1.txt`)
The prompt must:
- Never prescribe medication or act as a therapist
- Focus on the 3-question CBT interrupt: **What am I feeling? What triggered it? What do I actually need?**
- Gently redirect towards a small, healthy action (a glass of water, a 2-min walk, a light snack)
- Escalate with a crisis resource message if user input contains distress keywords

---

## 7. Flutter App Module Map

```
mobile/lib/
├── main.dart
├── core/
│   ├── api_client.dart        # Dio HTTP client with auth interceptor
│   ├── ws_client.dart         # WebSocket manager for SOS
│   └── firebase_service.dart  # FCM token registration, deep links
│
├── features/
│   ├── auth/                  # Firebase login/signup screens
│   ├── dashboard/             # Daily macro ring + meal feed
│   ├── meal_generator/        # Craving input → recipe card
│   ├── sos/                   # SOS button + real-time chat UI
│   └── notifications/         # Push notification inbox + deep link handler
│
└── shared/
    ├── widgets/
    └── models/                # Dart models matching backend Pydantic schemas
```

---

## 8. Environment & Configuration

```
# backend/.env
DATABASE_URL=postgresql+asyncpg://user:pass@localhost/fitbuddy
FIREBASE_CREDENTIALS_JSON=./firebase-service-account.json
OPENAI_API_KEY=sk-...
LLM_PROVIDER=openai                  # or "anthropic"
LLM_MODEL=gpt-4o
PUSH_WORKER_INTERVAL_MINUTES=15
SKIP_RISK_THRESHOLD_HOURS=5
PUSH_COOLDOWN_HOURS=3
```

All config values are loaded via `pydantic-settings` in `core/config.py`. No hardcoded values anywhere.

---

## Approval Checklist

Before implementation begins, confirm:

- [ ] LLM provider choice: **OpenAI GPT-4o** or **Anthropic Claude 3.5**?
- [ ] Deployment target: Docker on a VPS (e.g. Railway, Render) or managed cloud (AWS/GCP)?
- [ ] Push worker: run inside FastAPI process (APScheduler) or as a separate Celery worker?
- [ ] Flutter state management preference: **Riverpod**, **Bloc**, or **Provider**?
- [ ] Should the photo-scan (fridge photo) feature be included in Phase 1 or deferred?
