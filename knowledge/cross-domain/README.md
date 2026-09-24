# DC//LAB Cross-Domain Knowledge Layer

This folder is the project's bridge between the existing `creative-coding/` and `design/` libraries.

The goal is not to collect more styles. The goal is to make the research library **generative itself**: extract transferable principles from several domains, translate them into compatible representations, combine them through reusable operators, then deliberately mutate the result until it becomes an original DC//LAB system.

A source is therefore not a look to imitate. It is raw material for a transformation grammar.

## Read order

1. `CROSS_DOMAIN_ATLAS.md` — maps reusable bridges between typography, graphic design, shaders, simulation, geometry, interaction and realtime systems.
2. `IDEA_ENGINE.md` — method for multiplying, mutating and filtering combinations into original concepts.
3. `LIVING_SYSTEMS.md` — autonomy, coupling, internal state, multiple time scales, emergence and interaction-as-perturbation.
4. `SOURCE_CATALOG.md` — references selected specifically because they demonstrate movement between disciplines.
5. `sources.json` — machine-readable index for later tooling, search or automated concept generation.

Use these together with:

- `../creative-coding/CONCEPT_ATLAS.md`
- `../creative-coding/SOURCE_CATALOG.md`
- `../design/TYPOGRAPHY_ATLAS.md`
- `../design/STRUCTURAL_TYPOGRAPHY.md`
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

Representation depth matters. A concept about internal glyph anatomy should not stop at a rigid glyph instance; move to contours, sampled points or SDF/MSDF when necessary.

### Operator

A transformation applied to a representation.

Examples: sample, quantize, threshold, warp, fold, repeat, advect, diffuse, erode, dilate, sort, pack, interpolate, accumulate, feedback, displace, remap, segment, mirror, phase-shift.

### Driver

The signal that changes the system.

Examples: time, pointer position, touch velocity, multiple touches, audio envelope, glyph metrics, text content, simulation state, noise, camera, external data.

A driver should not automatically be direct control. It may inject energy, change a boundary condition, alter coupling or seed an event.

### Temporal model

How state behaves through time.

Examples: stateless, oscillator, eased transition, spring, hysteresis, accumulation, decay, feedback, simulation, autonomous agent system, fatigue/repair, regime change.

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
+ 1 autonomous process
+ 1 interaction perturbation
+ 1 temporal model with memory/coupling when appropriate
+ 1 professional design constraint
```

Then run the result through the mutation process in `IDEA_ENGINE.md` and the living-system checks in `LIVING_SYSTEMS.md`.

Example structure, not a prescribed visual:

```text
glyph outlines
-> sampled contour population
-> neighbour spring coupling
-> counter area becomes local pressure
-> autonomous pressure oscillation changes contours
-> touch injects fatigue rather than directly setting position
-> damaged regions repair with hysteresis
-> composition remains governed by a fixed editorial hierarchy
```

The value is in the chain of transformations and feedback relationships, not any single effect.

## Originality rule

A DC//LAB concept should not be traceable to one reference's surface appearance.

Prefer combinations where:

- multiple independent references contribute different principles;
- at least one bridge crosses a genuinely different discipline;
- the implementation changes representation, behavior or temporal logic rather than only color/style;
- the system has meaningful autonomous behavior before interaction;
- interaction changes internal state rather than merely moving a cursor effect;
- consequences can propagate, persist, repair or alter later behavior;
- the final composition still has a deliberate graphic-design identity.

If the description can be reduced to "make source X but with our colors", the research process has failed.

## Artwork / interface boundary

The logical PROGRAM canvas is the artwork.

Do not burn project/interface metadata into it:

- sketch title;
- sketch number;
- tags/category;
- technical labels;
- explanatory captions that belong to the editor/Gallery.

Text is welcome when it is the actual artistic carrier.

A visible frame or poster-within-a-canvas is not the default. Use it only when framing itself is part of the concept.

## Living-system gate

Before implementation, answer:

```text
What happens for 30 seconds with no input?
What internal variables evolve?
What is coupled to what?
What is the fast time scale?
What is the slow time scale?
What does a gesture perturb?
What remains after release?
What can repair, fatigue, migrate, synchronize or change regime?
```

If those answers are mostly empty, the idea is probably still an interactive effect rather than a mature realtime system.

## Implementation boundary

This library is research memory. It stores our own abstractions, links, tags and methods.

Do not automatically vendor external code, fonts, imagery, screenshots, articles or project files. Before exact code/asset reuse, inspect the license and provenance of the specific upstream material. Prefer reimplementation from understood principles.
