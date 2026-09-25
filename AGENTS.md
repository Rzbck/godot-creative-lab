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
6. Read `docs/ARCHITECTURE.md` for the implemented runtime model.
7. Inspect the exact scene/script/shader involved before proposing changes.
8. For creative/design work, consult the relevant material under `knowledge/` before inventing from model memory alone.

If documentation disagrees with current code or telemetry, investigate. Git HEAD + runtime evidence win.

## Evidence vocabulary

Keep these states distinct:

- **HOST_VALIDATED** — observed on the user's real Windows/Godot runtime.
- **REPO_VALIDATED** — committed state validated by CI/repository checks.
- **IMPLEMENTED_NOT_VALIDATED** — code exists but required validation is missing.
- **EXPERIMENTAL** — prototype/hypothesis, not a stable product behavior.
- **BLOCKER** — prevents the next safe step.
- **NEXT** — agreed next operation.

Existing code is not automatically validated behavior.

## Git discipline

- Repository: `Rzbck/godot-creative-lab`.
- `main` is not to be merged/changed without explicit user approval.
- Feature-branch commits/pushes through the GitHub connector are expected during normal work.
- Keep the current stacked branch/PR structure unless there is a concrete reason to change it.
- Never force-push as routine recovery.
- Never use destructive reset/clean without explicit need.
- Never overwrite unrelated concurrent work.
- Never instruct the user to use blind `git add -A`.
- Human validation decides promotion/merge to `main`.

## User workflow

The user does not want to write code manually.

Preferred loop:

1. AI inspects GitHub/telemetry.
2. AI edits the feature branch directly.
3. AI updates durable handoff/state documentation in the same work session.
4. AI resolves the exact final remote HEAD.
5. AI waits for CI on that exact HEAD and verifies every required job.
6. If host validation is useful, AI automatically gives the canonical PowerShell **sync + wait-for-CI + launch** block from `docs/handoff/OPERATIONS.md`; the user should not have to ask for it.
7. User tests behavior.
8. AI reads online telemetry before asking for copied logs.

PowerShell blocks supplied to the user must be complete copy/paste blocks wrapped in:

```powershell
& {
    ...
}
```

The known workstation paths and canonical block are documented in `docs/handoff/OPERATIONS.md`.

## Mandatory AI completion protocol

This protocol applies after any **material repository change**: runtime/code, sketch content, architecture, creative direction, validation procedure, knowledge-system rules, branch/PR state, or NEXT action.

Before giving the final user response, the AI must, without waiting to be reminded:

1. Commit/push all intended work to the active feature branch.
2. Update `docs/handoff/CURRENT_WORK.md` whenever current durable state, rejected direction, validation status, or NEXT changed.
3. Update `HANDOFF.md` when a future session would otherwise reconstruct the wrong product/creative state.
4. Update `docs/handoff/project_state.json` when machine-readable state/constraints/knowledge pointers changed.
5. Update `docs/handoff/NEXT_AI_PROMPT.md` when startup rules, creative method, or immediate next task changed.
6. Update `docs/handoff/OPERATIONS.md` when the canonical test/sync/launch workflow changed.
7. Resolve the final remote branch HEAD **after all documentation commits**.
8. Wait for and inspect CI for that exact final SHA. Never report an older green run as validation of a newer HEAD.
9. Report the exact short HEAD and CI result.
10. If the work needs or benefits from Windows host validation, include the canonical PowerShell block that syncs, waits for CI success for the exact SHA, and only then launches Godot.
11. After the user's host test, inspect `telemetry/runtime` before asking for logs or screenshots that telemetry can answer.

Do not leave continuity/documentation as an optional cleanup step. It is part of task completion.

## Automated validation

Local standard check:

`scripts/check.ps1`

GitHub CI:

`.github/workflows/ci.yml`

Expected CI gates:

- repository policy;
- Godot 4.7.1 headless import;
- main-scene runtime smoke test;
- no tracked-file modifications caused by Godot import.

A runtime/code change is not finished until the relevant CI is green.

## Telemetry-first debugging

Before asking the user for logs, inspect the sanitized public telemetry branch:

- branch: `telemetry/runtime`
- rolling file: `latest.jsonl`
- historical snapshots: `sessions/`

Telemetry was built specifically to debug window state, layout, rendering, PROGRAM/LIVE OUT, touch input and resize behavior. It publishes asynchronously so Git/network work must not block the Godot UI.

Do not claim a publisher PID means upload succeeded; verify the telemetry branch itself. Do not ask the user to copy information that is already present there.

## Product behavior that must not regress

- Workstation UI remains usable while PROGRAM/LIVE OUT runs on a selected display.
- Gallery/Settings/project navigation must not automatically stop the current PROGRAM output.
- Another preview can replace the current PROGRAM via `TAKE LIVE`.
- Touch/mouse input on the physical output display controls the PROGRAM sketch.
- While editor and PROGRAM are linked, preview and output must represent the same generative state.
- Per-sketch parameters persist across app sessions.
- Gallery cards show real rendered thumbnails; only the hovered preview animates.
- Gallery organization/search/filtering is generated from `definition.json` tags/metadata.
- Gallery permanent tag UI must remain bounded/scalable: do not restore a permanently expanded all-tags wall. Current behavior uses a generated quick rail plus collapsed `MORE` drawer while search indexes every tag.
- Final PROGRAM output contains no debug labels or sketch-title chrome unless text is intentionally part of the artwork.
- Selecting a fullscreen display must not move/destroy the workstation UI.

## Sketch contract

Creative works live under `sketches/<id>/` and are discovered from `definition.json`.

The host owns Gallery/navigation/PROGRAM transport. Sketches own their creative rendering and parameter/state contract.

For synchronized live rendering, sketches should expose the existing runtime synchronization methods used by the implemented sketches, rather than creating an unrelated second generative simulation.

Do not fake Spout or NDI. They remain future adapters until actually implemented and validated.

## Knowledge library

External research memory is versioned in the repo:

- `knowledge/creative-coding/` — shaders, simulation, generative systems, GPU techniques, references.
- `knowledge/design/` — typography, graphic design, grids, hierarchy, color, poster/layout systems, realtime-design translation and review checklist.
- `knowledge/cross-domain/` — technique palette, collision-first exploration, bridges, mutation and living-system research.

For substantial creative exploration, current priority is:

1. `knowledge/cross-domain/TECHNIQUE_PALETTE.md`
2. `knowledge/cross-domain/RANDOM_COLLISION_ENGINE.md`
3. `knowledge/cross-domain/COLLISION_SOURCE_CATALOG.md`
4. relevant creative-coding/design atlases
5. `knowledge/cross-domain/CROSS_DOMAIN_ATLAS.md` / `IDEA_ENGINE.md` when shaping a promising collision into an artwork.

Use sources as research starting points. Do not vendor/copy third-party code blindly; check license/provenance first.

## Handoff maintenance

Handoff maintenance is mandatory under the completion protocol above, not an optional later task.

Do not store conversation transcripts. Store concise state, evidence, decisions, branch/PR references, known failures, validation results and next actions.
