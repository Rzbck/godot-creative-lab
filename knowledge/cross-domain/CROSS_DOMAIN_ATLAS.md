# Cross-Domain Atlas

This atlas maps **translations**, not styles.

A domain becomes useful to another domain when we identify a representation they can share. Typography can become points, paths, masks or distance fields. A graphic grid can become coordinates, topology or constraints. Motion can become a parameter field. Interaction can become forces. A simulation can become a mask, displacement map, density field or temporal memory.

The practical question is always:

> What representation lets concept A become manipulable by the logic of concept B?

## 1. Universal bridge pattern

Most useful cross-domain transitions follow this structure:

```text
SOURCE DOMAIN
    -> extract a representation
    -> transform it with one or more operators
    -> drive it with another system
    -> constrain it using a design rule
TARGET EXPERIENCE
```

Example:

```text
typography
-> glyph contours
-> sampled points
-> vector-field advection
-> pointer velocity controls field intensity
-> editorial grid constrains density and margins
-> interactive generative poster
```

The important step is the **representation change**. Without it, cross-domain work often degenerates into an effect layered on top of another effect.

---

## 2. Representation bridges

### Typography -> geometry

- glyph outline -> Bézier/path data;
- path -> sampled points;
- glyph mask -> occupancy field;
- glyph mask -> signed distance field;
- glyph metrics -> layout constraints;
- variable-font axes -> continuous parameter vector;
- word/line structure -> graph or sequence;
- counters/stems/terminals -> semantic regions or anchor points.

Once type becomes geometry or data, it can participate in particles, fields, packing, triangulation, SDF operations, simulations and spatial systems.

### Graphic design -> computation

- modular grid -> coordinate lattice;
- baseline grid -> phase/rhythm system;
- hierarchy -> amplitude/frequency/scale bands;
- margins -> boundary conditions;
- palette -> discrete state mapping;
- crop -> viewport/window function;
- repetition -> tiling/instancing rule;
- identity rules -> parameter constraints;
- editorial sequence -> temporal state machine.

Design becomes executable when its rules are encoded as constraints rather than reproduced as decoration.

### Image -> system

- pixels -> samples;
- luminance -> density/height/velocity;
- edges -> paths/forces;
- optical flow -> vector field;
- segmentation -> region graph;
- color clusters -> palette/state classes;
- frame history -> temporal buffer.

### Simulation -> graphic language

- scalar concentration -> color or type weight;
- vector velocity -> displacement/orientation;
- particle density -> mask or opacity;
- agent trails -> line system;
- collision events -> typographic or color events;
- reaction-diffusion state -> texture/mask/geometry threshold;
- feedback buffer -> memory and visual persistence.

### Interaction -> dynamics

- pointer position -> attractor/repulsor;
- pointer velocity -> energy/intensity;
- acceleration -> impulse;
- touch count -> number of active sources;
- gesture direction -> field orientation;
- dwell time -> accumulation;
- pressure, when available -> local stiffness/scale;
- multitouch distance -> global tension/spacing.

A strong interaction changes internal system behavior. A weak interaction only attaches an effect to the cursor.

---

## 3. Bridge matrix

| From | Shared representation | Operator | Into | Possible result |
|---|---|---|---|---|
| typography | sampled contour points | advect | flow field | letterforms dissolve/rebuild through motion |
| typography | SDF | smooth boolean / warp | shader math | elastic type without losing structural control |
| typography | variable axes | normalize/remap | interaction | touch changes width/weight/optical behavior |
| typography | glyph metrics | quantize | grid system | type controls the modular composition |
| typography | word sequence | phase offset | motion system | semantic rhythm becomes kinetic rhythm |
| grid | cell coordinates | randomize under bounds | generative layout | controlled variation instead of free randomness |
| baseline grid | periodic phase | oscillate | shader field | visual waves locked to typographic rhythm |
| hierarchy | ranked levels | map | motion amplitude | important elements move differently from secondary ones |
| palette | indexed colors | state mapping | simulation | chemical/agent states remain identity-consistent |
| margins | boundary region | clamp / repel | particles | particles respect graphic safe areas |
| poster crop | viewport rule | repeat / scroll | spatial field | composition moves without losing edge tension |
| image | luminance field | threshold | typography | image data controls glyph visibility/weight |
| image | edge map | attract | particles | particles reveal structural contours |
| image | optical flow | advect | glyph/particles | camera movement becomes kinetic typography |
| audio | amplitude bands | remap | variable-font axes | sound drives typographic morphology |
| audio | FFT bins | sample | grid | columns/cells become spectral structure |
| pointer | velocity vector | inject | feedback field | gesture leaves energy rather than a cursor trail |
| touch | positions | multiple source terms | reaction-diffusion | fingers seed evolving chemistry |
| touch | distance/angle | normalize | layout | multitouch changes spacing/tension of a composition |
| particles | density | reconstruct | SDF/mask | particle behavior becomes readable graphic shape |
| particles | velocity | orient | typography fragments | fragments align with local flow |
| simulation | scalar field | threshold | geometry | dynamic contours emerge from physical state |
| simulation | vector field | sample | type deformation | glyph deformation follows systemic motion |
| feedback | previous frame | decay/transform | typography | type gains memory, erosion and temporal residue |
| reaction-diffusion | concentration | mask | type/image | biological pattern grows only in selected forms |
| cellular automata | cell state | palette mapping | identity system | discrete evolution becomes branded visual grammar |
| Voronoi | cells | assign glyph/weight | typography | type becomes territorial/spatial |
| SDF | distance | gradient | normals/flow | shape boundary generates forces and lighting cues |
| mesh | vertices | displace | audio/touch | graphic object becomes responsive spatial material |
| data | normalized values | quantize | design tokens | data changes composition without destroying identity |

The rightmost column is intentionally generic. Use the bridge, then mutate it; do not treat the example as a finished concept.

---

## 4. High-value cross-domain families

### A. Typography x fields

Pipeline:

```text
glyph -> points/SDF -> scalar or vector field -> temporal dynamics -> reconstruction
```

Operators worth exploring:

- flow-field advection;
- curl/noise displacement;
- attraction to stems/counters;
- distance-based stiffness;
- erosion/dilation;
- local phase offsets;
- field-driven orientation;
- reassembly from density.

Design constraints:

- preserve optical margins;
- choose when legibility is required and when it may collapse;
- establish one dominant typographic scale;
- keep deformation amplitude subordinate to a clear identity rule.

### B. Typography x simulation

Pipeline:

```text
glyph mask or SDF
-> initial/boundary condition
-> reaction / diffusion / agents / particles
-> simulation state
-> type or image reconstruction
```

Interesting inversions:

- type is not rendered; it only seeds the simulation;
- type appears only where simulation stabilizes;
- counters act as obstacles;
- letter boundaries emit or absorb particles;
- words are readable only through accumulated history.

### C. Grid x shader

Pipeline:

```text
design grid -> normalized cell coordinates -> procedural operator per cell -> hierarchy constraints
```

Potential operators:

- cell-local rotation;
- phase offsets;
- quantized SDF operations;
- neighborhood coupling;
- cell-specific noise bandwidth;
- controlled cell merging/splitting.

Avoid the generic "shader tiles" look by letting hierarchy and layout determine which cells may mutate.

### D. Variable typography x interaction

Pipeline:

```text
font axis -> normalized parameter -> physical/semantic driver -> temporal filtering
```

Mappings:

- touch speed -> width;
- distance to pointer -> weight;
- dwell -> optical size or custom axis;
- multiple touches -> competing regional axes;
- sound envelope -> slant;
- simulation density -> axis value.

The important design question is whether the mapping expresses something. Do not map every sensor to every axis.

### E. Editorial composition x realtime behavior

Pipeline:

```text
editorial hierarchy -> roles -> motion grammar -> state transitions
```

Examples of translation:

- headline = slow dominant motion;
- secondary text = faster low-amplitude response;
- captions = stable anchors;
- margins = forbidden or dissipative zones;
- page turns = scene/state transitions;
- column relationships = coupled oscillators or linked simulations.

This creates a moving publication system rather than animated decorations.

### F. Feedback x identity

Pipeline:

```text
identity element -> previous-frame buffer -> controlled transform/decay -> reinjection
```

Possible memory behaviors:

- persistence;
- delayed echo;
- erosion;
- recursive scale;
- chromatic separation over time;
- accumulation until threshold;
- reset at semantic/interactive events.

Feedback should encode memory or process, not just produce trails.

### G. Geometry x typography

Pipeline:

```text
glyph/path -> spatial construction -> mesh/curve topology -> shader/simulation
```

Examples:

- paths become ribbons/tubes;
- counters become cavities;
- glyph skeletons become structural graphs;
- letter spacing becomes physical spacing;
- extrusion depth comes from hierarchy or data;
- curvature controls emission or color.

### H. Color theory x generative systems

Pipeline:

```text
palette rule -> state space -> simulation/generative values -> constrained color mapping
```

Prefer:

- role-based palettes;
- luminance hierarchy;
- bounded interpolation;
- perceptually intentional transitions;
- state changes with semantic meaning.

Avoid assigning raw RGB randomness directly to simulation output.

---

## 5. Bridge stacking

A new visual identity usually becomes interesting when several bridges form a chain.

### Two-hop chain

```text
type -> SDF -> deformation field
```

Useful, but often still recognizable as a single technique.

### Three-hop chain

```text
type -> SDF -> reaction-diffusion boundary -> palette states
```

Now typography, simulation and color-system logic are coupled.

### Four-hop chain

```text
editorial grid
-> coordinate lattice
-> glyph placement
-> per-glyph variable-font axis
-> touch-driven vector field
-> feedback memory
```

This is no longer "a typography effect". It is a system with several interacting grammars.

For DC//LAB, aim for **2-4 meaningful bridges**. More is not automatically better. Every bridge must change the behavior or identity of the work.

---

## 6. Mutation operators

After making a valid chain, mutate it deliberately.

### Translate

Keep the rule, change the representation.

```text
particle density -> replace with SDF distance
```

### Transfer

Take a rule from one domain and apply it to another.

```text
baseline rhythm -> phase rhythm in a shader
```

### Invert

Swap source and target.

```text
type seeds particles
becomes
particles reconstruct type
```

### Couple

Make two previously independent parameters affect each other.

```text
glyph width changes field strength; field strength also changes glyph width
```

### Constrain

Add a severe design rule.

```text
full spectrum -> two colors only
free layout -> fixed 6-column grid
```

### Temporalize

Give a static relation memory or evolution.

```text
grid deformation -> feedback + decay
```

### Spatialize

Turn a flat parameter into local variation.

```text
one global font weight -> per-region weight field
```

### Discretize

Replace continuous behavior with states.

```text
smooth deformation -> 5 quantized states with hysteresis
```

### Continuous-ize

Replace discrete states with interpolation.

```text
three poster layouts -> continuous morphing layout manifold
```

### Remove the obvious carrier

Let the original source become invisible but still govern the result.

```text
glyph mask controls simulation, but glyph itself is never directly drawn
```

This is one of the strongest ways to escape literal visual references.

---

## 7. Interaction bridge rules

For touch-first DC//LAB sketches, prefer interaction that behaves like physics or authorship.

Good patterns:

- touch injects material into a field;
- gesture changes local boundary conditions;
- velocity creates momentum;
- dwell accumulates change;
- two touches establish a region, tension or axis;
- touch can permanently alter system memory until decay/reset.

Weak patterns:

- circle follows cursor;
- uniform `effect_strength` around pointer with no system consequence;
- interaction merely reveals a pre-existing filter;
- every parameter responds to the same distance function.

---

## 8. Cross-domain questions to ask before implementation

1. What is the carrier of identity?
2. What representation makes it computationally interesting?
3. Which operator comes from another domain?
4. What second operator makes the first one less obvious?
5. What is persistent through time?
6. What is allowed to vary, and what must remain fixed?
7. Which design rule protects hierarchy/composition?
8. Does interaction modify the system or merely decorate it?
9. Can the idea survive with a very limited palette?
10. If the source references disappeared, would the concept still have its own logic?
11. Can the same system produce a family of outputs without losing identity?
12. What is the cheapest Godot-native representation that preserves the idea?

Then use `IDEA_ENGINE.md` to generate and mutate candidate concepts.