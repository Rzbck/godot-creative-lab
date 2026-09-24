# Prompt for the next AI session

Copy/paste the block below into a new AI conversation that has access to the GitHub repository.

---

You are taking over the ongoing project **DC//LAB / Godot Creative Lab**.

Repository:
`Rzbck/godot-creative-lab`

Do **not** rely on previous-chat memory. Reconstruct the current state from the repository and GitHub evidence.

## Mandatory startup procedure

1. Resolve the current remote HEAD of branch `feat/creative-sketches-002-004-20260924` and inspect draft PR #7.
2. Read, in this order:
   - `AGENTS.md`
   - `HANDOFF.md`
   - `docs/handoff/CURRENT_WORK.md`
   - `docs/handoff/OPERATIONS.md`
   - `docs/handoff/project_state.json`
   - `docs/ARCHITECTURE.md`
3. Inspect `app/main/main_runtime.tscn` and follow the actual `extends` chain of the runtime script before changing Gallery/PROGRAM/window/telemetry behavior.
4. Inspect the exact sketch/runtime files involved in the user's next request.
5. If the request is creative/design related, read the relevant material under:
   - `knowledge/creative-coding/`
   - `knowledge/design/`
6. Resolve current CI status before assuming the branch is healthy.
7. If the user's message follows a runtime test, read the online sanitized telemetry branch `telemetry/runtime` (`latest.jsonl` and session snapshots as necessary) before asking for copied logs.

## Operating rules

- Work directly through GitHub on the active feature branch when code/docs changes are needed.
- The user should not have to write code manually.
- Do not merge or modify `main` without explicit user approval.
- Do not force-push/reset as routine recovery.
- Do not use blind `git add -A` instructions.
- After runtime/code changes, verify GitHub CI (repository policy + Godot 4.7.1 headless import/smoke test/cleanliness) before saying the work is finished.
- When host validation is needed, give one concise copy/paste PowerShell block wrapped in `& { ... }`, using the canonical block in `docs/handoff/OPERATIONS.md`.
- Respond in concise French. The user writes quickly/phonetically; answer the intent rather than correcting spelling.
- Prefer concrete implementation/progress over generic explanation.

## Product behaviors that must not regress

- The DC//LAB workstation stays open and usable while PROGRAM/LIVE OUT runs on the selected physical display.
- Returning to Gallery/Settings/opening another project does **not** stop current PROGRAM output.
- Another PREVIEW can replace PROGRAM using `TAKE LIVE`.
- Touch/mouse input on the physical PROGRAM display controls the live sketch.
- Linked PREVIEW and PROGRAM represent the same generative runtime state; do not create two independent timelines.
- Per-sketch exposed parameters persist across application sessions.
- Gallery cards display real rendered thumbnails and only the hovered card animates.
- Gallery groups/search/tag filters are generated from `definition.json` metadata.
- Final output must not contain debug labels/title chrome unless text is intentionally the artwork.
- Telemetry publication must remain asynchronous and must not block Godot's main/UI thread.

## Current content / direction

Existing sketches:
- 001 Signal Field — technical foundation/test patch.
- 002 Liquid Type.
- 003 Chroma Lens.
- 004 Gommage Type.

Do not invent sketch 005 unless the user asks for a new creative work.

There is a versioned external knowledge library in the repo. Use it as the project's research memory rather than starting only from model memory. In particular, combine professional typography/graphic-design principles with realtime shader/generative techniques.

Longer-term live-performance direction may include A/B/C decks, crossfade/mixing, timeline/cues and compositing, but these are future directions, not automatic implementation tasks.

## First response behavior

After scanning the repository, briefly state:
- current branch + short HEAD;
- PR/CI state;
- what the current implemented product can do;
- any stale/conflicting docs you detected;
- the exact next task you understood from the user's request.

Then work on the request. Do not ask the user to re-explain project history that is already documented.

---
