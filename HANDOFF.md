# HANDOFF — DataC0re Creative Lab

Canonical restart point for a new human or AI session.

**Always resolve the current GitHub branch HEAD and CI before trusting any recorded SHA below.** The repository is the source of continuity; chat history is secondary.

Last material handoff refresh: **2026-09-24**.

## Repository / active work

- GitHub: `Rzbck/godot-creative-lab`
- Local workstation path: `E:\_Project\GodotCreativeLab`
- Godot GUI: `C:\Godot\Godot_v4.7.1-stable_win64.exe`
- Godot console: `C:\Godot\Godot_v4.7.1-stable_win64_console.exe`
- Engine: Godot `4.7.1.stable.official.a13da4feb`
- Renderer validated on host: Vulkan / Forward+ / NVIDIA GeForce RTX 5080
- Active branch: `feat/creative-sketches-002-004-20260924`
- Draft PR: `#7`, base `feat/gallery-project-workflow-20260923`
- Baseline immediately before this handoff refresh: `eef780c02ddc1535f1c252bf50ffbec7b1813ee0`
- CI at that baseline: green (`Repository policy` + `Godot 4.7.1 headless`)
- `main` must not be merged/changed without explicit user approval.

Use GitHub to resolve the actual current HEAD because handoff/documentation commits occur after the baseline above.

## Product now implemented

DC//LAB is no longer an architecture-only scaffold. It is a functioning custom Godot creative-coding workstation with:

- custom dark compact workstation UI;
- Gallery with dynamically discovered sketches;
- real rendered card thumbnails;
- hover-only animated Gallery previews to control GPU cost;
- automatic Gallery grouping from sketch tags;
- tag filters and text search across metadata;
- one active editor/preview sketch at a time;
- generated parameter inspector from each sketch contract;
- persistent per-sketch parameter values across sessions;
- selected physical output display in Settings;
- persistent PROGRAM/LIVE OUT output on a separate display while the workstation remains usable;
- `TAKE LIVE` replacement workflow so navigation does not stop PROGRAM;
- mouse/touch interaction forwarded from the physical output display to the live sketch;
- preview/PROGRAM runtime-state synchronization while linked;
- sanitized online telemetry for deep runtime debugging;
- external creative-coding + design/typography research libraries under `knowledge/`.

## Current sketches

### 001 — SIGNAL FIELD

Technical/test sketch: moving signal points, distance connections and pointer interaction. It established the basic sketch/parameter/live-sync contract. Do not treat it as the approved artistic direction for future work.

### 002 — LIQUID TYPE

Interactive generative typography with elastic deformation / chromatic behavior. Accepted as a Gallery entry even though visual refinement can continue.

### 003 — CHROMA LENS

Typographic field with chromatic interactive lens. The grid was corrected so `GRID DENSITY` preserves controlled centered margins and glyphs do not spill outside the intended composition.

### 004 — GOMMAGE TYPE

Interactive erase/rebuild typography with dust/trail behavior. Used heavily to validate tactile PROGRAM output.

Do not invent 005 or another new sketch without user approval.

## PROGRAM / LIVE OUT architecture — validated direction

The key architectural decision is **PREVIEW/EDITOR and PROGRAM are separate responsibilities**.

The workstation must stay open and usable while PROGRAM runs on a selected display.

Expected workflow:

1. Open project 004 in editor.
2. Send it to `LIVE OUT` / PROGRAM on a selected display.
3. Return to Gallery or Settings; 004 keeps running on PROGRAM.
4. Open 002 in PREVIEW while 004 is still live.
5. Press `TAKE LIVE`; 002 replaces 004 on PROGRAM.

Navigation is not a transport stop command.

When editor and PROGRAM are linked to the same project, the editor simulation is the authority and PROGRAM follows its runtime state. When the user navigates away, PROGRAM detaches and continues autonomously from the last synchronized state.

The active runtime scene is `res://app/main/main_runtime.tscn`. Inspect its script and `extends` chain before changing output behavior. Current top-level runtime layers include Gallery organizer -> PROGRAM output -> Gallery persistence -> LIVE output, with lower window/telemetry layers beneath them.

## Input / touch — HOST_VALIDATED

A physical touchscreen can be selected as the PROGRAM display. Touch/drag/mouse events from the native PROGRAM window are mapped into the sketch logical coordinate space and forwarded to the correct live sketch.

This must keep working even when the workstation is in Gallery or editing a different project while another project remains in PROGRAM.

## Preview / PROGRAM synchronization

A major past bug was having two independent generative simulations: editor preview and output looked different.

Current rule: a linked PROGRAM renderer is a follower, not an independent second timeline. Runtime generative state (e.g. time/pointer state) is synchronized through the sketch live-sync contract. Resolution differences must not alter the composition logic; current design sketches use a stable logical design space.

Do not reintroduce an independent second generator for a linked PROGRAM surface.

## Gallery — current behavior

Gallery is data-driven from each sketch `definition.json`.

Current features:

- static real render thumbnail per card;
- only hovered card animates;
- hover tooltip overlay that obscured cards was explicitly rejected/removed;
- first tag acts as the automatic primary group/family;
- all tags are generated as filters;
- search covers title/id/index/tags/engine/description;
- groups without matching results disappear;
- card grids remain responsive.

The user wants the Gallery to remain simple, clean and scalable to many sketches.

## Persistent settings

Sketch parameter values are stored locally under `user://creative_lab_sketch_settings.cfg`.

When the user changes exposed parameters they are persisted and restored next session. Gallery thumbnails also receive saved parameter values so the visual library reflects the user's configured versions.

## Telemetry — critical debugging system

Telemetry exists specifically so a new AI session does not ask the user to manually copy every log.

### Local runtime

Workspace telemetry is written under:

`res://.telemetry_runtime/`

This location is ignored by normal Git.

### Online sanitized telemetry

Repository is public. Only sanitized debug payloads are published to:

- branch: `telemetry/runtime`
- rolling latest: `latest.jsonl`
- historical session snapshots: `sessions/`

Payload is intended to exclude personal/account/path information and raw screenshot pixels. Git transport itself is still normal network infrastructure; do not make broad claims that GitHub sees no network metadata.

### Publication model

Publishing is asynchronous/queued so Git/network work does not block Godot. A printed publisher PID is not proof that a remote update succeeded. Verify the telemetry branch directly.

Telemetry has been used to diagnose:

- Windows/Godot fullscreen/exclusive mode transitions;
- window geometry and layout corruption;
- SubViewport render/update state;
- black/gray output differentiation;
- render probes via numerical frame metrics (not raw frames);
- resize/minimum-size overflow;
- output display selection;
- PROGRAM state;
- touch/mouse forwarding and coordinate mapping;
- live-sync counts/state.

Before changing window/output code after a user test, read the new telemetry first.

## Important history / rejected approaches

Fullscreen/output went through many failed approaches. Do not casually resurrect them:

- root overlay without physical output;
- switching the workstation root window to native/exclusive fullscreen and rebuilding UI afterward;
- secondary native window sampling the workstation SubViewport texture across windows (produced gray output on the host GPU/Windows path);
- concurrent synchronous telemetry Git pushes that blocked the main Godot thread and triggered Windows "not responding";
- independent output sketch simulation without runtime-state sync.

The current PROGRAM architecture was selected because it lets the workstation remain usable and provides a clean live-output mental model compatible with future A/B/C decks, crossfades and timeline/mixing.

## Knowledge library

Do not rely only on model memory when proposing future creative work.

### Creative coding

`knowledge/creative-coding/`

Contains curated references, source catalog, concept atlas and machine-readable sources covering shader math, noise, SDF/raymarching, particles, autonomous systems, simulations, feedback, procedural geometry, interaction/live, WebGPU/compute and related areas.

### Typography / graphic design / broader design

`knowledge/design/`

Current files include:

- `README.md`
- `SOURCE_CATALOG.md`
- `TYPOGRAPHY_ATLAS.md`
- `GRAPHIC_DESIGN_ATLAS.md`
- `REALTIME_DESIGN_BRIDGE.md`
- `DESIGN_REVIEW_CHECKLIST.md`
- `sources.json`

Use these to cross professional design principles (grid, hierarchy, margins, rhythm, typography, color, composition, poster systems) with realtime creative-coding techniques.

Do not blindly copy third-party source/code/assets; check license/provenance for the exact material.

## CI / validation

Workflow: `.github/workflows/ci.yml`

Expected gates:

- repository policy;
- Godot 4.7.1 setup/version;
- headless import;
- main-scene smoke test;
- verify Godot did not modify tracked files.

Local equivalent: `scripts/check.ps1`.

Do not tell the user a runtime/code change is finished until the relevant CI is green.

## Communication / operational preference

The user wants the AI to do the repo work directly and avoid generic explanations/manual busywork.

- concise French is preferred;
- do not ask the user to write code;
- commit directly on the active feature branch where appropriate;
- do not merge `main` without explicit approval;
- after code changes, verify CI;
- when host testing is required, provide one compact PowerShell `& { ... }` block;
- before asking for logs, inspect telemetry online.

See `docs/handoff/OPERATIONS.md` for the exact tested PowerShell patterns.

## CURRENT WORK / NEXT

The immediate product foundation is in a good usable state. Current development direction is:

1. Keep Gallery / PROGRAM / persistence / touch / telemetry stable.
2. Use the knowledge library when designing the next creative work rather than starting from memory alone.
3. Continue improving visual quality of existing sketches only when requested.
4. Longer-term live-performance direction: PROGRAM transport can evolve toward A/B/C decks, crossfade/mix, timeline/cues/compositing — but do not build that without an explicit user task.
5. Spout and NDI remain future adapters and must not be faked.

For a fresh AI session, use the prompt in `docs/handoff/NEXT_AI_PROMPT.md`.