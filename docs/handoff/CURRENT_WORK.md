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
- `006_breath_score` — **BREATH SCORE**. Press = inhale, hold = accumulated tension, release = damped exhale; interaction selects the touched typographic line and changes spacing/temporal rhythm rather than applying a generic pointer filter.
- `007_redaction_field` — **REDACTION FIELD**. Drag right reveals, drag left redacts, long hold preserves the editorial decision, idle slowly renegotiates visibility around the statement `EVERY EDIT / CHANGES / THE STORY`.
- `008_palimpsest` — **PALIMPSEST**. Slow scratching exposes an older textual layer, fast gestures tear into a deeper layer, holding preserves traces, idle rewrites the present over the archive.
- `009_chorus_drift` — **CHORUS DRIFT**. Repeated `I AM HERE` voices form a crowd; touch isolates one row, holding gives it presence, horizontal drag displaces it with echoes, release reabsorbs it into the chorus.
- `010_fault_register` — **FAULT REGISTER**. A strict editorial grid carries `ORDER / IS A TEMPORARY / AGREEMENT`; press anchors a fault, drag shears grid+type, hold deepens the break, release leaves slowly decaying registration scars.

Gallery taxonomy should remain small and semantic: primary `TYPOGRAPHY`, one meaningful family tag (`ELASTIC`, `OPTICAL`, `EROSION`, `PRINT`, `RHYTHM`, `REDACTION`, `MEMORY`, `CHORUS`, `FRACTURE`), plus `INTERACTIVE`.

## Creative direction / knowledge system

Before substantial creative work use:

- `knowledge/creative-coding/`
- `knowledge/design/`
- `knowledge/cross-domain/`

Specifically apply `DESIGN_REVIEW_CHECKLIST.md`, `CROSS_DOMAIN_ATLAS.md` and `IDEA_ENGINE.md`: frozen-frame composition first, genuine representation bridge, explicit identity invariants, deliberate mutation, causal interaction, designed recovery/idle state, then implementation.

The user explicitly considers the current creative vocabulary still too light compared with studio-grade interactive/generative work. The immediate purpose of sketches 006–010 is to create enough varied material for a **post-test creative audit**. After the host test, do not merely tune parameters: analyze the recurring visual/conceptual limitations, identify missing research bricks (interaction dramaturgy, semantic systems, spatial choreography, type systems, richer simulation/material models, multi-stage state machines, narrative/time structures, etc.), then expand `knowledge/` accordingly before the next major art direction.

## Validation state / next test

Implementation commit `6fc8e85` added sketches 006–010. CI run `36031022484` / #193 completed successfully:

- repository policy passed;
- Godot 4.7.1 setup/import passed;
- main-scene smoke test passed;
- tracked-file cleanliness passed.

Resolve the newest exact HEAD after documentation commits before reporting final repository validation.

Next host test:

1. inspect Gallery cards/taxonomy for 006–010;
2. test each sketch in PREVIEW through its full press / hold / drag / release / idle grammar;
3. test edges and extreme parameter values;
4. `TAKE LIVE` and repeat on the physical PROGRAM touchscreen;
5. after the test, inspect `telemetry/runtime` before requesting manual logs;
6. perform the planned creative-library gap analysis from the actual visual results.

## Non-regressions

Do not stop PROGRAM on navigation, create independent linked timelines, move the workstation as the normal output mechanism, block the UI with telemetry Git work, resurrect the failed cross-window texture path, add card-covering overlays, or fake Spout/NDI.
