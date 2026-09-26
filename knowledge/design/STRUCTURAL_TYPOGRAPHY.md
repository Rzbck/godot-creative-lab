# Structural Typography for Realtime Systems

This document exists because moving, scaling or tinting a whole glyph is **not** the same thing as deforming typography.

When the concept depends on the body of a letter, choose a representation deep enough to reach its anatomy.

## 1. Representation depth

Use the shallowest representation that still preserves the concept.

```text
string/layout
→ glyph instance
→ vector contour
→ sampled contour points
→ SDF/MSDF boundary
→ topology / region graph
```

Typical choices:

- **string/layout** — editorial hierarchy, line breaking, alignment, reading rhythm;
- **glyph instance** — per-letter position, rotation, scale, tracking, sequencing;
- **vector contour** — stems, bowls, counters, apertures, terminals, local bending, splitting;
- **SDF/MSDF** — erosion/dilation, edge fields, topology-preserving thresholds, shader coupling;
- **topology/region graph** — experiments where counters, connected components or letter parts become independent agents.

If the artistic claim is “the letter bends internally” but the implementation only translates the glyph origin, the representation is too shallow.

## 2. Letter anatomy is a constraint system

Useful structural regions include:

- stem;
- crossbar;
- bowl;
- counter;
- aperture;
- shoulder;
- spine;
- terminal;
- diagonal;
- vertex;
- overshoot zone;
- baseline contact;
- cap-height contact.

Not every font exposes semantic labels for these regions. They can still be approximated from contour position, local curvature, extrema and connectivity.

The goal is not to destroy outlines randomly. It is to define **which anatomical relationships may change and which remain invariant**.

## 3. Structural deformation operators

Prefer operators with a typographic interpretation.

### Counter breathing

Expand or contract points relative to a local counter/contour center while keeping the baseline stable.

### Stem shear

Move upper and lower regions in opposite directions while preserving stem thickness approximately.

### Aperture opening

Move contour points near an opening while anchoring the opposite bowl.

### Baseline hinge

Treat baseline contact points as fixed pivots and bend the rest of the glyph around them.

### Terminal drift

Allow endpoints/terminals to lag behind the main body through spring or inertial motion.

### Contour split

Apply opposite displacements to points on different sides of a fault line. One glyph can visibly fracture without becoming two unrelated sprites.

### Curvature pressure

Weight deformation by local curvature: round sections, corners and straight stems respond differently.

### Area compensation

If one region expands, compress another so the glyph approximately conserves occupied area. This often produces more deliberate results than free scaling.

## 4. Preserve something

Strong deformation needs a reference.

Possible invariants:

- baseline;
- cap height;
- counter visibility;
- total width;
- average stroke density;
- one anchor stem;
- reading order;
- word silhouette;
- optical center.

Choose at least one invariant before coding the deformation.

If every property changes independently, the result usually reads as noise rather than typography.

## 5. Autonomy before interaction

A realtime typographic artwork should normally have a designed autonomous state.

Ask:

- What does the letter do when nobody touches it for 30 seconds?
- Does its anatomy have a slow internal rhythm?
- Do glyphs influence neighboring glyphs?
- Is there accumulation, fatigue, repair, migration or phase change?
- Can a viewer understand the system before interacting?

Interaction should **perturb, feed, inhibit, select, redirect or wound** an already living system.

Avoid:

```text
idle = static poster
pointer down = effect on
pointer up = effect off
```

Prefer:

```text
autonomous system
+ user injects state/energy/constraint
+ system redistributes it
+ consequences persist/evolve
```

## 6. Couple letter anatomy to the system

The strongest crossing happens when typography is not merely the visual output.

Examples:

- counter area changes local fluid pressure;
- stem orientation changes vector-field direction;
- local curvature changes particle emission;
- glyph width changes oscillator frequency, which later changes glyph width;
- damaged contour length changes repair speed;
- one letter's deformation becomes a force on its neighbors.

This creates feedback instead of a one-way filter.

## 7. Interaction at structural depth

Touch should know **where inside the glyph** it acts.

Possible mappings:

- distance to contour point;
- side of a local fault plane;
- nearest stem/curve region;
- pointer velocity projected onto contour tangent;
- dwell time converted into local material fatigue;
- acceleration converted into fracture probability;
- two touches defining a stretch axis;
- drag crossing a counter opening/closing that aperture.

A radial cursor mask can still be useful, but it should not be the default interaction model.

## 8. Full-canvas rule

Gallery metadata belongs to Gallery UI, never to the artwork.

Do not burn into PROGRAM output:

- sketch title;
- sketch number;
- category name;
- project metadata;
- explanatory labels;
- fake museum/index captions.

Text may appear when it is **the actual artistic carrier**.

The 1280×720 logical canvas is the artwork. A smaller “poster card” inside that canvas is only valid when framing itself is conceptually necessary.

## 9. Parameters should bias behavior

Prefer:

- autonomy;
- fatigue;
- cohesion;
- repair;
- memory;
- pressure;
- permeability;
- coupling;
- mutation rate;
- structural tension.

Be suspicious of a panel dominated by:

- effect amount;
- generic speed;
- generic distortion;
- generic noise;
- generic contrast;
- several sliders that all increase visual chaos.

An artistic parameter should change the **rules of the system**, not merely the amount of post-processing.

## 10. Godot 4.7 implementation note

Godot exposes real font outline data through `TextServer.font_get_glyph_contours()`.

DC//LAB provides a shared sampled-contour helper under:

`sketches/_shared/glyph_contour_tools.gd`

and design-space helpers in:

`sketches/_shared/design_sketch_base.gd`

This makes contour-level experiments possible without importing third-party font geometry libraries.

Use cached contour sampling and keep CPU cost controlled for PROGRAM output.

## 11. Structural typography review

Before accepting a typographic sketch, ask:

1. Is typography carrying meaning, structure or behavior rather than fashion?
2. Is the chosen representation deep enough for the claimed deformation?
3. What anatomical feature actually changes?
4. What anatomical feature remains invariant?
5. Does the system live without user input?
6. Does interaction alter internal state rather than only a cursor-local effect?
7. Does deformation propagate, persist, couple or recover meaningfully?
8. Can several arbitrary frames survive as designed compositions?
9. Is the full canvas the artwork, with no project metadata burned in?
10. Would removing the pointer still leave an interesting evolving piece?
