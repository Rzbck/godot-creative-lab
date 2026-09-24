# Typography Atlas for Realtime / Generative Design

This file translates professional typography principles into constraints and creative opportunities for realtime sketches.

## 1. Glyph anatomy and metrics

Know the difference between:

- baseline
- cap height
- x-height
- ascender / descender
- advance width
- sidebearings
- glyph bounding box
- em square
- line gap
- optical overshoot

### Realtime rule

Never position or clamp a glyph only from its origin point. Use the **visual/glyph bounds** when the design depends on margins or framing.

### Failure mode

A grid appears mathematically centered but letters visibly spill outside the frame because the origin is inside the glyph while the actual outline extends beyond it.

## 2. Kerning vs tracking

- **Kerning** adjusts individual letter pairs.
- **Tracking** adjusts spacing across a sequence.

### Realtime opportunities

- map tracking to audio energy while preserving minimum pair spacing;
- use velocity to open/close spacing;
- let a field affect tracking locally rather than distorting entire glyph shapes;
- animate between dense and open typographic states.

### Rule

Do not use tracking as a substitute for a bad font size or bad grid.

## 3. Word spacing

Word spacing determines the visual rhythm of sentences and blocks.

### Realtime opportunities

- compress words toward an interaction point;
- expand silence/space after beats;
- treat spaces as active cells in a generative field.

### Failure mode

Animating letters individually while ignoring word structure destroys readability and rhythm.

## 4. Leading / line spacing

Line spacing affects texture, readability and vertical rhythm.

### Realtime rule

When line spacing changes, compute it from type metrics or a controlled scale rather than arbitrary pixel offsets.

### Useful starting point

For readable text, professional typography references commonly begin around 1.2–1.45× font size, but expressive display typography can intentionally depart from that when overlap/collision is part of the concept.

## 5. Line length

Long lines reduce vertical tracking comfort; very short lines fragment rhythm.

### Realtime translation

- constrain readable text blocks to a stable measure;
- if viewport width changes, reflow instead of scaling indefinitely;
- for display typography, let cropping be intentional and controlled separately from body-text rules.

## 6. Baseline grids

A baseline grid creates vertical consistency across multiple text elements.

### Realtime uses

- snap moving captions to a baseline lattice;
- let deformation occur between baseline states;
- use the baseline as a hidden force field;
- keep type hierarchy stable while backgrounds remain generative.

## 7. Modular grids

Use a repeated cell structure for type, image, data and motion.

### Realtime uses

- grid density as an artistic parameter;
- responsive columns determined by design width;
- cells become particles/fields while preserving global alignment;
- transitions can interpolate from one modular grid to another.

### Rule

Changing density must recompute margins, cell dimensions, font size and glyph bounds together. Density is not just “draw more letters.”

## 8. Safe margins

Margins are active design space, not leftover pixels.

### DC//LAB rule

Every sketch that uses framed typography should define a logical safe rectangle in design coordinates.

Example concept:

```text
DESIGN 1280×720
SAFE X = 96
SAFE Y = 88
CONTENT RECT = [96,88] → [1184,632]
```

### Realtime rule

Distortion, chromatic split, glow and motion amplitude must be included in the safety calculation. Clamp the **final visual bounds**, not only the undeformed glyph anchor.

## 9. Optical alignment

Mathematical centering is not always visual centering.

Round forms, punctuation and diagonals may need optical correction.

### Realtime uses

- optical-offset tables for punctuation;
- center words using actual rendered bounds;
- allow slight overshoot beyond geometric guides when it improves perceived alignment.

## 10. Hierarchy

Hierarchy can be created through:

- scale
- weight
- width
- position
- contrast
- color
- spacing
- density
- motion
- persistence/duration
- blur/sharpness

### Realtime rule

Motion is itself a hierarchy channel. If everything moves equally, nothing is prioritized.

## 11. Type scale

A typographic scale creates controlled relationships rather than arbitrary sizes.

### Realtime translation

Use discrete roles such as:

- micro
- caption
- body
- subhead
- display
- hero

Then animate within ranges without collapsing the hierarchy.

## 12. Weight

Weight changes both tone and occupied area.

### Variable-font opportunity

Map audio, pressure, touch force or semantic importance to `wght`, but compensate spacing/line length as weight changes.

## 13. Width

Width is powerful for dynamic systems because it changes density without simply scaling everything.

### Realtime opportunity

Use `wdth` for breathing, compression, proximity and responsive fitting.

## 14. Optical size

Variable fonts may expose `opsz`, allowing the design to adapt to intended display size.

### Realtime opportunity

Use optical size when changing scale rather than relying only on geometric scaling.

## 15. Slant / italic

Slant creates direction and energy.

### Realtime opportunity

Map horizontal velocity to slant, but return smoothly to neutral. Treat slant as directional information rather than decoration.

## 16. Custom variable-font axes

Some fonts expose custom axes beyond `wght`, `wdth`, `opsz`, `slnt`.

### DC//LAB opportunity

Variable font axes can become native shader parameters, with limits read from font metadata and mapped to touch/audio/data.

## 17. Alignment modes

Study:

- flush-left / ragged-right
- flush-right / ragged-left
- centered
- justified
- axial / symmetric
- asymmetric

### Realtime rule

A transition between alignment systems should interpolate deliberately; avoid intermediate frames that look like accidental misalignment.

## 18. Rag quality

The edge shape of ragged text is a compositional object.

### Realtime opportunity

Generate changing line breaks but score them to avoid ugly single-word lines, extreme gaps or repetitive shapes.

## 19. Justification

Justified text distributes space to align both edges.

### Risk

Realtime width changes can create rivers and extreme word spacing.

### Use

For expressive systems, those rivers can be intentional—but should be measured and controlled.

## 20. Contrast pairing

Strong typography often pairs contrasting roles:

- serif / sans
- wide / narrow
- light / black
- roman / italic
- geometric / humanist
- display / neutral text

### Realtime rule

Pairings should have defined roles. Do not randomly switch fonts frame-to-frame.

## 21. Repetition and seriality

Repeated words/glyphs build texture and rhythm.

### Realtime opportunity

- phase-shift repeated words;
- create typographic waves;
- layer repeated glyphs with controlled opacity;
- use serial type as spatial structure.

## 22. Cropping

Cropping can increase scale and tension.

### Rule

Crop because the composition wants it, not because the layout overflowed.

### Implementation

Expose crop/bleed as a design parameter separate from safety margins.

## 23. Type as shape

At display scale, text can behave as geometry rather than only language.

### Techniques

- silhouette masks
- outlines
- fills
- subtractive counters
- repeated contours
- extrusion
- cutouts
- image masks
- field boundaries

## 24. Type as texture

Dense small type can function as tonal material.

### Realtime techniques

- density maps
- glyph mosaics
- character brightness mapping
- text halftone
- typographic dithering

## 25. Type as particles

Glyphs or points sampled from glyph outlines can become particle sources.

### Rule

Preserve a recognizable typographic state to give the dissolve/reconstruction meaning.

## 26. SDF/MSDF typography

Distance-field rendering allows scalable text with shader-controlled edges.

### Opportunities

- outline width
- soft edge
- glow
- dilation/erosion
- reveal
- threshold animation
- local distortion
- chromatic edge splitting

### Rule

Keep the underlying glyph edge stable enough that effects feel intentional rather than like poor rasterization.

## 27. Kinetic typography

Motion can encode rhythm, emphasis and semantic structure.

### Useful motion roles

- entrance
- hold
- accent
- transition
- exit
- loop

### Rule

Define timing grammar. Do not independently animate every glyph unless the concept requires chaos.

## 28. Temporal hierarchy

A word can become important because it:

- appears earlier;
- remains longer;
- moves differently;
- snaps while others ease;
- becomes the only stable element.

This is the time-based equivalent of static typographic hierarchy.

## 29. Motion rhythm

Typography in motion benefits from beats, pauses and repetition.

### Realtime mapping

- use audio onset for structural events;
- use continuous amplitude for subtle deformation;
- avoid mapping every audio frequency directly to an unrelated visual property.

## 30. Spatial typography

Text on multiple screens or projection surfaces needs physical composition.

Consider:

- viewing distance
- screen aspect ratio
- bezel/gap
- touch reach
- perspective
- physical margins
- audience position
- environmental contrast

## 31. Multi-script shaping

Latin assumptions fail for Arabic, Devanagari, Thai, CJK and many other writing systems.

### Rule

Use proper shaping/layout engines and script-aware line breaking. Never treat every Unicode code point as an independently placeable “character” for normal text.

## 32. Directionality

Right-to-left and bidirectional text require logical-order vs visual-order awareness.

### Realtime rule

Animation should preserve reading order and shaping behavior unless deliberate deconstruction is the artwork.

## 33. Color typography

Color controls hierarchy, emotion and legibility.

### Rules

- preserve sufficient luminance separation when readability matters;
- avoid making every layer saturated;
- use accent color strategically;
- test color-blind distinguishability when color carries meaning;
- consider background motion when evaluating contrast.

## 34. Chromatic aberration / RGB split

RGB splitting is visually strong but quickly destroys edge clarity.

### Rule

Scale split relative to glyph size and keep it inside safe margins. Use local/interaction-dependent split rather than constant maximum separation.

## 35. Distortion

Distortion should have a reference state.

Good pattern:

```text
rest → deformation → recovery
```

Without a stable reference, viewers cannot perceive the transformation as typographic behavior.

## 36. Touch typography

Touch can map to:

- displacement
- local tracking
- weight/width axes
- reveal
- erasure
- spring force
- rotation
- color emphasis

### Rule

Direct manipulation should feel spatially consistent: the affected letters should correspond to where the user touched on the output surface.

## 37. Responsive typography

For multiple output screens:

- define a logical composition space;
- letterbox/crop deliberately;
- recompute font metrics when dimensions change;
- separate physical resolution from typographic layout units;
- preserve hierarchy before preserving absolute pixel size.

## 38. Legibility vs expression

Not all type must be maximally readable, but the intended role must be clear.

Classify each text element:

- information
- navigation
- title/display
- texture
- image/material

Apply readability constraints according to role.

## 39. Accessibility resilience

When text communicates required information:

- maintain contrast;
- avoid ultra-light weights at small sizes;
- do not encode meaning only in color;
- avoid motion that makes reading impossible;
- respect reduced-motion modes where relevant;
- ensure spacing changes do not destroy content.

## 40. The DC//LAB typography test

Before validating a typographic sketch, ask:

1. Are the margins intentional at every parameter extreme?
2. Are glyph visual bounds inside the intended safe area?
3. Is hierarchy visible in a still frame?
4. Is motion adding meaning or only noise?
5. Does the design still work at PROGRAM resolution?
6. Does touch act on the spatial location the user touched?
7. Are preview and PROGRAM compositionally identical?
8. Does changing density recompute the complete layout system?
9. Is cropping deliberate?
10. Can the visual return to a legible/stable reference state?
