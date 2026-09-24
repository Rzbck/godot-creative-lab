# DC//LAB Idea Engine

This document turns the knowledge library into a **concept-generation system**.

The objective is not random novelty. It is to create original visual identities by combining principles from different domains, then mutating the combination until the system has its own internal logic.

A useful concept should be able to answer:

- why these elements belong together;
- why the interaction behaves this way;
- why the composition remains coherent while changing;
- what makes the system recognizably itself across many states.

---

## 1. Concept genotype

Treat every candidate idea as a compact genotype.

```text
CARRIER
+ REPRESENTATION
+ OPERATOR A
+ OPERATOR B
+ DRIVER
+ TEMPORAL MODEL
+ DESIGN SYSTEM
+ CONSTRAINT
+ OUTPUT LANGUAGE
```

Example:

```text
word
+ signed distance field
+ reaction-diffusion boundary
+ feedback erosion
+ touch velocity
+ accumulated memory
+ asymmetric 5-column poster grid
+ black + one fluorescent accent
+ fullscreen kinetic identity
```

This is not yet an artwork. It is a structured hypothesis that can be mutated.

---

## 2. Multiplier decks

Use the following decks as independent dimensions. A concept becomes less predictable when choices come from **distant decks** rather than from one stylistic family.

### Carrier deck

- glyph;
- word;
- sentence;
- typographic block;
- modular grid;
- baseline grid;
- line;
- point cloud;
- particle population;
- image;
- silhouette;
- color field;
- mesh;
- data stream;
- spatial surface;
- empty/negative space.

### Representation deck

- raster mask;
- vector path;
- sampled contour points;
- SDF/MSDF;
- scalar field;
- vector field;
- density map;
- signed velocity field;
- graph;
- lattice;
- Voronoi/Delaunay structure;
- particle cloud;
- mesh vertices;
- texture history buffer;
- normalized parameter vector.

### Operator deck

- sample;
- quantize;
- threshold;
- smoothstep/remap;
- warp;
- fold;
- repeat;
- mirror;
- rotate locally;
- advect;
- diffuse;
- erode;
- dilate;
- sort;
- pack;
- interpolate;
- accumulate;
- decay;
- feedback;
- displace;
- segment;
- triangulate;
- phase-shift;
- couple;
- mask;
- reconstruct from density;
- change topology;
- change coordinate space.

### Driver deck

- absolute time;
- oscillator phase;
- pointer position;
- pointer velocity;
- pointer acceleration;
- touch count;
- multitouch span/angle;
- dwell time;
- audio amplitude;
- FFT band;
- glyph metric;
- text length;
- local curvature;
- simulation concentration;
- particle density;
- noise field;
- frame history;
- external data.

### Temporal deck

- stateless;
- periodic;
- quasi-periodic;
- eased transition;
- spring;
- inertia;
- hysteresis;
- accumulation;
- decay;
- delayed response;
- feedback;
- diffusion;
- autonomous agents;
- reaction system;
- cellular state machine.

### Design-system deck

- Swiss/modular grid;
- asymmetric editorial grid;
- baseline rhythm;
- oversized poster crop;
- strict centered composition;
- edge tension;
- controlled negative space;
- hierarchical scale bands;
- one-family variable typography;
- duotone identity;
- monochrome + one accent;
- role-based palette;
- repeated identity token;
- constrained anti-grid;
- dense/sparse zoning.

### Constraint deck

- two colors only;
- one typeface only;
- one continuous axis only;
- no explicit glyph rendering;
- no noise;
- no particles;
- no smooth interpolation;
- fixed margins;
- fixed logical grid;
- preserve counters;
- preserve baseline;
- interaction may only add energy, never directly set position;
- system must reconstruct itself after disturbance;
- every element must derive from one field;
- maximum two exposed artistic parameters.

### Output deck

- kinetic poster;
- generative identity;
- interactive type field;
- abstract shader surface;
- particle typography;
- procedural spatial object;
- live installation surface;
- motion system;
- audiovisual field;
- data-driven graphic system.

---

## 3. The distance rule

Do not choose every component from the same neighborhood.

Weak combination:

```text
GLSL noise + distortion + chromatic aberration + mouse radius
```

Everything belongs to the same visual-effect family, so the result is likely to feel generic.

Stronger combination:

```text
editorial baseline grid
+ glyph metrics
+ vector-field advection
+ hysteresis
+ two-color print constraint
```

These concepts originate in different disciplines and must negotiate with one another. That negotiation is where a new identity can emerge.

For important new work, require at least **three domains**, for example:

```text
typography + simulation + editorial design
```

or:

```text
color theory + geometry + interaction + feedback
```

---

## 4. Mutation passes

Never implement the first coherent combination immediately. Run several deliberate mutations.

### Pass 1 — Representation mutation

Change what the carrier *is* computationally.

```text
glyph texture -> glyph SDF
```

or:

```text
grid cells -> graph nodes
```

This usually changes the available algorithms more deeply than adding another effect.

### Pass 2 — Domain transfer

Take a rule from an unrelated domain.

Examples:

- typographic leading controls vertical wave period;
- editorial hierarchy determines simulation time scale;
- kerning distances become particle spring rest lengths;
- palette roles become cellular automata states;
- poster margins become repulsive boundaries.

### Pass 3 — Inversion

Reverse causality.

```text
touch deforms type
->
type shape deforms the touch-generated field
```

```text
simulation reveals text
->
text defines the simulation's chemistry
```

### Pass 4 — Coupling

Create a feedback relationship between two systems.

```text
field changes glyph width
and
glyph width changes field strength
```

Coupling is a major novelty multiplier because the result cannot be described as a one-way filter chain anymore.

### Pass 5 — Constraint mutation

Remove freedom.

Examples:

- reduce a rainbow simulation to two role-based colors;
- remove direct text rendering;
- force all deformation to preserve baseline;
- allow motion only inside selected grid zones;
- quantize continuous behavior into four states.

Strong constraints often reveal the actual concept.

### Pass 6 — Temporal mutation

Ask what persists.

Add or remove:

- memory;
- decay;
- hysteresis;
- accumulation;
- delayed response;
- irreversible marks;
- self-repair;
- state transitions.

### Pass 7 — Interaction mutation

Replace direct control with systemic influence.

```text
pointer sets deformation
->
pointer injects velocity into a field that later deforms the composition
```

### Pass 8 — Carrier removal

Hide the obvious source.

If the concept begins with typography, test a version where letters are never directly rendered. Let glyph geometry govern forces, boundaries, density or timing instead.

This pass is particularly useful for escaping derivative visual resemblance.

---

## 5. Identity construction

A visual identity is stronger than an effect when several rules reinforce each other.

Require at least three persistent identity anchors.

Possible anchors:

- one coordinate/grid logic;
- one characteristic deformation law;
- one temporal behavior;
- one typographic relationship;
- one palette logic;
- one interaction law;
- one recurring spatial motif;
- one reconstruction/destruction behavior.

Example:

```text
ANCHOR 1: everything aligns to a 7-column asymmetric grid
ANCHOR 2: touch injects rotational energy, never direct displacement
ANCHOR 3: every disturbed form slowly reconstructs from its SDF boundary
ANCHOR 4: only black, warm white and one state-dependent accent exist
```

Those rules can produce many frames while remaining recognizably one system.

---

## 6. Concept collision protocol

When actively generating candidates for a new sketch, use this sequence.

### Step A — Pick one intentional seed

Choose a question, not an effect.

Examples:

- Can typography behave like a material that remembers touch?
- Can a grid become a force field rather than a layout scaffold?
- Can legibility emerge from simulation density instead of direct drawing?
- Can negative space be the active simulated material?

### Step B — Select three distant domains

Example:

```text
type anatomy
+ reaction-diffusion
+ Swiss poster hierarchy
```

### Step C — Find one shared representation per crossing

```text
glyph -> SDF
SDF -> simulation boundary
simulation concentration -> palette/hierarchy state
```

### Step D — Add one non-obvious temporal model

Examples:

- hysteresis;
- accumulated memory;
- self-repair;
- delayed coupling;
- discrete phase changes.

### Step E — Add one severe design constraint

Examples:

- two-color only;
- fixed margins;
- never render the original glyph directly;
- only one family of curves;
- every local deformation must conserve total area approximately.

### Step F — Mutate at least three times

Do not keep the first version unchanged.

### Step G — Name the behavior, not the effect

Bad concept description:

```text
cool liquid chromatic text shader
```

Better concept description:

```text
a typographic boundary system that stores gesture energy, erodes into a reaction field, then reconstructs according to a fixed editorial hierarchy
```

The second description tells us what the work *does*.

---

## 7. Candidate filter

Before implementation, evaluate a concept on these axes from 0 to 3.

| Axis | 0 | 1 | 2 | 3 |
|---|---|---|---|---|
| Cross-domain depth | one effect family | superficial combination | meaningful bridge | multiple coupled bridges |
| Identity coherence | arbitrary | partial | recognizable rules | strong family-generating system |
| Originality distance | obvious reference | familiar remix | transformed sources | source appearance no longer dominates |
| Interaction necessity | decorative | optional | affects behavior | fundamental to system evolution |
| Temporal depth | static | simple loop | meaningful dynamics | memory/emergence/state change |
| Design control | accidental | loosely composed | clear hierarchy | rigorous adaptable system |
| Godot feasibility | unclear | expensive/risky | plausible | direct efficient representation |
| Live robustness | fragile | many dependencies | manageable | deterministic/persistent/live-friendly |

This is not a beauty score. It is a way to reject shallow or technically incoherent concepts before spending implementation time.

A candidate should normally have no `0`, and should be strong in **cross-domain depth**, **identity coherence** and **design control**.

---

## 8. Anti-derivative checks

Reject or mutate a concept when:

- one reference supplies both the composition and visual treatment;
- the concept is described mainly by an existing artist/studio/site name;
- changing the palette makes it indistinguishable from a known tutorial;
- the core is a stock distortion/noise/chromatic effect;
- interaction is just a radial mask around the cursor;
- typography is used only because text looks fashionable;
- simulation has no relationship to the composition;
- the grid is decorative rather than structural;
- too many independent effects have no common rule.

Prefer extracting principles from several sources, then implementing an original chain from first principles in Godot.

---

## 9. Seed patterns for future research

These are **not approved sketches**. They are examples of how to formulate research seeds for the engine.

### Self-healing typography

```text
glyph SDF
+ touch-injected erosion
+ reaction/diffusion-like recovery
+ fixed baseline grid
+ recovery hysteresis
```

Question: can the identity be the way typography repairs itself rather than the way it deforms?

### Typographic weather

```text
glyph metrics
+ vector field
+ particle density
+ strict editorial hierarchy
+ slow accumulated climate state
```

Question: can type metrics generate a climate that later reshapes the composition?

### Grid organism

```text
modular grid
+ neighborhood coupling
+ cellular states
+ typographic scale hierarchy
+ multitouch boundary changes
```

Question: can a graphic grid behave like an organism while staying recognizably designed?

### Latent letterfield

```text
glyph contours never drawn
+ SDF gradients become forces
+ particles reveal density
+ feedback creates memory
+ duotone print constraint
```

Question: can a viewer perceive typography without ever seeing a rendered letter?

### Elastic editorial system

```text
columns + baseline grid
+ spring constraints
+ variable-font axes
+ gesture velocity
+ quantized layout states
```

Question: can editorial hierarchy deform physically without becoming chaotic?

### Semantic turbulence

```text
word lengths / letter classes
+ field parameters
+ fluid-like advection
+ restrained poster composition
+ slow decay
```

Question: can textual structure influence motion without visualizing language literally?

---

## 10. DC//LAB implementation translation

Once a concept survives the filter, translate it into the runtime contract.

Record:

```text
logical design space
render representation
simulation authority
live-sync state
artistic parameters
interaction inputs
persistent parameters
GPU/CPU budget
reset/detach behavior
PROGRAM composition rules
```

Prefer the cheapest representation that preserves the concept.

Examples:

- use one SDF field instead of thousands of independent glyph objects when possible;
- use a texture feedback simulation when state is naturally per-pixel;
- use particles/points when topology is not required;
- use explicit geometry only when shape structure is central;
- expose artistic decisions, not implementation noise, as parameters.

A concept is ready for implementation when its **identity rules**, **cross-domain bridges** and **runtime representation** are all clear.