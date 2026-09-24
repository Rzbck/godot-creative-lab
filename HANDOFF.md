# HANDOFF — DataC0re Creative Lab

Canonical restart point for a new human or AI session.

**Always resolve current GitHub branch HEAD and CI before trusting recorded SHAs.** The repository is the source of continuity; chat history is secondary.

Last material refresh: **2026-09-24**.

## Repository / active work

- GitHub: `Rzbck/godot-creative-lab`
- local workstation: `E:\_Project\GodotCreativeLab`
- Godot GUI: `C:\Godot\Godot_v4.7.1-stable_win64.exe`
- Godot console: `C:\Godot\Godot_v4.7.1-stable_win64_console.exe`
- engine: Godot `4.7.1.stable.official.a13da4feb`
- validated host renderer: Vulkan / Forward+ / NVIDIA GeForce RTX 5080
- active branch: `feat/creative-sketches-002-004-20260924`
- draft PR: `#7`, base `feat/gallery-project-workflow-20260923`
- never merge/change `main` without explicit user approval.

## Product state

DC//LAB is a functioning Godot creative-coding workstation with:

- Gallery discovery from sketch `definition.json`;
- real thumbnails and hover-only animated previews;
- automatic groups, tag filters and search;
- generated parameter inspector + per-sketch persistence;
- PREVIEW / PROGRAM separation;
- persistent PROGRAM output while workstation navigation remains usable;
- `TAKE LIVE` replacement workflow;
- physical output display selection;
- mouse/touch forwarding from PROGRAM;
- linked PREVIEW/PROGRAM live-state synchronization;
- asynchronous sanitized telemetry on `telemetry/runtime`;
- versioned creative-coding, design, typography, cross-domain and living-system knowledge.

The logical artwork space is `1280×720` unless a concept explicitly requires another representation. PROGRAM canvas is artwork-only.

## Current sketches

### 001 — SIGNAL FIELD

Technical/regression reference for the sketch/runtime contract. Do not force it into the artistic direction.

### 002 — LIQUID TYPE

Elastic typography with gesture-velocity memory influencing spacing, phase, tangential response, smear and chromatic direction.

### 003 — CHROMA LENS

Typographic optical system with controlled safe margins, stable hierarchy, quantized lens states and editorial structure.

### 004 — GOMMAGE TYPE

Erase/rebuild typography with directional erosion/dust/gesture memory and reconstruction.

### 005 — REGISTER TYPE

Internal folder remains `sketches/005_pressure_lattice/` for compatibility. Original **PRESSURE LATTICE** visual concept was rejected; do not restore it.

Visible artwork: **REGISTER TYPE**. Editorial hierarchy + local typographic compression + print misregistration + damped recovery.

### 006 — BREATH SCORE

Current structural/autonomous pass:

- no project title/index metadata inside artwork;
- full-canvas atmospheric field;
- autonomous breathing at rest;
- real glyph contours are sampled and internally expanded/rippled;
- touch injects local pressure/gesture direction into contour deformation rather than turning an effect on;
- behavioral parameters: breath tempo, autonomy, elasticity, touch pressure, counter tension, ink density.

### 007 — REDACTION FIELD

Current structural/autonomous pass:

- no `DOCUMENT / REVISION...` caption, number or poster-card frame;
- per-character visibility state;
- autonomous institutional scan + leak behavior continuously renegotiates censorship;
- glyph contours collapse toward their own centerline as censorship increases, making the letter itself become the redaction material;
- touch edits local characters and dwell creates memory;
- behavior remains active without touch.

### 008 — PALIMPSEST

Current structural/autonomous pass:

- no archive caption/card frame;
- full-canvas sediment field;
- older/deeper textual strata surface autonomously;
- gesture speed chooses excavation depth; dwell increases persistence;
- current/old/deep glyph layers use contour deformation/drift;
- history rewrites itself after the viewer stops touching.

### 009 — CHORUS DRIFT

Current structural/autonomous pass:

- no project caption/frame or explanatory central label;
- chorus rows are a coupled oscillator population with natural frequencies, phase coupling, unrest, offsets and velocities;
- voices can emerge autonomously through synchronization/phase state;
- touch perturbs one row and pushes neighbouring rows rather than simply isolating a rigid text sprite;
- high-energy voices use contour-level vibration/deformation.

### 010 — FAULT REGISTER

Current structural/autonomous pass:

- no `STRUCTURE / STRESS / RESIDUE`, number or inset poster frame;
- full-canvas living grid;
- small faults seed autonomously and decay;
- viewer-created faults leave scars;
- fault displacement is evaluated per vector contour point across a fault plane, so a **single glyph can fracture internally** instead of moving as a rigid unit;
- local structural fault energy controls print registration separation.

## Shared structural-type infrastructure

New shared helper:

`sketches/_shared/glyph_contour_tools.gd`

It uses Godot's native `TextServer.font_get_glyph_contours()` to retrieve real glyph outlines, samples on-curve / conic / cubic segments, and caches polylines.

`sketches/_shared/design_sketch_base.gd` now exposes design-space helpers for:

- retrieving sampled glyph contours;
- transforming contour points;
- drawing contour polylines;
- computing outline bounds.

This exists because moving/scaling a whole glyph is not enough when an artwork claims to alter stems, bowls, counters, apertures, fractures or other internal structure.

## Creative-quality rules — durable

These rules were established from direct host visual feedback and should be treated as project standards.

### 1. Full canvas = artwork

Do not burn into final PROGRAM art:

- sketch title;
- sketch number/index;
- category/tag;
- project metadata;
- debug text;
- fake museum/editorial labels that merely explain the sketch.

Those belong to Gallery/editor UI. Text inside the artwork is valid when it is actually the artistic carrier.

Do not automatically draw an inset poster/card frame inside the 1280×720 canvas. A visible frame must be conceptually necessary.

### 2. Live before touch

A realtime artwork should normally exhibit meaningful autonomous behavior for at least ~30 seconds without interaction.

Reject the default pattern:

`static poster -> click = effect on -> release = effect off`

Prefer an autonomous system with internal state that the viewer perturbs.

### 3. Interaction changes state

Touch should feed, wound, seed, inhibit, isolate, redirect, synchronize, desynchronize, change constraints or otherwise perturb internal state.

Consequences should be able to propagate, persist, migrate, decay, repair or change later behavior when appropriate.

A radial cursor effect is not the default interaction model.

### 4. Representation depth must match the artistic claim

If the concept is about whole-word layout, glyph transforms may be enough.

If the concept is about internal letter structure, use vector contours, sampled points, SDF/MSDF or another representation that exposes the actual anatomy.

Define at least one invariant where possible: baseline, counter visibility, cap height, width, area, anchor stem, reading order, etc.

### 5. Parameters bias behavior

Prefer controls such as autonomy, cohesion, stress, fatigue, repair, memory, permeability, coupling, mutation or structural tension.

Do not depend on a panel of generic `speed / distortion / noise / effect amount` sliders to make a weak default look interesting.

### 6. Multiple time scales

When suitable, combine fast interaction response, medium redistribution/coupling and slow memory/fatigue/repair/regime change.

## Knowledge system

Use all three knowledge roots:

- `knowledge/creative-coding/`
- `knowledge/design/`
- `knowledge/cross-domain/`

Mandatory relevant bricks now include:

- `knowledge/design/TYPOGRAPHY_ATLAS.md`
- `knowledge/design/STRUCTURAL_TYPOGRAPHY.md`
- `knowledge/design/GRAPHIC_DESIGN_ATLAS.md`
- `knowledge/design/REALTIME_DESIGN_BRIDGE.md`
- `knowledge/design/DESIGN_REVIEW_CHECKLIST.md`
- `knowledge/cross-domain/CROSS_DOMAIN_ATLAS.md`
- `knowledge/cross-domain/IDEA_ENGINE.md`
- `knowledge/cross-domain/LIVING_SYSTEMS.md`

The design checklist now includes:

- frozen-frame test;
- 30-second no-input test;
- one-gesture-then-hands-off test;
- structural typography test when relevant;
- full-canvas/UI separation test.

## PROGRAM / LIVE OUT architecture — preserve

PREVIEW/EDITOR and PROGRAM are separate responsibilities.

Expected workflow:

1. Open project in editor.
2. Send it to PROGRAM / LIVE OUT.
3. Return to Gallery/Settings; PROGRAM keeps running.
4. Open another PREVIEW.
5. `TAKE LIVE` replaces PROGRAM.

Navigation is not transport.

When linked, editor simulation is authoritative and PROGRAM follows synchronized state. When navigating away, PROGRAM detaches and continues from the last synchronized state.

Inspect `res://app/main/main_runtime.tscn` and its actual script `extends` chain before changing Gallery/PROGRAM/window/telemetry behavior.

## Input / touch

The shared physical PROGRAM touch path is HOST_VALIDATED. Events map to the same 1280×720 logical space used by PREVIEW.

New sketch-specific behavior still needs host validation.

## Telemetry

Local: `res://.telemetry_runtime/`.

Online sanitized branch:

- `telemetry/runtime`
- `latest.jsonl`
- `sessions/`

Publication remains asynchronous/queued.

Important current note: while reviewing the user's latest visual feedback, the remote telemetry still reported runtime Git head `0e9a002...` and only five Gallery previews. It was stale for the latest 006–010 test. Do not claim it diagnosed that visual test. After the next exact-head host run, inspect telemetry again before asking for logs.

## Validation state

Structural/autonomous implementation commit:

`6c20a0948a512809ad16014c7fef67e0ffaf4ae9`

CI run #196 / `36032793642` passed:

- repository policy;
- Godot 4.7.1 setup/import;
- main-scene smoke test;
- tracked-file cleanliness.

This implementation is `REPO_VALIDATED` but **not yet HOST_VALIDATED** visually/tactilely.

Always resolve newest HEAD + CI after documentation commits.

## Next host test

Do not tune sliders first.

For 006–010:

1. watch each untouched for about 30 seconds;
2. verify no title/index/project metadata appears in artwork;
3. verify full-canvas composition rather than a default poster-card frame;
4. judge whether autonomous motion is behavior or merely decoration;
5. make one slow gesture, stop touching, watch what persists/propagates/repairs;
6. repeat with one fast or long gesture;
7. inspect internal letter deformation where expected;
8. test selected pieces in PROGRAM/touch;
9. then inspect fresh telemetry + visual feedback before further art direction.

## Rejected regressions

Do not reintroduce:

- Pressure Lattice visual concept;
- project metadata captions inside artworks;
- click-only effect systems as the default creative pattern;
- rigid whole-glyph transforms for concepts claiming structural typography;
- workstation root-window fullscreen as normal PROGRAM path;
- failed cross-window SubViewport sampling path;
- synchronous telemetry Git work on UI thread;
- independent linked PREVIEW/PROGRAM timelines;
- Gallery overlays covering previews;
- fake Spout/NDI.

## Communication / operations

- concise French preferred;
- user should not have to write code manually;
- work directly on active feature branch;
- never merge `main` without explicit approval;
- after code changes verify exact-head CI;
- when host validation is needed provide one compact PowerShell `& { ... }` block from `docs/handoff/OPERATIONS.md`;
- inspect online telemetry before asking for logs.

For a fresh session, use `docs/handoff/NEXT_AI_PROMPT.md`.
