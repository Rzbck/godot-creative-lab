# Current work — DC//LAB

Last refreshed: 2026-09-25.

## Active branch / PR

- branch: `feat/creative-sketches-002-004-20260924`
- draft PR: `#7`
- PR base: `feat/gallery-project-workflow-20260923`
- never merge/change `main` without explicit user approval
- always resolve final remote HEAD + exact-head CI after all material commits

## Stable product behavior to preserve

- Gallery real previews; only hovered card animates.
- Adaptive generated tag discovery + complete search.
- Per-sketch creative parameter persistence.
- PREVIEW / PROGRAM separation; navigation does not stop PROGRAM.
- `TAKE LIVE`, physical display selection and PROGRAM touch/mouse forwarding.
- Linked PREVIEW/PROGRAM state synchronization.
- Async sanitized telemetry on `telemetry/runtime`.
- logical artwork space usually `1280×720`, but render surfaces adapt to actual viewport.
- PROGRAM is artwork-only.
- local Trash never deletes Git source.
- workstation native window state persists across launches.

## Current top runtime

`app/main/main_runtime_window_memory.gd`

It extends `main_runtime_gallery_compact_review.gd`, then feedback/trash, adaptive filters, organizer, PROGRAM/output/window/telemetry layers.

## Window-state startup contract

Fresh host telemetry on runtime `9fa6d889...` proved startup was visibly wrong: the app appeared `1280×720` windowed and only about 730 ms later switched to fullscreen.

New layer `main_runtime_window_memory.gd` persists:

- native mode: windowed / maximized / fullscreen;
- current screen;
- window position and size;
- restore rect used by custom window controls.

State path:

`user://creative_lab_window_state.cfg`

Startup hides the root native window in `_enter_tree()`, applies the saved state before the normal `_ready()` chain, waits for layout to settle, then reveals the workstation. First run falls back to fullscreen. F11 artwork presentation must not overwrite workstation preference.

Status: **IMPLEMENTED_NOT_HOST_VALIDATED**. Required evidence is a Windows close/reopen test showing no visible small-window -> fullscreen jump and correct restoration after leaving the app windowed/maximized/fullscreen.

## Explicit user-rating evidence

Fresh telemetry session `session_5e0960d4c3e0c6a7.jsonl` contained a consolidated `creative_preference_snapshot` with **16 reviewed sketches**.

Axis averages:

- visual: 2.25
- interaction: 2.125
- originality: 2.125
- aliveness: 1.8125
- controls: 2.0
- performance: 3.0625

Important complete vectors:

- **020 ECHO TISSUE** — 4,4,4,4,4,5; avg ~4.17.
- **012 CHEMICAL BLOCKS** — 4,3,4,3,3,3; avg ~3.33.
- **017 EDGE BLOOM** — 3,3,3,3,2,3; avg ~2.83.
- **014 RIBBON MORPH** — 1,1,1,1,1,1; avg 1.0.
- **016 PREDATOR VEIN** — 1,1,1,2,1,3; avg 1.5.
- **024 GRANULAR JAM** — 1,2,1,1,2,3; avg ~1.67.
- **022 LIESEGANG FRONT** — 1,2,2,1,2,3; avg ~1.83.
- **025 FARADAY QUASI** — 3,2,2,1,2,3; avg ~2.17.

Interpretation for generation: aliveness and controls remain the weak global axes. Stronger evidence favors local propagation, neighbour coupling, delayed memory and interaction that changes future evolution. Do **not** simply copy 020; ratings remain bounded probability evidence and 24% of adaptive draws remain preference-free.

## REVIEW / curation

Permanent inspector row remains compact:

`REVIEW <avg>/5  RATE  TRASH`

RATE modal v3 is an in-app centered opaque card with backdrop, close button, Esc and outside-click/touch dismissal. Ratings persist and Gallery `R x.x` badges remain.

Consolidated telemetry event: `creative_preference_snapshot`.

Trash stays local/reversible; source remains versioned.

## Adaptive batch 026–030

All five new definitions contain `creative_seed` and machine-readable `creative_signature`, and their actual signatures are recorded in `knowledge/cross-domain/creative_draw_space.json`.

### 026 VOID TENSION

`constraint network + Voronoi territories + fracture/fold + spring inertia`

- 18 stress-coupled network nodes;
- edges fracture under stress and repair with scars;
- touch cuts real links and redistributes force;
- territory texture follows nearest/second-nearest nodes and propagated stress;
- 8 controls.

### 027 GLASS TIDE

`wave fronts + SDF glass + threshold/displacement + state-dependent topology`

- four stateful moving lenses;
- asynchronous pressure fronts, no shader `TIME` choreography;
- touch toggles local optical topology and injects a wavefront;
- one full-canvas shader surface under the existing ShaderSurface contract;
- 8 controls.

### 028 LUMEN MAZE

`light transport + graph channels + jam/release + quantization`

- 80×45 state field with deterministic channel topology;
- six gates jam/release asynchronously;
- blocked transport accumulates pressure then bursts;
- touch deposits persistent obstacles the system routes around;
- one texture draw; 9 controls.

### 029 FIBER FELT

`fiber geometry + morphology mask + accumulation/displacement + phase transition`

- 30 constrained fibers, 13 points each;
- coarse local compaction field exchanges state with neighbouring cells;
- pressure and drag compact/advect fibers;
- material transitions from loose strands toward felted state and can relax;
- duotone; 8 controls.

### 030 REACTOR SKIN

`reaction-diffusion + procedural mesh + fracture/threshold`

- 52×30 Gray-Scott-style chemistry;
- chemical gradients become mechanical stress;
- 14×9 membrane mesh fractures and repairs on a slower timescale;
- touch injects reagent and local structural stress;
- no glow; 9 controls.

## Temporal-quality rule

User rejects cheap visible clock loops / sine-bobbing. Read `knowledge/cross-domain/TEMPORAL_MOTION_QUALITY.md`.

Preferred: `time -> state/force/memory/event -> coupled system -> render`.

Rejected by default: `time -> sin/cos -> visible position/scale/alpha/warp`.

For 026+, direct clock trig requires `TEMPORAL_INTENT:`. CI audit remains active. None of 026–030 depends on generic direct-clock trigonometry.

## Adaptive creative draw

Files:

- `knowledge/cross-domain/ADAPTIVE_CREATIVE_DRAW.md`
- `knowledge/cross-domain/creative_draw_space.json`
- `scripts/creative/draw_recipe.py`

Anti-repeat and preference rules remain:

- historical/recent feature penalties;
- minimum recent signature distance;
- representation/operator families must differ;
- forced oscillator penalized;
- explicit REVIEW bias bounded;
- 24% exploration share ignores preference bias.

CI self-tests 180 deterministic draws for diversity collapse.

## Full-canvas / performance contracts

`ShaderSurface` must use `sketches/_shared/full_canvas_surface.gd`; CI rejects fixed 1280×720 surfaces. Dense fields should render as ImageTexture/fullscreen shader rather than thousands of Canvas primitives. Do not recompute expensive neighbourhood/contact work again in `_draw()`.

## Required next host test

1. Launch from canonical PowerShell: no small 1280×720 flash before the workstation appears.
2. Leave workstation fullscreen, close normally, reopen: same fullscreen state/screen.
3. Restore/window the app, move/resize it, wait >1 s, close and reopen: same mode/screen/rect.
4. Confirm RATE modal remains centered/opaque after new top runtime.
5. Confirm Gallery source count is 30 and open 026–030.
6. For each 026–030: watch idle 20–30 s before interaction, then interact and remove hand; judge visual, aliveness, controls and whether consequences remain in system state.
7. Rate 026–030 normally.
8. Close normally and inspect fresh matching `telemetry/runtime`; require `workstation_window_state_restored` plus updated `creative_preference_snapshot` before conclusions.

## Mandatory AI completion

After every material repository change: finish commits, update durable docs/state, resolve final remote HEAD, wait exact-head CI, report exact short SHA + CI, include canonical CI-waiting PowerShell when host validation is relevant, then telemetry-first after user test.

## Non-regressions

Do not stop PROGRAM on navigation, create independent linked timelines, block UI with telemetry Git work, restore failed cross-window texture sampling, fake Spout/NDI, restore Pressure Lattice, burn project metadata into artwork, make glyph contours the default representation, restore a permanent all-tags wall, reintroduce fixed 1280×720 ShaderSurface nodes, restore native transparent RATE popup, use naked global-clock wobble as default aliveness, or restore the visible windowed->fullscreen startup jump.
