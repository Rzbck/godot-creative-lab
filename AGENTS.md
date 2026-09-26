# AGENTS.md — DataC0re Creative Lab

This repository is a Godot 4.7.1 creative-coding workstation developed through human + AI sessions.

The repository itself is the continuity system. Do not reconstruct the project only from chat memory.

## Bootstrap for every substantial session

Before modifying anything:

1. Resolve the real remote branch HEAD and CI state from GitHub.
2. Read this file.
3. Read `HANDOFF.md`.
4. Read `docs/handoff/CURRENT_WORK.md` and `docs/handoff/OPERATIONS.md`.
5. Read `docs/handoff/project_state.json`.
6. Read `docs/ARCHITECTURE.md` and `docs/SKETCH_CONTRACT.md` for the implemented runtime/sketch model.
7. Inspect the exact scene/script/shader involved before proposing changes.
8. For creative/design work, consult relevant `knowledge/` material before inventing from model memory alone.

If documentation disagrees with current code or telemetry, investigate. Git HEAD + runtime evidence win.

## Evidence vocabulary

- **HOST_VALIDATED** — observed on user's real Windows/Godot runtime.
- **REPO_VALIDATED** — committed state validated by CI/repository checks.
- **IMPLEMENTED_NOT_VALIDATED** — code exists but required validation missing.
- **EXPERIMENTAL** — prototype/hypothesis.
- **BLOCKER** — prevents next safe step.
- **NEXT** — agreed next operation.

Existing code is not automatically validated behavior.

## Git discipline

- Repository: `Rzbck/godot-creative-lab`.
- Never merge/change `main` without explicit user approval.
- Feature-branch commits/pushes through GitHub are expected.
- Keep current stacked branch/PR structure unless concrete reason to change.
- Never force-push routinely or destructive reset/clean casually.
- Never overwrite unrelated concurrent work.
- Never instruct user to use blind `git add -A`.
- Human validation decides promotion/merge.

## User workflow

The user does not want to write code manually.

Preferred loop:

1. AI inspects GitHub/telemetry.
2. AI edits feature branch directly.
3. AI updates durable handoff/state in same work session.
4. AI resolves exact final remote HEAD.
5. AI waits for CI on that exact HEAD and verifies all required jobs.
6. If host validation useful, AI automatically supplies canonical PowerShell `sync + exact-head CI wait + launch` from `docs/handoff/OPERATIONS.md`.
7. User tests.
8. AI reads online telemetry before asking for copied logs/screenshots.

PowerShell must be a complete copy/paste `& { ... }` block.

## Mandatory AI completion protocol

After any material repository change (runtime, sketch, architecture, creative direction, validation, knowledge rules, branch/PR state, or NEXT), before final response:

1. Commit/push intended work to active feature branch.
2. Update `docs/handoff/CURRENT_WORK.md` when durable state/rejection/validation/NEXT changed.
3. Update `HANDOFF.md` when future session would reconstruct wrong state.
4. Update `docs/handoff/project_state.json` when machine-readable state/constraints changed.
5. Update `docs/handoff/NEXT_AI_PROMPT.md` when startup rules/method/NEXT changed.
6. Update `docs/handoff/OPERATIONS.md` when canonical test/sync/launch or regression workflow changed.
7. Resolve final remote branch HEAD **after all documentation commits**.
8. Wait for and inspect CI for that exact SHA. Never use an older green run for a newer HEAD.
9. Report exact short HEAD + CI.
10. If host validation benefits the work, include canonical PowerShell automatically.
11. After host test, inspect `telemetry/runtime` first.

Continuity is part of task completion, not optional cleanup.

## Automated validation

Local standard check: `scripts/check.ps1`

GitHub CI: `.github/workflows/ci.yml`

Expected gates:

- repository policy;
- Godot 4.7.1 headless import;
- main-scene smoke test;
- no tracked-file modification caused by import.

Runtime/code work is not finished until relevant CI is green.

### Full-canvas render gate

A node named `ShaderSurface` is a full artwork surface.

It must use:

`res://sketches/_shared/full_canvas_surface.gd`

Never use a fixed physical 1280×720 `ShaderSurface`; logical design coordinates may remain 1280×720 while the actual render surface follows the real SubViewport.

Repository policy fails if a runtime scene contains `ShaderSurface` without the shared component or restores fixed 1280/720 offsets. The host also emits `sketch_surface_contract` telemetry. Do not weaken this guard to get a sketch through CI; fix the sketch representation.

## Telemetry-first debugging

Before asking the user for logs, inspect sanitized public telemetry:

- branch `telemetry/runtime`
- `latest.jsonl`
- `sessions/`

Telemetry covers window/layout/render/PROGRAM/input/resize plus Gallery curation and render-surface coverage. Publication is async; a publisher PID is not proof upload succeeded. Verify remote branch and matching tested HEAD/session.

## Explicit user review data

Each sketch can be rated 1–5 on:

- visual;
- interaction;
- originality;
- aliveness;
- controls;
- performance.

Ratings persist locally and `sketch_review_changed` telemetry exposes sanitized numeric scores.

When structured review data exists, treat it as **first-class creative evidence**. Use it to decide which mechanisms/aesthetics/interactions to repeat, mutate, refine or avoid. Do not override explicit scores with speculative taste inference.

## User curation / Trash

The workstation supports reversible local Trash and delayed local retirement.

- do not delete `res://sketches/...` source files from the runtime;
- `PURGE` in the app means remove permanently from this workstation Gallery, not Git deletion;
- actual source deletion is a separate explicit repo action;
- do not casually resurrect locally retired work in normal Gallery loading.

## Product behavior that must not regress

- Workstation usable while PROGRAM/LIVE OUT runs on selected display.
- Gallery/Settings/project navigation does not stop PROGRAM.
- Another PREVIEW can replace PROGRAM via TAKE LIVE.
- Touch/mouse on physical output controls PROGRAM sketch.
- Linked PREVIEW/PROGRAM represent same generative state.
- Per-sketch parameters persist.
- Gallery cards show real thumbnails; only hovered preview animates.
- Gallery discovery/search/filtering generated from metadata.
- Permanent tag UI remains bounded: generated quick rail + collapsed MORE, search indexes all tags.
- Full-canvas artwork surfaces cover actual PREVIEW/PROGRAM viewport; no accidental gray due to fixed sketch surface.
- PROGRAM contains no debug/title chrome unless intentionally artwork.
- Selecting fullscreen display does not move/destroy workstation UI.

## Sketch contract

Creative works live under `sketches/<id>/`, discovered from `definition.json`.

Host owns Gallery/navigation/PROGRAM transport/reviews/curation. Sketches own creative rendering, parameters and generative state.

For synchronized live rendering, use existing live-sync contract rather than unrelated second simulation.

Read `docs/SKETCH_CONTRACT.md` before adding a new rendering pattern.

Do not fake Spout/NDI; they remain future adapters.

## Knowledge library

- `knowledge/creative-coding/` — shaders, simulations, feedback, particles, fields, geometry/GPU.
- `knowledge/design/` — typography, layout, hierarchy, color, realtime design translation.
- `knowledge/cross-domain/` — technique palette, collision-first exploration, physics/chemistry, coupling, performance and idea mutation.

For substantial exploration prioritize current pointers in `CURRENT_WORK.md` / `HANDOFF.md`.

Use sources as research starting points. Do not vendor/copy third-party code/assets blindly; check license/provenance.

## Handoff maintenance

Store concise state, evidence, decisions, branch/PR references, failures, validation and next actions. Do not store chat transcripts.
