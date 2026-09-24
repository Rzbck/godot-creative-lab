# DC//LAB Cross-Domain Knowledge Layer

This folder is the project's bridge between the existing `creative-coding/` and `design/` libraries.

The goal is not to collect more styles. The goal is to make the research library **generative itself**: extract transferable principles from several domains, translate them into compatible representations, combine them through reusable operators, then deliberately mutate the result until it becomes an original DC//LAB system.

A source is therefore not a look to imitate. It is raw material for a transformation grammar.

## Read order

1. `CROSS_DOMAIN_ATLAS.md` — maps reusable bridges between typography, graphic design, shaders, simulation, geometry, interaction and realtime systems.
2. `IDEA_ENGINE.md` — method for multiplying, mutating and filtering combinations into original concepts.
3. `SOURCE_CATALOG.md` — references selected specifically because they demonstrate movement between disciplines.
4. `sources.json` — machine-readable index for later tooling, search or automated concept generation.

Use these together with:

- `../creative-coding/CONCEPT_ATLAS.md`
- `../creative-coding/SOURCE_CATALOG.md`
- `../design/TYPOGRAPHY_ATLAS.md`
- `../design/GRAPHIC_DESIGN_ATLAS.md`
- `../design/REALTIME_DESIGN_BRIDGE.md`
- `../design/DESIGN_REVIEW_CHECKLIST.md`

## Core vocabulary

Every cross-domain concept can be decomposed into a small set of roles.

### Carrier

The thing that carries the identity of the work.

Examples: glyph, word, grid, line, image, particle set, field, mesh, color system, data stream, spatial surface.

### Representation

The form in which the carrier becomes manipulable.

Examples: raster mask, vector path, sampled points, signed distance field, scalar field, vector field, graph, particle cloud, texture buffer, mesh, parameter vector.

### Operator

A transformation applied to a representation.

Examples: sample, quantize, threshold, warp, fold, repeat, advect, diffuse, erode, dilate, sort, pack, interpolate, accumulate, feedback, displace, remap, segment, mirror, phase-shift.

### Driver

The signal that changes the system.

Examples: time, pointer position, touch velocity, multiple touches, audio envelope, glyph metrics, text content, simulation state, noise, camera, external data.

### Temporal model

How state behaves through time.

Examples: stateless, oscillator, eased transition, spring, hysteresis, accumulation, decay, feedback, simulation, autonomous agent system.

### Design constraint

The rules that stop the result becoming arbitrary.

Examples: modular grid, baseline rhythm, fixed margins, two-color palette, one type family, limited scale ratio, controlled crop, hierarchy bands, density limits, asymmetry rule.

### Output

The final rendering language.

Examples: 2D shader field, kinetic poster, particle typography, procedural mesh, live identity, interactive installation surface, realtime type system.

## Default cross-domain recipe

For substantial new work, choose deliberately:

```text
1 carrier
+ 1 representation change
+ 2 operators from different domains
+ 1 driver
+ 1 temporal model
+ 1 professional design constraint
+ 1 interaction rule when interaction is meaningful
```

Then run the result through the mutation process in `IDEA_ENGINE.md`.

Example structure, not a prescribed visual:

```text
glyph outlines
-> sampled point cloud
-> flow-field advection
-> density reconstructed as an SDF
-> touch velocity changes field curl
-> feedback adds temporal memory
-> composition remains locked to a modular editorial grid
```

The value is in the chain of transformations, not any single effect.

## Originality rule

A DC//LAB concept should not be traceable to one reference's surface appearance.

Prefer combinations where:

- multiple independent references contribute different principles;
- at least one bridge crosses a genuinely different discipline;
- the implementation changes representation, behavior or temporal logic rather than only color/style;
- interaction changes the system's internal logic instead of merely moving a cursor effect;
- the final composition still has a deliberate graphic-design identity.

If the description can be reduced to "make source X but with our colors", the research process has failed.

## Implementation boundary

This library is research memory. It stores our own abstractions, links, tags and methods.

Do not automatically vendor external code, fonts, imagery, screenshots, articles or project files. Before exact code/asset reuse, inspect the license and provenance of the specific upstream material. Prefer reimplementation from understood principles.