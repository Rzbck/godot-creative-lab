# HANDOFF — DataC0re Creative Lab

Canonical restart point for a new human or AI session.

**Always resolve current GitHub branch HEAD and CI before trusting recorded SHAs.** Repository state is authoritative; chat history is secondary.

Last material refresh: **2026-09-24**.

## Repository / active work

- GitHub: `Rzbck/godot-creative-lab`
- local workstation: `E:\_Project\GodotCreativeLab`
- Godot GUI: `C:\Godot\Godot_v4.7.1-stable_win64.exe`
- Godot console: `C:\Godot\Godot_v4.7.1-stable_win64_console.exe`
- active branch: `feat/creative-sketches-002-004-20260924`
- draft PR: `#7`
- PR base: `feat/gallery-project-workflow-20260923`
- never merge/change `main` without explicit user approval

## Product state to preserve

DC//LAB is a working Godot creative-coding workstation with:

- data-driven Gallery discovery from sketch `definition.json` files;
- real rendered thumbnails and hover-only animated previews;
- groups, tags and search;
- generated parameter inspector and per-sketch persistence;
- PREVIEW / PROGRAM separation;
- persistent PROGRAM while browsing elsewhere;
- `TAKE LIVE` replacement workflow;
- physical display selection;
- PROGRAM mouse/touch forwarding;
- linked PREVIEW/PROGRAM state synchronization;
- asynchronous sanitized telemetry on `telemetry/runtime`;
- versioned creative/design/cross-domain knowledge.

The logical design space is normally `1280×720`.

## Artwork / interface boundary

PROGRAM canvas is artwork-only.

Do not burn into the artwork:

- sketch title;
- sketch index/number;
- tags/category;
- debug metadata;
- project metadata;
- explanatory pseudo-curatorial captions that belong to the editor/Gallery.

Text is valid when it is genuinely part of the artwork.

## Current sketches

- `001_signal_field` — technical/regression reference.
- `002_liquid_type` — elastic typography with gesture-velocity memory.
- `003_chroma_lens` — typographic optical system with safe margins and quantized hierarchy.
- `004_gommage_type` — directional erosion/dust memory and reconstruction.
- `005_pressure_lattice` — internal path retained; visible artwork is **REGISTER TYPE**. Original **PRESSURE LATTICE** visual concept was rejected and must not be restored.
- `006_breath_score` — **BREATH SCORE**.
- `007_redaction_field` — **REDACTION FIELD**.
- `008_palimpsest` — **PALIMPSEST**.
- `009_chorus_drift` — **CHORUS DRIFT**.
- `010_fault_register` — **FAULT REGISTER**.

A later pass (`6c20a094...`) generalized glyph-contour deformation across 006–010. It was host-rejected because it looked worse, some glyphs rendered inverted/broken, and the five pieces converged technically/aesthetically. The rollback beginning at `3a437fe...` restores the earlier behavior while keeping unwanted presentation captions out of the canvas. Do not restore the contour-everywhere pass.

## Current creative direction — collision-first research

The current problem is not lack of effects; 001–010 reuse too many of the same underlying mechanisms: 2D typography, direct drawing, pointer/drag, local deformation, springs/oscillation and simple recovery.

The next exploration phase deliberately prioritizes **collision-first** research:

`blind random technical draw -> coupled raw prototype -> observe -> interpret -> art-direct -> mutate`

Mandatory creative research files:

1. `knowledge/cross-domain/TECHNIQUE_PALETTE.md`
2. `knowledge/cross-domain/RANDOM_COLLISION_ENGINE.md`
3. `knowledge/cross-domain/COLLISION_SOURCE_CATALOG.md`
4. relevant creative-coding/design atlases
5. `CROSS_DOMAIN_ATLAS.md` / `IDEA_ENGINE.md` when turning a successful accident into an artwork.

Current blind research seeds A–E are recorded in `docs/handoff/CURRENT_WORK.md`. They deliberately spread across particles/instancing, reaction-diffusion/advection, Voronoi/topology, raster/mesh/ribbons and raymarched SDF/cellular systems.

Do not assign polished titles/messages/DA before the raw mechanism shows interesting behavior. Random stacking without state coupling is technical soup and should be rejected.

## Technique-selection rule

No technique is the default house style.

Available families include direct/variable typography, raster/masks, SDF/MSDF, fragment shaders, temporal feedback, particles/agents, vector fields, physical constraints, cellular/reaction-diffusion, procedural geometry/meshes, graphs/topology, data/semantic systems and external/audio/touch drivers.

Structural typography and glyph contours remain optional specialist tools only.

## PROGRAM / LIVE OUT architecture

Expected workflow:

1. Open project in editor/PREVIEW.
2. Send to PROGRAM / LIVE OUT.
3. Browse elsewhere while PROGRAM keeps running.
4. Open another project in PREVIEW.
5. `TAKE LIVE` replaces PROGRAM.

Navigation is not transport.

When linked, editor simulation is authoritative and PROGRAM follows synchronized state. When navigating away, PROGRAM detaches and continues from its last synchronized state.

Inspect `res://app/main/main_runtime.tscn` and the actual `extends` chain before touching Gallery/PROGRAM/window/telemetry behavior.

## Touch / telemetry

PROGRAM mouse/touch mapping into the shared design space is established infrastructure.

After any host runtime test:

1. inspect branch `telemetry/runtime` first;
2. read `latest.jsonl` and relevant session data;
3. do not ask the user for copied logs until telemetry has been checked.

If telemetry does not correspond to the tested HEAD/session, say so rather than inferring results.

## Mandatory AI completion protocol

The user should never need to remind the AI to update GitHub continuity, wait for CI or provide the test launcher.

After every material repository change, before the final response, every AI must automatically:

1. finish all intended commits on the active branch;
2. update `docs/handoff/CURRENT_WORK.md` when durable state/NEXT/validation/rejections changed;
3. update this `HANDOFF.md` when a future session would otherwise reconstruct stale state;
4. update `docs/handoff/project_state.json` when machine-readable state/constraints/knowledge pointers changed;
5. update `docs/handoff/NEXT_AI_PROMPT.md` when startup rules, creative method or immediate next task changed;
6. update `docs/handoff/OPERATIONS.md` whenever the canonical test/sync/launch workflow changes;
7. resolve the final remote branch HEAD after all documentation commits;
8. wait for and inspect CI for that exact final SHA;
9. report exact short HEAD + CI conclusion;
10. when host validation is relevant, automatically include the canonical PowerShell from `OPERATIONS.md`, which syncs the branch, waits for CI success for the exact SHA, and only then launches Godot;
11. after the user tests, inspect telemetry before requesting manual logs/screenshots that telemetry can answer.

This completion protocol is mandatory repository hygiene, not optional cleanup.

## CI / validation

Workflow: `.github/workflows/ci.yml`

Required gates for runtime/code changes:

- repository policy;
- Godot 4.7.1 setup/version;
- headless import;
- main-scene smoke test;
- tracked-file cleanliness.

Never use an older green CI run as validation for a newer HEAD.

## Rejected regressions

Do not casually reintroduce:

- root-window fullscreen as the normal output mechanism;
- the previously failed secondary-window texture sampling path;
- synchronous telemetry Git/network work on the UI thread;
- independent linked PREVIEW and PROGRAM simulations;
- Gallery overlays that cover preview cards;
- fake Spout/NDI support;
- Pressure Lattice;
- project metadata burned into artwork;
- glyph contours as the default creative solution.

## Immediate next step

Build raw experimental prototypes from several collision seeds with minimal art direction. The purpose is to discover genuinely different mechanisms first. Only successful accidents receive an artistic-impact pass.

See `docs/handoff/CURRENT_WORK.md` for the newest detailed state, `docs/handoff/OPERATIONS.md` for the canonical CI-waiting PowerShell, and `docs/handoff/NEXT_AI_PROMPT.md` for fresh-session bootstrap.