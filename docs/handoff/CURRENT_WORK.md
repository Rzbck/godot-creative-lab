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

## Existing sketches

001–010 remain the established earlier body of work. `005_pressure_lattice` visibly remains **REGISTER TYPE**; never restore the rejected Pressure Lattice concept. The rejected generalized contour pass `6c20a094...` across 006–010 must not be restored.

## Host feedback on collision-first batch 011–015

The first collision-first batch improved the technical/creative diversity, but the host test established three important shortcomings:

1. **visual quality is still too weak** — mechanisms are more interesting, but default compositions/palettes are not yet studio-grade;
2. **three exposed parameters are insufficient** for substantial Gallery laboratories;
3. cellular/raster systems still need deeper organic coupling — pixels/cells should exchange state, resources, pressure, phase or memory rather than behave as independent tiles.

Telemetry from the test showed 15 Gallery previews loaded on runtime head `6dd4b307...`; the feedback is therefore primarily creative/systemic, not evidence that the batch failed to load.

These lessons are now versioned in `knowledge/cross-domain/ORGANIC_COUPLING_AND_CONTROLS.md`.

## Durable new creative rules

For a substantial collision-first Gallery lab:

- normally expose **6–9 meaningful independent controls** when the mechanism supports them;
- parameter vocabulary should describe the system itself (`APPETITE`, `SCAR MEMORY`, `REFRACTORY TIME`, `MESH TENSION`, etc.), not generic aliases for more effect;
- at least half the controls should influence future evolution, not only current rendering;
- organic/cellular claims require real local coupling between neighbours or subsystems;
- prefer multiple time scales: fast response + slower repair/memory/transport/fatigue;
- raw research does **not** excuse ugly defaults — coherent palette, composition and frozen-frame quality are required before Gallery promotion;
- interaction should perturb state the system then redistributes.

## New batch 016–020 — organic collision laboratories

Blind draw seed: `202609242031`.

These are new raw Gallery labs, not approved final artworks.

### 016 — PREDATOR VEIN

Path: `sketches/016_predator_vein/`

Mechanism:

`nutrient nodes -> dynamic graph -> neighbour resource diffusion -> hysteresis -> raster field cohesion -> persistent predators -> scars / recovery`

- 30 drifting resource nodes;
- network activation uses hysteresis;
- node energy regrows and diffuses through neighbours;
- coarse field cells also smooth with neighbouring cells;
- touch injects persistent predators rather than a temporary visual mask;
- predators seek rich nodes, consume energy and leave scars;
- 8 parameters: `REGROWTH`, `RESOURCE FLOW`, `APPETITE`, `PREDATOR SPEED`, `NETWORK RANGE`, `HYSTERESIS`, `SCAR MEMORY`, `FIELD COHESION`;
- tags: `ECOSYSTEM`, `NETWORK`, `INTERACTIVE`.

### 017 — EDGE BLOOM

Path: `sketches/017_edge_bloom/`

Mechanism:

`edge-fed cellular tissue -> neighbour excitation -> refractory waves -> mobile spores -> gradient following -> deposit / split`

- 64×36 excitable cell field;
- each cell reads eight neighbours;
- cells enter a refractory period after strong excitation;
- screen edges feed the system continuously;
- spores follow local gradients, deposit activity and can split in rich zones;
- touch seeds a local excitable wave;
- 9 parameters: `CELL COUPLING`, `EXCITATION THRESHOLD`, `REFRACTORY TIME`, `EDGE FEED`, `DECAY`, `SPORE SPEED`, `SPORE SPLIT`, `SPORE DEPOSIT`, `SEED RADIUS`;
- tags: `CELLULAR`, `GROWTH`, `INTERACTIVE`.

### 018 — CURRENT MEMORY

Path: `sketches/018_current_memory/`

Mechanism:

`wave-equation lattice -> delayed field memory -> particle current -> dynamic proximity reconnection -> reciprocal particle injection`

- 52×30 wave membrane with neighbour Laplacian exchange;
- field memory pulls current state toward its recent history;
- 76 particles sample the wave gradient/tangent and can reconnect visually in coherent regions;
- particles inject small impulses back into the membrane;
- asymmetric void shapes the composition;
- pointer movement redirects current and injects wave energy rather than directly moving particles;
- 9 parameters: `WAVE TENSION`, `WAVE DAMPING`, `FLOW GAIN`, `PARTICLE INERTIA`, `RECONNECT RANGE`, `REGIME RATE`, `VOID RADIUS`, `FIELD MEMORY`, `CURRENT SPEED`;
- tags: `FLOW`, `WAVE`, `INTERACTIVE`.

### 019 — SOFT FLOCK

Path: `sketches/019_soft_flock/`

Mechanism:

`boid population -> Verlet constraint membrane -> agent pressure -> link abrasion -> repair -> persistent obstacle`

- two-color composition only;
- 13×8 soft mesh with horizontal/vertical/diagonal constraints;
- 42 flocking agents push against the membrane;
- agent traffic erodes actual link health;
- damaged links repair over time;
- touch creates a temporary obstacle that continues to redirect agents and mesh after release;
- 9 parameters: `MESH TENSION`, `MESH DAMPING`, `FLOCK COHESION`, `FLOCK ALIGNMENT`, `FLOCK SEPARATION`, `AGENT PRESSURE`, `LINK EROSION`, `LINK REPAIR`, `OBSTACLE RADIUS`;
- tags: `PHYSICS`, `FLOCK`, `INTERACTIVE`.

### 020 — ECHO TISSUE

Path: `sketches/020_echo_tissue/`

Mechanism:

`excitable cells -> eight-neighbour coupling -> density morphology -> refractory state -> delayed feedback -> autonomous reseeding`

- 72×40 tissue grid;
- every cell reads eight neighbours;
- local density can merge growth or consume over-dense regions;
- cells carry refractory memory;
- two-stage delayed history can re-trigger regions after visible activity fades;
- autonomous reseeding prevents the work from waiting for input;
- touch seeds activity that then migrates through the tissue;
- 9 parameters: `NEIGHBOUR COUPLING`, `FIRE THRESHOLD`, `EXCITATION`, `TISSUE DECAY`, `REFRACTORY TIME`, `DELAYED FEEDBACK`, `MEMORY DECAY`, `MERGE / CONSUME`, `SEED RADIUS`;
- tags: `TISSUE`, `MEMORY`, `INTERACTIVE`.

All five extend the shared design/runtime contract and include custom live-sync state.

Implementation commit: `e2ff8328532a4eab057c63b8bd1d361bc706ba15`.
Godot 4.7.1 import, main-scene smoke and tracked-file cleanliness all passed on CI #221 for that runtime commit.

## Knowledge priority

For current creative work read:

1. `knowledge/cross-domain/TECHNIQUE_PALETTE.md`
2. `knowledge/cross-domain/RANDOM_COLLISION_ENGINE.md`
3. `knowledge/cross-domain/COLLISION_SOURCE_CATALOG.md`
4. `knowledge/cross-domain/ORGANIC_COUPLING_AND_CONTROLS.md`
5. relevant creative-coding/design atlases
6. `CROSS_DOMAIN_ATLAS.md` / `IDEA_ENGINE.md` when promoting a mechanism into a real artwork.

## Required host test for 016–020

1. Gallery should contain **20 sketches**.
2. Open 016–020 at default values first; evaluate composition/palette before touching controls.
3. Watch each for 20–30 seconds hands-off.
4. Interact once, release, then observe whether state migrates/repairs/propagates.
5. Only then explore the 8–9 controls and check whether they create materially different regimes.
6. Test the strongest mechanisms on PROGRAM/touch.
7. After the test, inspect fresh `telemetry/runtime` before requesting manual logs.

Evaluation is now two-dimensional:

- **mechanism** — does the system genuinely negotiate state internally?
- **art direction** — is the default visual already compelling enough to deserve further development?

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
