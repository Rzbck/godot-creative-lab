# Current work — DC//LAB

Last refreshed: 2026-09-24.

## Active branch / PR

- branch: `feat/creative-sketches-002-004-20260924`
- draft PR: `#7`
- PR base: `feat/gallery-project-workflow-20260923`
- resolve current HEAD + CI from GitHub at session start
- never merge `main` without explicit user approval

## Stable product areas to preserve

- Gallery real previews, hover animation, automatic groups, tag filters and search.
- Per-sketch parameter persistence.
- PREVIEW / PROGRAM separation.
- Persistent PROGRAM while browsing/editing elsewhere.
- `TAKE LIVE` replacement workflow.
- Physical display selection and PROGRAM touch/mouse forwarding.
- Linked PREVIEW/PROGRAM state synchronization.
- Sanitized asynchronous telemetry on `telemetry/runtime`.

## Current creative content

- `001_signal_field` — technical/regression reference.
- `002_liquid_type` — typography; gesture velocity affects spacing, phase, tangency, smear and chromatic direction.
- `003_chroma_lens` — typography; safe margins + stable hierarchy + quantized optical states.
- `004_gommage_type` — typography; directional erosion/dust/gesture memory and reconstruction.
- `005_pressure_lattice` — internal path retained, visible artwork **REGISTER TYPE**. Original Pressure Lattice visual concept is rejected and must not be restored.
- `006_breath_score` — **BREATH SCORE**, now autonomous. The composition breathes without input; real glyph contours expand, ripple and respond locally to touch pressure/gesture direction.
- `007_redaction_field` — **REDACTION FIELD**, now autonomous/per-character. An institutional scan continuously renegotiates visibility; contour geometry collapses toward its own centerline so letters become their own censorship material. Touch locally reveals/redacts and dwell creates memory.
- `008_palimpsest` — **PALIMPSEST**, now autonomous. Sediment and old textual strata surface without input; slow/fast gestures excavate different depths. Current/old/deep glyph layers use contour deformation and persistence.
- `009_chorus_drift` — **CHORUS DRIFT**, now a coupled oscillator population rather than a static crowd waiting for touch. Rows synchronize/desynchronize and some voices emerge autonomously; interaction perturbs one voice and pushes neighbours. High-energy voices deform at contour level.
- `010_fault_register` — **FAULT REGISTER**, now autonomous and structural. Low-energy faults seed themselves; user faults leave scars. Fault displacement is evaluated per contour point, so one glyph can fracture internally across a fault plane rather than translate as one block.

Gallery taxonomy remains small/semantic. Project metadata belongs to Gallery/editor UI, never inside the artwork.

## New shared creative infrastructure

`sketches/_shared/glyph_contour_tools.gd` provides cached Godot-native glyph outline extraction/sampling through `TextServer.font_get_glyph_contours()`.

`design_sketch_base.gd` now exposes helpers to:

- get glyph contours in the shared 1280×720 design coordinates;
- map/deform sampled contour points;
- draw vector contours;
- compute outline bounds.

This is the first shared brick for real structural typography. When an artwork claims to bend/fracture/open a letter internally, prefer contour/SDF/anatomy-depth representations over whole-glyph transforms.

## Creative-quality rules established from host feedback

Treat these as durable rules:

1. **The full PROGRAM canvas is the artwork.** Do not burn sketch title, number, category, debug/project metadata or fake curatorial captions into it. A visible inset frame is only justified when framing is the actual concept.
2. **The work should normally live before touch.** Default/idle behavior must evolve meaningfully without clicks or slider rescue.
3. **Interaction perturbs a system; it should not merely toggle an effect.** Prefer injection of energy/state, damage, selection, coupling changes or boundary changes whose consequences can propagate/persist/repair.
4. **Typographic representation must match the artistic claim.** Structural deformation requires contour/SDF/anatomy access, not just moving a glyph origin.
5. **Parameters bias behavior rather than rescuing visuals.** Prefer autonomy, cohesion, fatigue, repair, memory, pressure, permeability, mutation, structural tension, etc.
6. **Use multiple time scales when appropriate.** Fast response + medium redistribution + slow memory/repair produce deeper behavior than one looping oscillator.

## Knowledge system

Before substantial creative work use:

- `knowledge/creative-coding/`
- `knowledge/design/`
- `knowledge/cross-domain/`

New mandatory bricks for relevant work:

- `knowledge/design/STRUCTURAL_TYPOGRAPHY.md`
- `knowledge/cross-domain/LIVING_SYSTEMS.md`

Also apply:

- `knowledge/design/DESIGN_REVIEW_CHECKLIST.md`
- `knowledge/cross-domain/CROSS_DOMAIN_ATLAS.md`
- `knowledge/cross-domain/IDEA_ENGINE.md`

The checklist now contains a 30-second no-input acceptance test and a one-gesture-then-hands-off test.

## Validation / telemetry state

Structural/autonomous implementation commit: `6c20a0948a512809ad16014c7fef67e0ffaf4ae9`.
CI #196 (`36032793642`) passed repository policy, Godot 4.7.1 headless import, main-scene smoke and tracked-file cleanliness.

The online telemetry visible during the user's previous visual review was stale: it reported runtime Git head `0e9a002...` and five previews, so it did **not** contain evidence for the latest 006–010 test. Do not pretend otherwise. After the next host run, inspect `telemetry/runtime` again before requesting logs.

The structural/autonomous pass is `REPO_VALIDATED` but remains `HOST_NOT_VALIDATED` until the user runs this exact version.

## Next host test

Do **not** start by tuning sliders.

1. sync/run the newest exact HEAD;
2. inspect 006–010 with hands off for ~30 seconds each;
3. verify no title/index/project metadata is drawn into artwork and composition uses the full canvas;
4. observe whether autonomous behavior has character rather than trivial ambient motion;
5. make one slow gesture, stop touching and watch the consequence;
6. make one fast/long gesture and compare memory/propagation/recovery;
7. inspect whether letter contours actually bend/collapse/fracture internally where intended;
8. test one or two pieces in PROGRAM/touch;
9. then inspect fresh telemetry plus the user's visual feedback before the next art-direction pass.

## Non-regressions

Do not stop PROGRAM on navigation, create independent linked timelines, move the workstation as the normal output mechanism, block the UI with telemetry Git work, resurrect the failed cross-window texture path, add card-covering overlays, fake Spout/NDI, restore Pressure Lattice, or reintroduce artwork metadata captions.
