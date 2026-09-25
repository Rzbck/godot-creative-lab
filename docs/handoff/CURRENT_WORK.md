# Current work — DC//LAB

Last refreshed: 2026-09-25.

## Active branch / PR

- branch: `feat/creative-sketches-002-004-20260924`
- draft PR: `#7`
- PR base: `feat/gallery-project-workflow-20260923`
- always resolve current remote HEAD + exact-head CI from GitHub
- never merge/change `main` without explicit user approval

## Stable product areas to preserve

- Gallery real previews, hover animation, automatic groups/tags/search.
- Per-sketch parameter persistence.
- PREVIEW / PROGRAM separation and persistent PROGRAM while navigating.
- `TAKE LIVE`, physical display selection and PROGRAM touch/mouse forwarding.
- Linked PREVIEW/PROGRAM state synchronization.
- Async sanitized telemetry on `telemetry/runtime`.
- logical artwork canvas `1280×720`, artwork-only: no title/index/tag/debug chrome unless artistically intentional.

## Historical constraints

001–010 remain the earlier body of work. `005_pressure_lattice` visibly remains **REGISTER TYPE**; never restore rejected Pressure Lattice. The generalized glyph-contour pass `6c20a094...` was host-rejected and must not be restored as a default representation.

011–015 established collision-first diversity but were host-judged visually weak, under-parameterized (3 controls) and insufficiently organic.

016–020 improved substantially: 8–9 controls, stronger local coupling and more autonomous behavior. Host feedback on 2026-09-25: **clearly better and starting to become interesting**, but still missing real-world material/physical richness and some sketches appeared to fall below the user's very high smooth FPS baseline.

## Telemetry status for the latest host feedback

Telemetry-first check was performed before changing runtime.

Remote `telemetry/runtime` is stale for the 016–020 host test:

- latest telemetry commit: `82114646068521140f1727b7d323803f7de51e58`;
- latest published session still reports runtime head `6dd4b307...` and 15 Gallery previews (011–015 era);
- therefore **do not attribute exact FPS numbers to individual 016–020 sketches from telemetry**.

The user nevertheless observed some sketches dropping below roughly 330 FPS on their host. Code audit found clear structural hotspots independent of missing telemetry:

- 017 could draw roughly 2304 CanvasItem cell primitives every render frame;
- 020 could draw roughly 2880 cell primitives and recomputed neighbour statistics again during `_draw()`.

Corrections now implemented:

- 017 dense field -> low-resolution `ImageTexture` refreshed only on simulation steps + one texture draw; sparse spores remain geometry;
- 020 dense field -> low-resolution `ImageTexture`, neighbour density cached during simulation, no second neighbour scan during draw;
- performance rules are versioned in `knowledge/cross-domain/REALTIME_PERFORMANCE_BUDGET.md`.

Fresh host telemetry is required after the next test for exact per-sketch performance attribution.

## New knowledge — physical / chemical systems

Added `knowledge/cross-domain/PHYSICAL_CHEMICAL_SYSTEMS_ATLAS.md`.

New real-world mechanism cards include:

- Belousov–Zhabotinsky excitable waves;
- Liesegang precipitation/dissolution bands;
- spinodal/Cahn–Hilliard phase separation;
- Bénard–Marangoni surface-tension convection;
- Faraday parametric waves;
- Rosensweig ferrofluid instability;
- diffusion-limited aggregation;
- granular jamming / force chains;
- Rayleigh–Taylor, Kelvin–Helmholtz and Saffman–Taylor interfacial instabilities.

New physical-condition interaction vocabulary includes concentration, temperature, pressure, surface tension, viscosity, magnetic field, gravity, forcing frequency, supersaturation, friction, confinement and catalyst/inhibitor state.

Rule: preserve at least one genuine causal relationship/threshold from a scientific phenomenon; do not merely copy the surface look.

## New batch 021–025 — physical / chemical collision labs

Blind draw seed: `202609250742`.

These are experimental Gallery labs, not approved final artworks. All expose 8–9 mechanism-level controls and all use the shared live-sync contract.

### 021 — ROSENSWEIG FIELD

Path: `sketches/021_rosensweig_field/`

`magnetic field -> instability threshold -> coupled peak modes -> viscosity/hysteresis -> relaxation`

- fullscreen single-pass shader;
- autonomous moving magnetic field when untouched;
- touch becomes a movable magnet rather than a deformation brush;
- crossing field threshold raises ordered peak structures;
- field memory and viscosity remain after release;
- 8 controls: `FIELD STRENGTH`, `MAGNET RADIUS`, `VISCOSITY`, `SURFACE TENSION`, `PEAK SHARPNESS`, `MODE COUPLING`, `HYSTERESIS`, `RELAXATION`.

### 022 — LIESEGANG FRONT

Path: `sketches/022_liesegang_front/`

`diffusing reservoir -> supersaturation -> precipitation -> depletion spacing -> dissolution / persistent bands`

- up to four reagent reservoirs;
- moving fronts cross threshold and create persistent band generations;
- old bands retain their historical centres when the source later moves;
- depletion affects spacing, dissolution erases old material, field bias deforms future rings;
- 8 controls: `DIFFUSION`, `SUPERSATURATION`, `NUCLEATION`, `DEPLETION`, `DISSOLUTION`, `FRONT SPEED`, `BAND MEMORY`, `FIELD BIAS`.

### 023 — SPINODAL MARANGONI

Path: `sketches/023_spinodal_marangoni/`

`conserved phase field -> chemical potential -> coarsening -> thermal quench -> surface-tension advection`

- 56×32 conserved-ish phase field at fixed 22 Hz;
- Cahn–Hilliard-inspired two-pass chemical-potential update;
- mean phase corrected after each step to preserve mass approximately;
- touch injects thermal quench, not phase paint;
- thermal gradients advect interfaces through Marangoni-like coupling;
- one low-resolution field texture draw;
- 9 controls: `QUENCH DEPTH`, `MOBILITY`, `INTERFACE ENERGY`, `COARSENING`, `MASS BIAS`, `ADVECTION`, `THERMAL MEMORY`, `SURFACE TENSION`, `QUENCH RADIUS`.

### 024 — GRANULAR JAM

Path: `sketches/024_granular_jam/`

`packed grains -> collision contacts -> friction/load -> force chains -> creep -> delayed avalanche`

- 54 grains in a confining chamber;
- pairwise contacts computed at fixed 45 Hz;
- force-chain contacts are cached and reused for drawing instead of recalculating the contact graph;
- touch applies load/pressure, not positional dragging;
- accumulated stress can release later as avalanche/slip;
- 9 controls: `PACKING`, `FRICTION`, `LOAD`, `STIFFNESS`, `FORCE CHAINS`, `CREEP`, `AVALANCHE`, `CONFINEMENT`, `GRAIN SIZE`.

### 025 — FARADAY QUASI

Path: `sketches/025_faraday_quasi/`

`parametric forcing -> resonance windows -> mode competition -> nonlinear saturation -> standing-wave field`

- only four modal amplitudes/phases simulated on CPU;
- fullscreen single shader pass reconstructs the fluid surface;
- frequency/chirp moves the system through resonance windows;
- touch injects local phase/impulse and decays after release;
- 8 controls: `DRIVE`, `FREQUENCY`, `DAMPING`, `CAPILLARITY`, `DEPTH`, `MODE COUPLING`, `RESONANCE WIDTH`, `CHIRP`.

Runtime implementation commit: `50e7d9f9296768a09a56c7a8f7ac421a4d823389`.
CI #224 passed repository policy, Godot 4.7.1 import, main-scene smoke and tracked-file cleanliness for that runtime commit.

## Knowledge priority

For current creative work read:

1. `knowledge/cross-domain/TECHNIQUE_PALETTE.md`
2. `knowledge/cross-domain/RANDOM_COLLISION_ENGINE.md`
3. `knowledge/cross-domain/COLLISION_SOURCE_CATALOG.md`
4. `knowledge/cross-domain/PHYSICAL_CHEMICAL_SYSTEMS_ATLAS.md`
5. `knowledge/cross-domain/ORGANIC_COUPLING_AND_CONTROLS.md`
6. `knowledge/cross-domain/REALTIME_PERFORMANCE_BUDGET.md`
7. relevant creative-coding/design atlases
8. `CROSS_DOMAIN_ATLAS.md` / `IDEA_ENGINE.md` for promotion into finished artwork.

## Required next host test

Expected Gallery count: **25 sketches**.

1. Open 017 and 020 first and compare smoothness to the previous build.
2. Watch 021–025 for 20–30 seconds at defaults before touching controls.
3. Interact once, release, and watch delayed physical/chemical consequences.
4. Then explore the 8–9 controls and verify materially different regimes.
5. Test strongest candidates in PROGRAM/touch.
6. Close normally so telemetry can publish.
7. Immediately inspect fresh `telemetry/runtime`; require matching tested HEAD/session before attributing exact FPS.

Evaluation now has three axes:

- **mechanism** — does state really negotiate/propagate internally?
- **art direction** — is the default image already compelling?
- **performance architecture** — is the representation appropriate for realtime Gallery/PREVIEW/PROGRAM use?

## Mandatory AI operational completion

After every material repository change, every AI must automatically finish commits, update durable handoff/state, resolve final remote HEAD after all commits, wait for exact-head CI, report exact short SHA + CI, provide the canonical CI-waiting PowerShell when host testing is relevant, then inspect telemetry first after the host test.

## Non-regressions

Do not stop PROGRAM on navigation, create independent linked timelines, move the workstation as normal output, block UI with telemetry Git work, resurrect failed cross-window texture sampling, add card-covering overlays, fake Spout/NDI, restore Pressure Lattice, reintroduce artwork metadata captions, or make glyph contours the default representation.
