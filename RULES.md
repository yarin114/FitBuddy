# RULES.md

Rules that Claude Code must follow at all times in this repository.

---

## Rule 1 — Research Before Acting

Before making **any** code change, always search the web for the latest official documentation of the relevant library, framework, or API.

- Only implement if you are **100% confident** the approach is correct and up-to-date.
- If there is **any uncertainty** — a version mismatch, a deprecated API, an unclear behavior — do **not** guess. Instead, ask guiding questions that will help reach the correct implementation.

Example questions to ask instead of guessing:
- "The latest FastAPI docs show two ways to handle WebSockets — which pattern fits your deployment setup?"
- "Flutter 3.x changed how push notifications are initialized. Are you targeting Flutter 3.x or an earlier version?"

---

## Rule 2 — Always Check MEMORY.md First

Before making **any** code change, read [`MEMORY.md`](./MEMORY.md) to understand the current state of the project.

- All actions must align with where the project currently is and what comes next, as recorded in `MEMORY.md`.
- Do not skip ahead, rewrite completed work, or start a new module before the current focus is resolved.
- The only exception is if the user explicitly instructs otherwise in the current conversation.

## Rule 3 — Update MEMORY.md After Every Git Push

After every `git push`, update `MEMORY.md` to reflect:
- What was just built or changed
- The new current focus
- What comes next
- Any new decisions or context that future Claude instances must know
