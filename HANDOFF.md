# HANDOFF — DataC0re Creative Lab

Canonical restart point for a new human or AI session.

**Always resolve the current remote branch HEAD and exact-head CI before trusting recorded SHAs.** Repository state is authoritative; chat history is secondary.

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

DC//LAB is a Godot creative-coding workstation with:

- data-driven Gallery discovery from sketch `definition.json`;
- real thumbnails and hover-only animated previews;
- automatic groups, tags and search;
- generated parameter inspector + per-sketch persistence;
- PREVIEW / PROGRAM separation;
- persistent PROGRAM while browsing elsewhere;
- `TAKE LIVE` replacement workflow;
- physical output display selection;
- PROGRAM mouse/touch forwarding;
- linked PREVIEW/PROGRAM live-state synchronization;
- asynchronous sanitized telemetry on `telemetry/runtime`;
- versioned creative/design/cross-domain knowledge.

The normal logical artwork space is `1280×720`.

PROGRAM canvas is artwork-only: never burn sketch title/index/tags/debug/project metadata into the final artwork unless that text is genuinely part of the piece.

## Sketch state

### 001–010

- `001_signal_field` — technical/regression reference.
- `002_liquid_type` — elastic typography.
- `003_chroma_lens` — typographic optical system.
- `004_gommage_type` — directional erosion/reconstruction.
- `005_pressure_lattice` — visible artwork **REGISTER TYPE**; original Pressure Lattice is rejected and must not be restored.
- `006_breath_score` — **BREATH SCORE**.
- `007_redaction_field` — **REDACTION FIELD**.
- `008_palimpsest` — **PALIMPSEST**.
- `009_chorus_drift` — **CHORUS DRIFT**.
- `010_fault_register` — **FAULT REGISTER**.

A generalized contour pass (`6c20a094...`) across 006–010 was host-rejected: some glyphs looked inverted/broken, the five pieces converged technically and the result was worse. The rollback beginning at `3a437fe...` restored the earlier behavior while keeping unwanted captions out of the canvas. Do not restore contour-everywhere.

### 011–015 — collision-first raw laboratories

These are intentionally raw research prototypes, not approved final artworks.

- `011_swarm_relay` — **SWARM RELAY**: autonomous agents + dynamic neighbour topology; touch damages local communication and repels the swarm; links reform as damage decays.
- `012_chemical_blocks` — **CHEMICAL BLOCKS**: coarse Gray-Scott reaction-diffusion; touch injects reagent and chemistry keeps evolving after release.
- `013_cut_cell` — **CUT CELL**: moving nearest-site territories + dynamic graph; touch cuts real graph links, which heal over time.
- `014_ribbon_morph` — **RIBBON MORPH**: binary raster morphology + regime switching + ribbon reconstruction; touch deposits material and dwell changes the regime.
- `015_phase_pack` — **PHASE PACK**: colliding packed bodies + discrete neighbour phase rules + distance-field rendering; touch converts local phase and perturbs motion.

All 011–015 extend the shared design/runtime contract and carry custom live-sync state for PREVIEW/PROGRAM.

Implementation root commit: `230ef4ff...`; five generated script UID files were then tracked. Resolve current HEAD from GitHub rather than relying on that historical implementation SHA.

## Current creative method — collision-first

The user explicitly wants more technical and conceptual diversity before assigning final artistic meaning.

Current exploration pipeline:

`blind technical collision -> coupled raw prototype -> observe -> interpret -> art-direct -> mutate`

Read first for substantial exploration:

1. `knowledge/cross-domain/TECHNIQUE_PALETTE.md`
2. `knowledge/cross-domain/RANDOM_COLLISION_ENGINE.md`
3. `knowledge/cross-domain/COLLISION_SOURCE_CATALOG.md`
4. relevant creative-coding/design atlases
5. `CROSS_DOMAIN_ATLAS.md` / `IDEA_ENGINE.md` when a successful accident deserves an identity pass

No technique is the default house style. Contours, direct type, raster, SDF, fragment shaders, feedback, agents, vector fields, physical systems, CA/reaction-diffusion, geometry, topology and data systems are separate options.

Do not over-art-direct a raw collision before its mechanism proves interesting. Random effect stacking without state coupling is rejected.

## 011–015 validation contract

Repository evidence already observed on the first runtime commit:

- Godot 4.7.1 import passed;
- main-scene smoke test passed;
- first CI cleanliness failed only because five new `.gd.uid` files were generated;
- those UIDs are now tracked.

The exact **final HEAD** validation must always be resolved from GitHub CI after all docs/code commits. Do not use an older green run.

Host state for 011–015: **HOST_NOT_VALIDATED**.

Next host test:

1. confirm Gallery shows 15 sketches and 011–015 cards render;
2. watch each 011–015 hands-off before moving sliders;
3. interact once, then remove input and watch propagation/recovery;
4. test promising mechanisms in PROGRAM/touch;
5. decide which raw mechanisms contain accidents worth an artistic-impact pass;
6. inspect fresh `telemetry/runtime` immediately after the test before requesting manual logs.

## PROGRAM / LIVE OUT architecture

Expected workflow:

1. Open a project in PREVIEW/editor.
2. Send it to PROGRAM / LIVE OUT.
3. Browse Gallery/Settings while PROGRAM keeps running.
4. Open another PREVIEW.
5. `TAKE LIVE` replaces PROGRAM.

Navigation is not transport.

When linked, editor simulation is authoritative and PROGRAM follows synchronized state. When navigating away, PROGRAM detaches and continues from the last synchronized state.

Inspect `res://app/main/main_runtime.tscn` and its actual `extends` chain before touching Gallery/PROGRAM/window/telemetry behavior.

## Telemetry-first debugging

After any host runtime test:

1. inspect branch `telemetry/runtime`;
2. read `latest.jsonl` and relevant session data;
3. verify telemetry corresponds to the tested HEAD/session;
4. only ask for manual logs/screenshots if telemetry genuinely lacks the evidence.

## Mandatory AI completion protocol

The user must not need to remind the AI to update continuity, wait for CI or provide the launcher.

After every material repository change, before final response:

1. finish intended feature-branch commits;
2. update `CURRENT_WORK.md`, this handoff, `project_state.json`, `NEXT_AI_PROMPT.md` and `OPERATIONS.md` where durable state/workflow changed;
3. resolve the final remote branch HEAD **after all code + docs commits**;
4. wait for and inspect CI for that exact SHA;
5. report exact short HEAD + CI result;
6. when host validation is relevant, automatically include the canonical PowerShell from `OPERATIONS.md` that syncs, waits for exact-head CI success and only then launches Godot;
7. after the user tests, inspect telemetry first.

## Rejected regressions

Do not casually reintroduce:

- root-window fullscreen as normal PROGRAM output;
- the failed cross-window texture sampling path;
- synchronous telemetry Git/network work on Godot UI thread;
- independent linked PREVIEW/PROGRAM simulations;
- Gallery overlays that cover cards;
- fake Spout/NDI;
- Pressure Lattice;
- project metadata inside artwork;
- glyph contours as the default creative representation.

See `docs/handoff/CURRENT_WORK.md` for detailed current work, `docs/handoff/OPERATIONS.md` for the canonical exact-CI PowerShell, and `docs/handoff/NEXT_AI_PROMPT.md` for fresh-session bootstrap.
