# Realtime Design Bridge

Professional graphic design principles become more useful to DC//LAB when translated into runtime constraints instead of copied as static aesthetics.

## Static design → realtime system

| Static principle | Realtime translation | Runtime variable examples |
|---|---|---|
| Grid | Dynamic coordinate system with stable relationships | columns, rows, gutter, baseline, density |
| Margin | Safe interaction/render zone | safe_x, safe_y, bleed_mode |
| Hierarchy | Priority across scale, contrast and motion | role, scale, luminance, motion_weight |
| Kerning/tracking | Local/global spacing behavior | tracking, pair_offset, touch_spacing |
| Type weight | Continuous visual emphasis | variable `wght`, stroke width |
| Type width | Density and responsive fit | variable `wdth` |
| Optical size | Size-aware letterform design | variable `opsz` |
| Color palette | Semantic role system | bg, fg, accent, support, alert |
| Poster crop | Explicit edge policy | crop, bleed, mask, overscan |
| Repetition | Temporal/spatial rhythm | count, phase, interval, repetition |
| Editorial sequence | State/scene progression | idle, active, peak, release |
| Identity system | Shared invariant rule set | font family, palette, grid, transition family |
| Material texture | Physically motivated shader behavior | grain scale, ink spread, registration |
| Wayfinding | Spatial hierarchy across screens | primary_screen, support_screen, interaction_zone |

## 1. Logical design coordinates first

Do not design directly in physical output pixels.

Recommended pattern:

```text
logical design space → layout → deformation/effects → output transform
```

This is why DC//LAB currently uses a stable logical design space for synced preview/PROGRAM rendering.

## 2. Effects must know the safe area

For typography and framed compositions, compute:

```text
final_bounds = glyph_bounds + motion_extent + effect_extent
```

where effect extent includes blur, glow, chroma split, displacement and lens magnification.

Only then test against safe margins.

## 3. Separate design parameters from implementation parameters

Good exposed parameters:

- density
- margin
- rhythm
- deformation
- palette
- weight
- width
- interaction radius
- recovery

Usually bad exposed parameters:

- raw internal buffer index
- obscure shader constants with no visual meaning
- duplicate controls that change nearly the same thing

Operator controls should describe artistic decisions.

## 4. Define invariants and variables

For every sketch, write down:

### Invariants

What must remain recognizable?

- type family
- central alignment axis
- palette relationship
- grid ratio
- interaction behavior
- motion grammar

### Variables

What may evolve?

- density
- phase
- weight
- distortion
- color mix
- scale
- particle count

Generative identity comes from variation inside invariants.

## 5. Responsive design is recomposition, not stretching

When output aspect ratio changes:

1. preserve hierarchy;
2. preserve safe margins;
3. recompute layout/grid;
4. preserve intended relationships;
5. scale only after those decisions.

Do not merely multiply all positions by viewport width/height when typography matters.

## 6. Interaction must share composition coordinates

Touch, pointer, PROGRAM and preview must map into the same logical design coordinates.

Interaction should be tested at:

- corners
- edges
- center
- multi-touch positions
- different physical monitor resolutions

## 7. Motion should have grammar

Define a small family of motion behaviors:

- snap
- spring
- glide
- elastic
- decay
- pulse
- reveal

Use them consistently. Random easing per object weakens identity.

## 8. Motion hierarchy

Assign motion importance:

```text
primary event > secondary response > ambient motion
```

Ambient movement should usually have lower amplitude, lower contrast or slower speed.

## 9. Realtime typography pipeline

Recommended conceptual pipeline:

```text
text content
→ shaping
→ glyph metrics/bounds
→ layout/grid
→ optical correction
→ local interaction deformation
→ visual effects
→ safe-area validation
→ preview/program rendering
```

Do not skip metrics/layout and jump directly from characters to particles when text must remain designed.

## 10. SDF/MSDF as a design surface

Distance fields are not only a rendering optimization. They expose typographic edge distance to shaders.

Design controls can include:

- fill threshold
- outline
- erosion/dilation
- edge softness
- glow
- local reveal
- edge particles
- distance-driven color

## 11. Variable fonts as realtime instruments

Map continuous font axes carefully:

- `wght` → pressure / loudness / importance
- `wdth` → proximity / available width / rhythm
- `opsz` → actual display size
- `slnt` → direction / velocity
- custom axes → semantic or musical controls

Clamp to real font axis ranges and keep spacing responsive.

## 12. Poster logic for fullscreen output

A PROGRAM frame should survive as a poster:

- one dominant visual idea;
- strong focal hierarchy;
- clear negative space;
- controlled edge relationships;
- no operator/debug UI;
- intentional crop or intentional safety.

## 13. Motion-poster logic

Treat a realtime sketch as a sequence of strong poster states connected by motion.

This is usually stronger than a composition where everything changes continuously with no pause or structure.

## 14. Color as a system

Store colors by role, not only value.

Example:

```text
background
foreground
accent_primary
accent_secondary
muted
```

Then palette transitions can interpolate roles while preserving hierarchy.

## 15. Perceptual color

When interpolating or generating palettes, prefer perceptually sensible spaces where possible rather than assuming equal RGB steps look equal.

For production, evaluate:

- luminance contrast
- saturation balance
- color-blind distinction if meaning is encoded
- projector/display gamut
- black levels in physical space

## 16. Generative print logic

Physical graphic processes can inspire shaders with rules:

- screenprint → layers + registration offset
- halftone → luminance → dot size
- risograph → limited palette + overprint
- letterpress → edge/pressure variation
- photocopy → threshold + noise + repeated degradation

Model the process rather than adding generic noise.

## 17. Identity across multiple sketches

Future DC//LAB collections can share design tokens:

```text
collection.fonts
collection.palette
collection.grid
collection.motion_family
collection.transition_family
collection.output_rules
```

This allows separate sketches to feel like one show.

## 18. Preview vs PROGRAM

Preview may run at lower resolution/FPS for performance, but composition/state must remain equivalent.

Never let preview optimization change:

- random seed
- layout density
- type metrics
- animation phase
- interaction position

## 19. Future A/B/C mixer implications

Design should already anticipate multiple live sources:

- each deck has one clear composition/state;
- transition is separate from source art;
- master output owns final color/transform/composite;
- source interaction remains addressable even when not in editor;
- parameter state is persistent and recallable;
- thumbnail/preview represents actual source state.

## 20. Research recipe for a new sketch

Before coding:

1. Pick 1 graphic-design principle.
2. Pick 1 typographic principle if type is present.
3. Pick 1 creative-coding technique.
4. Pick 1 interaction model.
5. Pick 1 constraint.
6. Inspect at least 3 independent references.
7. Define invariants/variables.
8. Define the frozen-frame composition.
9. Only then choose shader/simulation implementation.

Example:

```text
grid discipline
+ variable width typography
+ reaction diffusion
+ touch pressure
+ two-color constraint
= a specific system, not a random effect pile
```
