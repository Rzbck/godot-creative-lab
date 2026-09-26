# DC//LAB Cross-Domain Knowledge Layer

This folder bridges the project's `creative-coding/` and `design/` libraries.

Its purpose is not to impose a house technique. It exists to help us move between domains, compare possible representations, combine principles, and mutate them into an original DC//LAB system.

A source is not a look to imitate. A technique is not a style to repeat.

## Two valid starting modes

### Intent-first

Use when there is already a strong artistic question or material premise.

`intention -> compare representations -> prototype -> refine`

Use `TECHNIQUE_PALETTE.md`, `CROSS_DOMAIN_ATLAS.md` and `IDEA_ENGINE.md`.

### Collision-first

Use when the goal is to escape our habits and discover behavior we would not have designed directly.

`blind random draw -> coupled raw prototype -> observe emergence -> assign meaning -> art-direct -> mutate`

Use `RANDOM_COLLISION_ENGINE.md` and `COLLISION_SOURCE_CATALOG.md`.

The collision-first mode is intentionally allowed to choose technique before meaning. This is a separate research procedure, not a universal house method.

## Read order

For general creative work:

1. `TECHNIQUE_PALETTE.md` — representation/mechanism families.
2. `RANDOM_COLLISION_ENGINE.md` — stochastic collision-first exploration method.
3. `COLLISION_SOURCE_CATALOG.md` — specialist references for hybrid systems and emergent behavior.
4. `PHYSICAL_CHEMICAL_SYSTEMS_ATLAS.md` — real-world instabilities, matter, chemistry, thresholds and physical-condition interaction cards.
5. `ORGANIC_COUPLING_AND_CONTROLS.md` — host-derived rules for neighbour coupling, organic state exchange, 6–9 meaningful controls and minimum visual quality.
6. `REALTIME_PERFORMANCE_BUDGET.md` — representation/cadence/rendering rules for keeping labs fast inside Gallery/PREVIEW/PROGRAM.
7. `CROSS_DOMAIN_ATLAS.md` — reusable bridges between typography, design, shaders, simulation, geometry, interaction and realtime systems.
8. `IDEA_ENGINE.md` — concept-first multiplication/mutation method.
9. `LIVING_SYSTEMS.md` — optional research brick for autonomy, coupling and internal state.
10. `SOURCE_CATALOG.md` — broader cross-domain references.
11. `sources.json` — machine-readable index.

Use these together with:

- `../creative-coding/CONCEPT_ATLAS.md`
- `../creative-coding/SOURCE_CATALOG.md`
- `../design/TYPOGRAPHY_ATLAS.md`
- `../design/STRUCTURAL_TYPOGRAPHY.md` only when internal glyph anatomy is relevant
- `../design/GRAPHIC_DESIGN_ATLAS.md`
- `../design/REALTIME_DESIGN_BRIDGE.md`
- `../design/DESIGN_REVIEW_CHECKLIST.md`

## Technique-selection rule — intent-first mode

When an artistic intention already exists, do not jump directly to the most recently used technique.

Compare at least three plausible chains and choose the mechanism that makes the idea more specific.

Contours, SDFs, feedback, particles, shaders, grids, meshes, graph systems, raster masks, simulations, variable fonts and whole-glyph typography are all separate options. None is the default.

## Technique-selection rule — collision-first mode

When deliberately exploring by chance, choose mechanisms blindly first.

For each seed draw:

```text
1 carrier/material
+ 2 technically distant representation families
+ 2 operators
+ 1 temporal model
+ 1 interaction consequence
+ 1 severe design constraint
```

The draw may also include a **real-world phenomenon / physical condition** from `PHYSICAL_CHEMICAL_SYSTEMS_ATLAS.md`, for example:

- excitable chemistry / BZ waves;
- precipitation / Liesegang bands;
- spinodal phase separation;
- Marangoni convection;
- Faraday resonance;
- ferrofluid / Rosensweig instability;
- DLA growth;
- granular jamming / force chains;
- interfacial instability.

When a real-world card is selected, preserve at least one genuine causal relationship or threshold instead of copying only its surface appearance.

Then build a coupled prototype before assigning final meaning.

Random systems must exchange state. Randomly stacking visible effects is not enough.

## Current host-derived quality rules

A raw collision may be experimental, but Gallery inclusion has stronger gates:

- substantial labs normally expose **6–9 independent systemic/artistic controls** when the mechanism supports them;
- controls must alter different axes of the system, not duplicate `amount/chaos/speed`;
- at least half of exposed controls should affect future evolution rather than only rendering the current frame;
- cellular/raster work claiming organic behavior must propagate state through neighbours, resources, pressure, delay, phase, constraints or another local relationship;
- raw does not mean visually careless: default palette, mass/void distribution and frozen-frame quality still matter;
- interaction should modify a living system's future, not merely paint a temporary cursor effect;
- performance architecture is part of creative quality: dense fields should not become thousands of CanvasItem draw calls per render frame when a texture/shader representation preserves the idea better.

See `ORGANIC_COUPLING_AND_CONTROLS.md` and `REALTIME_PERFORMANCE_BUDGET.md` for the detailed rules.

## Core vocabulary

### Carrier

The thing carrying the work's identity: glyph, word, grid, line, image, particles, field, mesh, color system, data stream, spatial surface, etc.

### Representation

The computational form of the carrier: direct type, raster mask, vector path, sampled points, SDF/MSDF, scalar/vector field, graph, particles, texture history, mesh, parameter vector, etc.

### Operator

Sample, quantize, threshold, warp, fold, repeat, advect, diffuse, erode, dilate, sort, pack, interpolate, accumulate, feedback, displace, remap, segment, mirror, phase-shift, change topology, etc.

### Driver

Time, pointer, velocity, acceleration, touch count, audio, glyph metrics, text content, field state, simulation state, camera or external data.

Physical/chemical drivers now also include concentration, temperature, pressure, surface tension, viscosity, magnetic field, gravity vector, forcing frequency, supersaturation, friction, confinement and catalyst/inhibitor state.

### Temporal model

Stateless, loop, oscillator, spring, hysteresis, delay, accumulation, decay, feedback, autonomous agents, stochastic events, phase transition, repair, mutation, birth/death, regime switching, etc.

### Design constraint

Grid, baseline rhythm, margin/crop rule, type family, palette logic, scale hierarchy, density limits, asymmetry, editorial sequence, etc.

## Diversity rule for a series

Several works should differ in more than wording and color.

- no more than two share the same primary representation;
- no more than two share the same primary temporal model;
- interaction consequences materially differ;
- at most two use typography as the primary carrier in a five-work collision batch;
- include persistent feedback/state, population behavior, discrete rules and spatial/geometry systems across the batch when feasible;
- parameter vocabularies should reveal different mechanisms rather than repeat the same generic controls;
- palette/composition differences alone do not count as technical diversity;
- do not use five CPU raster loops when one or more experiments could be analytic shaders, cached geometry, particles, MultiMesh or low-resolution field textures.

If five pieces could be produced by one renderer with changed text, colors and cursor mapping, the series has failed.

## Artwork / interface boundary

The logical PROGRAM canvas is the artwork. Do not burn sketch title, index, tags, debug metadata or explanatory UI captions into it. Text is valid when it is actually part of the artwork.

## Originality rule

Prefer systems where independent mechanisms alter each other and where behavior cannot be reduced to one familiar realtime preset.

Reject directions that are mainly:

- one tutorial effect plus our colors;
- the same representation repeated across every sketch;
- interaction reduced to a radial cursor mask;
- typography added automatically;
- simulation with no relationship to composition;
- independently animated pixels presented as an organic system;
- randomly stacked effects without coupling;
- complexity visible only in code rather than behavior;
- visual density bought with structurally wasteful rendering.

## Implementation boundary

This library stores our abstractions, links, tags and methods. Do not vendor external code/fonts/imagery/articles without explicit license review. Prefer reimplementation from understood principles.
