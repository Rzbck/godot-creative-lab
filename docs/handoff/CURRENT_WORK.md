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
- `006_breath_score` — **BREATH SCORE**, restored to the pre-contour-overuse implementation.
- `007_redaction_field` — **REDACTION FIELD**, restored to the pre-contour-overuse implementation; project caption/number are suppressed by a thin wrapper.
- `008_palimpsest` — **PALIMPSEST**, restored to the pre-contour-overuse implementation; archive caption/frame chrome is suppressed by a thin wrapper.
- `009_chorus_drift` — **CHORUS DRIFT**, restored to the pre-contour-overuse implementation; explanatory frame/caption is suppressed by a thin wrapper.
- `010_fault_register` — **FAULT REGISTER**, restored to the pre-contour-overuse implementation; the editorial grid remains but project label/number are removed by a thin wrapper.

## Rejected creative pass

The host test of the `6c20a094` structural/autonomous pass was rejected.

Why it failed:

- glyph contours were applied as a near-universal answer instead of one technique among many;
- several glyph-contour renderings appeared vertically inverted / visually broken;
- the five works converged technically and aesthetically instead of becoming more diverse;
- the correction overfit one piece of feedback (`work inside letter structure`) and ignored the much larger available palette of shaders, fields, feedback, particles, SDFs, simulations, geometry, typography metrics, variable fonts, graphs, raster systems, etc.;
- the result became worse than the previous host-tested pass.

Commit `3a437fe2621c00c11c808b909cb6a30a5936e80a` rolls the five runtimes back without restoring the unwanted presentation captions.

Do not resurrect the rejected contour-everywhere versions.

## Creative rules established from host feedback

1. **PROGRAM canvas is artwork-only.** Sketch title, index, tags, debug/project metadata and explanatory pseudo-curatorial labels stay in the Gallery/editor UI.
2. **No single technique becomes house style by accident.** Vector contours, SDF, shaders, particles, feedback, simulation, direct type, mesh/geometry, fields, raster/masks, graphs and variable-font systems are all separate options.
3. **Concept chooses representation.** For substantial new work, compare at least three plausible technical representations before implementation.
4. **Structural typography is optional.** Only use contour/anatomy-level techniques when the artistic idea genuinely depends on internal glyph structure.
5. **Series diversity is structural.** Five works must not be five variants of one renderer with changed text/color/input mapping.
6. **Interaction and autonomy still need deeper research**, but do not solve that by blindly adding contour deformation or generic ambient oscillation.
7. **Parameters should express artistic/systemic choices**, not rescue a weak default composition.

## Knowledge system

Before substantial creative work use:

- `knowledge/creative-coding/`
- `knowledge/design/`
- `knowledge/cross-domain/`

Most important current files:

- `knowledge/cross-domain/TECHNIQUE_PALETTE.md` — mandatory selection/diversity guide;
- `knowledge/cross-domain/CROSS_DOMAIN_ATLAS.md`;
- `knowledge/cross-domain/IDEA_ENGINE.md`;
- `knowledge/cross-domain/LIVING_SYSTEMS.md` — useful as one behavior research brick, not a mandate that every artwork must be autonomous;
- `knowledge/design/TYPOGRAPHY_ATLAS.md`;
- `knowledge/design/STRUCTURAL_TYPOGRAPHY.md` — optional technique-specific reference, not the default typography strategy;
- `knowledge/design/DESIGN_REVIEW_CHECKLIST.md`.

### Mandatory technique-selection protocol

For a substantial new sketch, write at least three candidate implementation chains before choosing one.

Example:

```text
same intention
A -> direct/variable typography + layout state machine
B -> raster mask + temporal feedback + shader
C -> particles/agents + field + reconstruction
```

Choose by artistic fit, not by recency/convenience.

For a multi-sketch series:

- no more than two works should share the same primary representation;
- no more than two should share the same primary temporal model;
- interaction consequence must materially differ;
- palette/composition changes alone do not count as technical/conceptual diversity.

## Telemetry state

The latest host run published runtime head `729c3a2...` with all 10 previews loaded and no error entry found in the rolling telemetry. The user's complaint is therefore primarily a visual/creative failure, not evidence of a runtime crash.

After any further host test, inspect `telemetry/runtime` before requesting manual logs.

## Validation / next step

The runtime rollback itself must pass exact-head CI before being presented as stable.

Do **not** immediately generate another batch of five artworks.

Next creative task is a real gap analysis of the research library and technique palette:

1. classify current sketches 001–010 by primary representation, temporal model, interaction consequence, composition system and visual material;
2. identify overrepresented mechanisms and missing families;
3. research studio-grade references for the missing families;
4. expand the library with concrete implementation bridges;
5. only then design the next major artwork/series.

## Non-regressions

Do not stop PROGRAM on navigation, create independent linked timelines, move the workstation as the normal output mechanism, block the UI with telemetry Git work, resurrect the failed cross-window texture path, add card-covering overlays, fake Spout/NDI, restore Pressure Lattice, reintroduce artwork metadata captions, or make glyph contours the default creative representation.