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
- `main` must not be merged/changed without explicit user approval.

Use GitHub to resolve the actual current HEAD because handoff/documentation commits occur after any recorded implementation baseline.

## Product now implemented

DC//LAB is a functioning custom Godot creative-coding workstation with:

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
- external creative-coding + design/typography + cross-domain research libraries under `knowledge/`.

## Current sketches

### 001 — SIGNAL FIELD

Technical/test sketch: moving signal points, distance connections and pointer interaction. It established the basic sketch/parameter/live-sync contract. Keep it primarily as a contract/regression reference; do not force it into the artistic direction merely for visual consistency.

### 002 — LIQUID TYPE

Interactive generative typography with elastic deformation / chromatic behavior. The 2026-09-24 knowledge-driven refinement adds gesture-velocity memory: authored motion changes tracking, wave phase, tangential field response, smear and chromatic direction instead of acting only as a radial cursor deformation.

### 003 — CHROMA LENS

Typographic field with chromatic interactive lens. `GRID DENSITY` still preserves the controlled centered safe area. The current refinement adds stable per-cell hierarchy, four quantized graphic lens states and a seven-column/baseline background structure so the lens behaves like a realtime editorial system rather than an undifferentiated radial effect.

### 004 — GOMMAGE TYPE

Interactive erase/rebuild typography with dust/trail behavior. The current refinement stores directional gesture velocity in each erosion mark: fast gestures create anisotropic erase regions, dust inherits gesture direction and residual mark traces encode authored motion while the work rebuilds.

### 005 — PRESSURE LATTICE

New cross-domain Godot `canvas_item` shader approved by the user on 2026-09-24.

Concept chain:

`editorial modular grid -> procedural signal field -> gesture-injected vector pressure -> decaying temporal memory -> duotone identity`

Implementation:

- scene: `res://sketches/005_pressure_lattice/runtime/pressure_lattice.tscn`;
- runtime: `pressure_lattice.gd` extends the shared design/live-sync base;
- shader: `pressure_lattice.gdshader`;
- four synchronized decaying gesture-memory marks are passed into the shader;
- parameters expose grid columns, field strength, line density, memory decay, gesture energy, contrast, pulse and palette;
- no debug/project title is burned into PROGRAM output.

The first CI after adding 005 passed import/smoke and failed only because Godot generated the new `.gd.uid` and `.gdshader.uid`; those UID files were then explicitly tracked. Resolve the newest CI before calling the final implementation `REPO_VALIDATED`.

## PROGRAM / LIVE OUT architecture — validated direction

The key architectural decision is **PREVIEW/EDITOR and PROGRAM are separate responsibilities**.

The workstation must stay open and usable while PROGRAM runs on a selected display.

Expected workflow:

1. Open a project in editor.
2. Send it to `LIVE OUT` / PROGRAM on a selected display.
3. Return to Gallery or Settings; the live project keeps running on PROGRAM.
4. Open another project in PREVIEW while the previous project is still live.
5. Press `TAKE LIVE`; the PREVIEW project replaces PROGRAM.

Navigation is not a transport stop command.

When editor and PROGRAM are linked to the same project, the editor simulation is the authority and PROGRAM follows its runtime state. When the user navigates away, PROGRAM detaches and continues autonomously from the last synchronized state.

The active runtime scene is `res://app/main/main_runtime.tscn`. Inspect its script and `extends` chain before changing output behavior. Current top-level runtime layers include Gallery organizer -> PROGRAM output -> Gallery persistence -> LIVE output, with lower window/telemetry layers beneath them.

## Input / touch — HOST_VALIDATED foundation

A physical touchscreen can be selected as the PROGRAM display. Touch/drag/mouse events from the native PROGRAM window are mapped into the sketch logical coordinate space and forwarded to the correct live sketch.

This must keep working even when the workstation is in Gallery or editing a different project while another project remains in PROGRAM.

The shared foundation is host-validated. Any newly introduced sketch-specific interaction, including 005, still requires a host pass before its exact visual/tactile behavior is promoted to `HOST_VALIDATED`.

## Preview / PROGRAM synchronization

A major past bug was having two independent generative simulations: editor preview and output looked different.

Current rule: a linked PROGRAM renderer is a follower, not an independent second timeline. Runtime generative state (e.g. time/pointer/custom memory state) is synchronized through the sketch live-sync contract. Resolution differences must not alter the composition logic; current design sketches use a stable logical design space.

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

### Cross-domain translation + idea generation

`knowledge/cross-domain/`

This layer turns the two libraries above into a concept engine rather than a reference archive.

Current files:

- `README.md` — vocabulary and usage model;
- `CROSS_DOMAIN_ATLAS.md` — representation changes and bridges such as type -> geometry/SDF, grid -> coordinate system, interaction -> force field, simulation -> graphic language and feedback -> memory;
- `IDEA_ENGINE.md` — multiplier decks, mutation passes, originality checks, identity anchors and candidate filter;
- `SOURCE_CATALOG.md` — sources chosen specifically because they cross disciplines;
- `sources.json` — machine-readable bridge metadata for future tooling.

For substantial new creative work, use at least one genuine representation change and normally combine three or more domains. Do not implement the first coherent combination unchanged: mutate it deliberately until the concept has its own internal logic and visual identity.

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
- when host validation is required, give one compact PowerShell `& { ... }` block;
- before asking for logs, inspect telemetry online.

See `docs/handoff/OPERATIONS.md` for the exact tested PowerShell patterns.

## CURRENT WORK / NEXT

1. Resolve the final CI for the latest 002–005 creative pass.
2. User host-tests Gallery previews plus PREVIEW/PROGRAM/touch for 002–005, especially the new 005 shader.
3. After that test, inspect `telemetry/runtime` before asking for logs and fix any runtime-specific visual/input issue with evidence.
4. Keep using all three knowledge layers for future creative work: technical vocabulary + professional design discipline + cross-domain mutation.
5. Keep Gallery / PROGRAM / persistence / touch / telemetry stable.
6. Longer-term live-performance direction may include A/B/C decks, crossfade/mix, timeline/cues/compositing — do not build that without an explicit user task.
7. Spout and NDI remain future adapters and must not be faked.

For a fresh AI session, use the prompt in `docs/handoff/NEXT_AI_PROMPT.md`.
