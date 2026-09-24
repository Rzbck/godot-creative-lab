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
- `005_pressure_lattice` — internal path retained, but visible artwork is now **REGISTER TYPE**. The original Pressure Lattice concept was rejected and must not be restored.

### 005 REGISTER TYPE design contract

- stable typographic poster at rest;
- explicit safe area and six-column editorial structure;
- asymmetric `FORM / PRESS / TRACE` hierarchy;
- limited print palette;
- typography is the primary carrier;
- press selects the actual touched row and locally compresses it;
- drag velocity controls registration direction/energy;
- release returns via damped recovery;
- shader supplies paper/grain/grid/halftone registration support rather than becoming the artwork itself;
- custom row energy/anchor/direction remain synchronized between PREVIEW and PROGRAM.

Gallery taxonomy for 002–005 is intentionally small and semantic: primary `TYPOGRAPHY`, one meaningful family tag (`ELASTIC`, `OPTICAL`, `EROSION`, `PRINT`), plus `INTERACTIVE`. Avoid category noise such as `TYPE`, `RGB`, `SHADER`, `LIVE`.

## Knowledge system

Before substantial creative work use:

- `knowledge/creative-coding/`
- `knowledge/design/`
- `knowledge/cross-domain/`

Specifically apply `DESIGN_REVIEW_CHECKLIST.md`, `CROSS_DOMAIN_ATLAS.md` and `IDEA_ENGINE.md`: frozen-frame composition first, real representation bridge, explicit identity invariants, deliberate mutation, causal interaction, designed recovery/idle state, then implementation.

## Validation state / next test

The replacement 005 and taxonomy cleanup have passed CI on their implementation head; resolve the newest exact HEAD after documentation commits before reporting final repository validation.

Next host test:

1. inspect Gallery taxonomy and thumbnail;
2. open REGISTER TYPE in PREVIEW;
3. test press, slow drag, fast drag, release and edges on each of the three typographic rows;
4. test `TYPE SCALE`, `TRACKING`, `PRESSURE`, `REGISTRATION`, `RECOVERY`, `PRINT GRAIN`, `GRID`, `INK PALETTE`;
5. `TAKE LIVE` and repeat on the physical PROGRAM touchscreen;
6. after the test, inspect `telemetry/runtime` before requesting manual logs.

## Non-regressions

Do not stop PROGRAM on navigation, create independent linked timelines, move the workstation as the normal output mechanism, block the UI with telemetry Git work, resurrect the failed cross-window texture path, add card-covering overlays, or fake Spout/NDI.
