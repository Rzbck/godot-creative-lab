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
   - `knowledge/cross-domain/`
6. For a substantial new artwork/shader, specifically read `knowledge/cross-domain/CROSS_DOMAIN_ATLAS.md` and `knowledge/cross-domain/IDEA_ENGINE.md`. Use them to generate and mutate a concept before implementation; do not simply combine a single visual reference with a stock effect.
7. Resolve current CI status before assuming the branch is healthy.
8. If the user's message follows a runtime test, read the online sanitized telemetry branch `telemetry/runtime` (`latest.jsonl` and session snapshots as necessary) before asking for copied logs.

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
- 001 Signal Field — technical foundation/test patch; preserve mainly as a contract/regression reference.
- 002 Liquid Type — refined with gesture-velocity memory affecting spacing, phase, field direction, smear and chromatic behavior.
- 003 Chroma Lens — refined with fixed safe margins, stable cell hierarchy, quantized graphic lens states and seven-column editorial structure.
- 004 Gommage Type — refined with directional gesture-memory in erosion, dust and residual marks.
- 005 Pressure Lattice — real Godot `canvas_item` shader crossing editorial grid, procedural field, gesture-injected vector pressure, decaying temporal memory and duotone identity.

`005_pressure_lattice` is approved and implemented. Do not rely on older documentation claiming there is no 005. Do not invent 006 unless the user asks for another creative work.

There is a versioned external knowledge library in the repo. It has three layers:

- `knowledge/creative-coding/` — technical methods and generative/GPU vocabulary;
- `knowledge/design/` — typography, composition, grids, color, hierarchy and professional design constraints;
- `knowledge/cross-domain/` — representation bridges, mutation operators and an idea engine for producing original identities from the first two layers.

For substantial new work, extract principles from several independent references, build genuine representation changes between domains, mutate the first coherent combination, and define persistent identity rules before choosing the Godot implementation.

The current immediate validation task is to host-test the knowledge-driven 002–005 creative pass, especially 005 in PREVIEW and PROGRAM with touch/mouse interaction. If the user reports a test result, inspect `telemetry/runtime` before asking for logs.

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
