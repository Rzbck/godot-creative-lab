# DC//LAB Cross-Domain Knowledge Layer

This folder bridges the project's `creative-coding/` and `design/` libraries.

Its purpose is not to impose a house technique. It exists to help us move between domains, compare possible representations, combine principles, and mutate them into an original DC//LAB system.

A source is not a look to imitate. A technique is not a style to repeat.

## Read order

1. `TECHNIQUE_PALETTE.md` — compare the available representation/mechanism families before choosing an implementation.
2. `CROSS_DOMAIN_ATLAS.md` — reusable bridges between typography, graphic design, shaders, simulation, geometry, interaction and realtime systems.
3. `IDEA_ENGINE.md` — method for multiplying, mutating and filtering combinations into original concepts.
4. `LIVING_SYSTEMS.md` — optional research brick for autonomy, coupling, internal state, multiple time scales and interaction-as-perturbation when the concept needs it.
5. `SOURCE_CATALOG.md` — references selected because they demonstrate movement between disciplines.
6. `sources.json` — machine-readable index.

Use these together with:

- `../creative-coding/CONCEPT_ATLAS.md`
- `../creative-coding/SOURCE_CATALOG.md`
- `../design/TYPOGRAPHY_ATLAS.md`
- `../design/STRUCTURAL_TYPOGRAPHY.md` when internal glyph anatomy is relevant
- `../design/GRAPHIC_DESIGN_ATLAS.md`
- `../design/REALTIME_DESIGN_BRIDGE.md`
- `../design/DESIGN_REVIEW_CHECKLIST.md`

## Technique-selection rule

For substantial work, do not jump from concept directly to the most recently used technique.

Before implementation, compare at least three plausible chains, for example:

```text
same artistic intention
A -> direct / variable typography + layout state machine
B -> raster mask + feedback buffer + shader
C -> particles / agents + vector field + reconstruction
```

Choose the mechanism that makes the artistic idea more specific.

Contours, SDFs, feedback, particles, shaders, grids, meshes, graph systems, raster masks, simulations, variable fonts and whole-glyph typography are all separate options. None is the default.

## Core vocabulary

### Carrier

The thing carrying the work's identity: glyph, word, grid, line, image, particles, field, mesh, color system, data stream, spatial surface, etc.

### Representation

The computational form of the carrier: direct type, raster mask, vector path, sampled points, SDF/MSDF, scalar/vector field, graph, particles, texture history, mesh, parameter vector, etc.

Representation depth should match the claim. A concept about word hierarchy may need only direct typography; a concept about a counterform collapsing may need contours/SDF; a concept about memory may be better served by a feedback buffer.

### Operator

Sample, quantize, threshold, warp, fold, repeat, advect, diffuse, erode, dilate, sort, pack, interpolate, accumulate, feedback, displace, remap, segment, mirror, phase-shift, change topology, and so on.

### Driver

Time, pointer, velocity, acceleration, touch count, audio, glyph metrics, text content, field state, simulation state, camera or external data.

A driver is input to a system; it does not have to directly move the artwork.

### Temporal model

Stateless, loop, oscillator, spring, hysteresis, delay, accumulation, decay, feedback, autonomous agents, stochastic events, phase transition, repair, mutation, regime switching, etc.

### Design constraint

Grid, baseline rhythm, margin/crop rule, type family, palette logic, scale hierarchy, density limits, asymmetry, editorial sequence, etc.

## Diversity rule for a series

Several works should differ in more than wording and color.

- no more than two should share the same primary representation;
- no more than two should share the same primary temporal model;
- interaction consequences should materially differ;
- palette/composition differences alone do not count as conceptual diversity;
- structural typography is one option, not a mandatory DC//LAB signature;
- autonomous behavior is useful when conceptually justified, not a compulsory effect layer.

If five pieces could be produced by one renderer with changed text, colors and cursor mapping, the series has failed.

## Artwork / interface boundary

The logical PROGRAM canvas is the artwork. Do not burn sketch title, index, tags, debug metadata or explanatory UI captions into it. Text is valid when it is actually part of the artwork.

## Originality rule

Prefer combinations where independent references contribute different principles and where representation, behavior or temporal logic changes meaningfully.

Reject directions that are mainly:

- one tutorial effect plus our colors;
- the same representation repeated across every sketch;
- interaction reduced to a radial cursor mask;
- typography added because it looks fashionable rather than because its structure matters;
- simulation with no relationship to composition;
- a pile of unrelated effects without one system tying them together.

## Implementation boundary

This library stores our abstractions, links, tags and methods. Do not vendor external code/fonts/imagery/articles without explicit license review. Prefer reimplementation from understood principles.