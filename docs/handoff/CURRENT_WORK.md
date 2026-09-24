# Current work — DC//LAB

Last refreshed: 2026-09-24.

## Active branch / PR

- branch: `feat/creative-sketches-002-004-20260924`
- draft PR: `#7`
- PR base: `feat/gallery-project-workflow-20260923`
- always resolve current remote HEAD + exact-head CI from GitHub
- never merge/change `main` without explicit user approval

## Stable product areas to preserve

- Gallery real previews, hover animation, automatic groups, tag filters and search.
- Per-sketch parameter persistence.
- PREVIEW / PROGRAM separation.
- Persistent PROGRAM while browsing/editing elsewhere.
- `TAKE LIVE` replacement workflow.
- Physical display selection and PROGRAM touch/mouse forwarding.
- Linked PREVIEW/PROGRAM state synchronization.
- Sanitized asynchronous telemetry on `telemetry/runtime`.
- PROGRAM canvas is artwork-only: no sketch title/index/tags/debug/project chrome unless artistically intentional.

## Existing creative content

- `001_signal_field` — technical/regression reference.
- `002_liquid_type` — elastic typography.
- `003_chroma_lens` — typographic optical system.
- `004_gommage_type` — directional erosion/reconstruction.
- `005_pressure_lattice` — visible artwork **REGISTER TYPE**; original Pressure Lattice is rejected and must not be restored.
- `006_breath_score` — **BREATH SCORE**, pre-contour-overuse version.
- `007_redaction_field` — **REDACTION FIELD**, pre-contour-overuse runtime with canvas chrome suppressed.
- `008_palimpsest` — **PALIMPSEST**, pre-contour-overuse runtime with archive chrome suppressed.
- `009_chorus_drift` — **CHORUS DRIFT**, pre-contour-overuse runtime with explanatory chrome suppressed.
- `010_fault_register` — **FAULT REGISTER**, pre-contour-overuse runtime with label-free grid.

The generalized glyph-contour pass `6c20a094...` was host-rejected because it looked worse, some contours rendered inverted/broken and the series converged around one technique. Do not restore it.

## New collision-first Gallery laboratories — 011–015

These are intentionally **raw mechanisms**, not polished artworks. Their job is to reveal behavior worth art-directing later.

### 011 — SWARM RELAY

Path: `sketches/011_swarm_relay/`

Primary mechanism:

`autonomous agents -> cohesion/separation -> dynamic neighbour graph -> local communication damage/recovery`

- 72 moving agents;
- each agent continuously rebuilds links to nearby neighbours;
- touch repels local agents and increases damage, causing communication links to disappear;
- damage decays, so topology reforms after interaction;
- parameters: `COHESION`, `SEPARATION`, `LINK RANGE`;
- tags: `AGENTS`, `TOPOLOGY`, `INTERACTIVE`.

### 012 — CHEMICAL BLOCKS

Path: `sketches/012_chemical_blocks/`

Primary mechanism:

`coarse raster chemistry -> Gray-Scott reaction-diffusion -> autonomous pattern growth -> touch injects reagent`

- 48×27 two-field reaction-diffusion simulation;
- autonomous feed/kill chemistry continues with no input;
- touch injects B reagent and locally restarts the reaction;
- parameters: `FEED`, `KILL`, `DIFFUSION`;
- tags: `CHEMISTRY`, `DIFFUSION`, `INTERACTIVE`.

### 013 — CUT CELL

Path: `sketches/013_cut_cell/`

Primary mechanism:

`moving sites -> nearest-site territories -> dynamic communication graph -> interaction cuts links -> healing`

- 18 autonomous sites;
- coarse nearest-site field produces moving cellular territories;
- graph uses nearest/second-nearest relationships within a range;
- touch can cut actual graph links around the gesture region;
- severed links heal over time while sites keep moving;
- parameters: `DRIFT`, `HEAL`, `NETWORK RANGE`;
- tags: `NETWORK`, `VORONOI`, `INTERACTIVE`.

### 014 — RIBBON MORPH

Path: `sketches/014_ribbon_morph/`

Primary mechanism:

`binary raster material -> neighbourhood morphology -> regime switching -> raster reconstructed as ribbons`

- 64×36 binary material field;
- autonomous morphology alternates between growth-like and erosion-like regimes;
- touch deposits material;
- dwell flips the material regime rather than directly dragging geometry;
- row structure is reconstructed into long quad ribbons;
- parameters: `MORPH RATE`, `PERSISTENCE`, `RIBBON MASS`;
- tags: `MORPHOLOGY`, `RASTER`, `INTERACTIVE`.

### 015 — PHASE PACK

Path: `sketches/015_phase_pack/`

Primary mechanism:

`packed colliding bodies -> neighbour phase rules -> local phase transitions -> signed-distance-like field`

- 24 moving bodies with radii, collisions and two material phases;
- same/opposite phases affect neighbour forces;
- discrete neighbourhood rules can flip phase autonomously;
- touch changes local phase and injects repulsion;
- coarse field rendering derives from distance to the packed bodies;
- parameters: `MOTION`, `PHASE RATE`, `FIELD`;
- tags: `PHASE`, `PACKING`, `INTERACTIVE`.

All five use the shared design/runtime contract and include custom live-sync state for linked PREVIEW/PROGRAM.

Implementation root commit: `230ef4ff587db604f264e8cf0522fadfcdbeae52`.
Five generated Godot script UIDs were subsequently tracked; resolve the current final HEAD from GitHub rather than trusting this recorded commit.

## Why this batch exists

The user identified that 001–010 varied surface styling more than underlying mechanism. Collision-first work deliberately spreads into different state representations before assigning artistic meaning.

Current rule:

`blind technical collision -> coupled raw prototype -> observe -> interpret -> art-direct -> mutate`

Mandatory references:

- `knowledge/cross-domain/TECHNIQUE_PALETTE.md`
- `knowledge/cross-domain/RANDOM_COLLISION_ENGINE.md`
- `knowledge/cross-domain/COLLISION_SOURCE_CATALOG.md`

Do not prematurely turn 011–015 into five polished poster designs. First identify which mechanisms produce genuinely interesting accidents.

## Validation state

- The initial 011–015 runtime commit successfully passed Godot 4.7.1 import and the main-scene smoke test.
- Its first CI failed only because Godot generated five untracked `.gd.uid` files for the new scripts.
- Those UIDs are now tracked.
- Repository validation of the **final HEAD** must be taken from GitHub CI, never inferred from this file.
- Host visual/tactile state for 011–015: **HOST_NOT_VALIDATED**.

## Required host test for 011–015

Do not start by tuning sliders.

1. Sync the exact final HEAD only after its CI is green.
2. Confirm Gallery now contains **15 sketches** and cards 011–015 render real previews.
3. Open each of 011–015 and watch it for ~15–30 seconds without touching.
4. Then interact once and remove your hand; observe whether the consequence persists/propagates/reorganizes.
5. Specifically test:
   - 011: damage and network reformation;
   - 012: reagent injection and continuing chemistry;
   - 013: cut links and healing;
   - 014: material deposition + dwell regime switch;
   - 015: local phase conversion and later propagation/collisions.
6. Try the most promising one or two on physical PROGRAM/touch.
7. After the test, inspect `telemetry/runtime` before asking the user for logs.

The artistic evaluation question is not “is it finished?” It is: **which mechanism contains an accident worth developing into a real DC//LAB piece?**

## Mandatory AI operational completion

After every material repository change, every AI must automatically:

1. finish intended feature-branch commits;
2. update durable handoff/state docs when state/NEXT/validation changes;
3. resolve the final remote HEAD after all commits;
4. wait for CI on that exact final SHA;
5. report exact short HEAD + CI result;
6. when host validation is relevant, include the canonical `sync + exact-head CI wait + launch Godot` PowerShell from `docs/handoff/OPERATIONS.md` without waiting to be asked;
7. after host testing, inspect telemetry before requesting manual logs.

## Non-regressions

Do not stop PROGRAM on navigation, create independent linked timelines, move the workstation as normal output, block UI with telemetry Git work, resurrect the failed cross-window texture path, add card-covering overlays, fake Spout/NDI, restore Pressure Lattice, reintroduce artwork metadata captions, or make glyph contours the default representation.
