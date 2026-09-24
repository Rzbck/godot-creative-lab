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
- `005_pressure_lattice` — internal path retained, visible artwork **REGISTER TYPE**. Original Pressure Lattice concept is rejected and must not be restored.
- `006_breath_score` — **BREATH SCORE**, restored to pre-contour-overuse implementation.
- `007_redaction_field` — **REDACTION FIELD**, restored; project caption/number suppressed by wrapper.
- `008_palimpsest` — **PALIMPSEST**, restored; archive caption/frame chrome suppressed.
- `009_chorus_drift` — **CHORUS DRIFT**, restored; explanatory frame/caption suppressed.
- `010_fault_register` — **FAULT REGISTER**, restored; editorial grid remains but project label/number removed.

## Rejected creative pass

Host test rejected commit `6c20a094` because glyph contours became a near-universal answer, several glyphs rendered inverted/broken, and the five works converged technically/aesthetically.

Commit `3a437fe2621c00c11c808b909cb6a30a5936e80a` rolled 006–010 back without restoring unwanted captions.

Do not resurrect contour-everywhere versions.

## Current diagnosis of 001–010

The Gallery is still creatively too concentrated.

Overrepresented:

- typography as primary carrier;
- direct 2D drawing / per-glyph layout;
- pointer/drag as primary interaction;
- local deformation;
- springs/oscillation;
- simple local memory/recovery;
- parameter sliders as visible creative controls.

Underused or absent:

- persistent framebuffer feedback;
- reaction-diffusion / excitable media;
- cellular automata;
- particle/agent populations as the artwork itself;
- topology/graph mutation;
- physical constraint networks / soft-body logic;
- Voronoi/Delaunay and recursive spatial partitioning;
- slitscan / temporal slicing;
- raymarching / volumetric SDF;
- procedural mesh/ribbon systems;
- 3D/spatial composition;
- birth/death and population ecology;
- discrete phase transitions / regime switching;
- non-pointer drivers such as audio, data or sensing when intentionally supported.

The problem is not lack of effects. It is lack of **different underlying mechanisms**.

## New exploration direction — collision-first

The user explicitly wants a more stochastic process before assigning artistic meaning.

Two modes are valid:

### Intent-first

`artistic question -> compare representations -> prototype -> refine`

### Collision-first

`blind random technical draw -> coupled raw prototype -> observe -> interpret -> art-direct -> mutate`

For the next exploration batch, collision-first is preferred.

Mandatory files:

- `knowledge/cross-domain/TECHNIQUE_PALETTE.md`
- `knowledge/cross-domain/RANDOM_COLLISION_ENGINE.md`
- `knowledge/cross-domain/COLLISION_SOURCE_CATALOG.md`

Broader references:

- `CROSS_DOMAIN_ATLAS.md`
- `IDEA_ENGINE.md`
- `LIVING_SYSTEMS.md`
- creative-coding and design atlases.

## Collision-first rules

For each seed randomly choose:

```text
1 carrier/material
+ 2 technically distant representations
+ 2 operators
+ 1 temporal model
+ 1 interaction consequence
+ 1 severe design constraint
```

Then:

1. couple the systems so they exchange state;
2. build an intentionally raw prototype before choosing a message/title/final palette;
3. observe autonomous and interacted behavior;
4. harvest the most interesting accidents;
5. only then assign artistic meaning and graphic direction;
6. mutate one card at a time if the result is weak;
7. kill the seed after three unsuccessful mutations.

Random stacking without coupling is technical soup and must be rejected.

## First blind draw — research seeds

These are not approved artworks and should not be art-directed before raw prototypes exist.

### A

`typography + GPU particles/agents + instanced geometry + sort/reorder + morphology + feedback memory + touch toggles topology + no noise`

### B

`architectural cells + vector-field advection + reaction-diffusion + grow/decay + phase shift + coupled oscillators + touch seeds population + no smooth interpolation`

### C

`line network + Voronoi/Delaunay + velocity field + fold/mirror + feedback sharpen/blur + birth/death + touch cuts links + horizontal attractor`

### D

`data-like symbols + raster morphology + procedural mesh/ribbons + recursive transform + domain warp + stochastic regime switching + dwell changes material + no smooth interpolation`

### E

`abstract symbols + raymarched SDF geometry + cellular automaton + collision/packing + phase transition + dwell changes local phase + two colors only`

Any artistic interpretation attached to these before a prototype is only a hypothesis.

## Internet research added

`COLLISION_SOURCE_CATALOG.md` now includes specialized references for:

- Nature of Code — agents, forces, CA, complexity;
- Book of Shaders — coordinate systems, image processing, ping-pong simulation, reaction-diffusion;
- LYGIA — broad shader/operator taxonomy;
- TouchDesigner official feedback/particle state loops;
- Simon Alexander-Adams — reaction-diffusion + CA driving particles/geometry;
- Derivative community — SDF geometry + particles, feedback + reaction-diffusion, text as simulation boundary;
- elekktronaut — feedback, instancing, slitscan, particle paths, generative blueprints;
- Codrops — WebGL/WebGPU particles, typography, physics, masks, material effects;
- Entagma — SDF, packing, advection, procedural geometry;
- Generative Hut — code + physical/plotter/material approaches;
- Raven Kwok — quadtree→Voronoi, particles→soft-body→Kinect, KD-tree recursion;
- Universal Everything — Living Motion Systems;
- onformative — research-driven generative/data installations;
- FIELD.IO — visual-library decomposition into generative identity systems.

## Creative rules that remain

1. PROGRAM canvas is artwork-only; project title/index/tags/debug labels stay in UI.
2. No single technique becomes house style accidentally.
3. Structural typography is optional.
4. Series diversity is structural, not cosmetic.
5. Parameters should bias a strong system, not rescue a weak default.
6. Interaction should exploit the mechanism actually discovered, not automatically use a radial cursor effect.
7. A collision should exchange state across systems rather than stack independent effects.

## Mandatory AI operational completion

The user should not need to ask for repository hygiene, CI waiting or the test launcher after each change.

After every material repository change, every AI must automatically:

1. update the durable handoff/state documents affected by the change;
2. resolve the final remote HEAD after all code + documentation commits;
3. wait for CI on that exact final SHA and inspect required jobs;
4. report exact short HEAD + CI result;
5. when host validation is relevant, include the canonical `sync + exact-head CI wait + launch Godot` PowerShell block from `docs/handoff/OPERATIONS.md`;
6. never launch/recommend launch before CI success in that block;
7. after host testing, read `telemetry/runtime` before requesting manual logs.

This is part of task completion, not optional cleanup. See `AGENTS.md` for the full protocol.

## Telemetry state

Latest host run published runtime head `729c3a2...` with all 10 previews loaded and no error entry found. The recent complaints are primarily visual/creative, not runtime crashes.

After further host tests, inspect `telemetry/runtime` before requesting manual logs.

## Next creative step

Do not redesign 006–010 again immediately.

Build raw prototypes from several blind collision seeds with minimal art direction. The purpose is to discover genuinely new behavior first. After observing them, select only the collisions whose emergent behavior has real visual/interactive potential, then perform the artistic-impact pass.

## Non-regressions

Do not stop PROGRAM on navigation, create independent linked timelines, move the workstation as normal output, block UI with telemetry Git work, resurrect the failed cross-window texture path, add card-covering overlays, fake Spout/NDI, restore Pressure Lattice, reintroduce artwork metadata captions, or make glyph contours the default representation.