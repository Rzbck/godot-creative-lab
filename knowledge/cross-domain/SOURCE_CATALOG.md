# Cross-Domain Source Catalog

Curated on **2026-09-24** for sources that are useful specifically because they **cross disciplines**: typography into geometry, graphic design into programmable systems, interaction into shader behavior, simulation into visual identity, or static composition into realtime systems.

Legend: **A** primary/canonical, **B** professional/curated practice or focused technical resource, **C** inspiration/tutorial/community. Tier does not imply permission to copy code or assets.

Use these sources to extract mechanisms and principles. Combine several independent sources before defining a DC//LAB concept.

## 1. Design systems -> code systems

### A/B — Coding Systems
- URL: https://codingsystems.info/
- People: Tim Rodenbröker + Martin Lorenz.
- Tags: `generative-design`, `visual-systems`, `identity`, `creative-coding`, `tools`
- Why: explicitly joins creative coding with flexible visual systems; treats code as a way to build open visual systems rather than isolated effects.
- Bridge value: **graphic identity rules -> executable generative system**.
- DC//LAB question: which identity constraints should become code-level invariants rather than fixed layouts?

### A/B — Flexible Visual Systems
- URL: https://flexiblevisualsystems.info/
- Tags: `visual-systems`, `identity`, `grid`, `flexibility`, `design-method`
- Why: Martin Lorenz's long-running research into visual systems that remain coherent across changing formats and states.
- Bridge value: **graphic design systems -> parameterized/adaptive identity**.
- DC//LAB question: how can a live generative sketch vary continuously while remaining recognizably the same system?

### B — Tim Rodenbröker / Creative Coding practice
- URL: https://timrodenbroeker.de/
- Tags: `creative-coding`, `graphic-design`, `generative-branding`, `education`
- Why: practice and teaching focused on the meeting point of communication design and creative coding.
- Bridge value: **designer thinking -> computational construction**.

### A — Generative Design / Code Package for p5.js
- URL: https://github.com/generative-design/Code-Package-p5.js
- Book overview: https://archive.p5js.org/books/
- Tags: `generative-design`, `typography`, `grids`, `patterns`, `interaction`, `p5js`
- Why: organizes generative design around visual categories such as color, shape and typography while keeping parameters and interaction central.
- Bridge value: **traditional visual-design material -> code-controlled variation**.
- License note: repository reports Apache-2.0 at research time; re-check exact files before reuse.

### A — Code as Creative Medium — exercise repository
- URL: https://github.com/golanlevin/exercises
- Tags: `typography`, `curves`, `geometry`, `image`, `simulation`, `sound`, `interaction`
- Why: unusually broad exercise set where one computational vocabulary moves through graphic elements, typography, curves, geometry, image processing, simulation and sound.
- Bridge value: **algorithmic primitive -> many artistic domains**.
- DC//LAB use: deliberately take an operator from one chapter/family and apply it to a carrier from another.

## 2. Typography -> geometry / data / simulation

### A — p5.Font `textToPoints()` / `textToPaths()`
- URL: https://beta.p5js.org/reference/p5/p5.font/
- Tags: `typography`, `glyph-outlines`, `points`, `paths`, `geometry`
- Why: demonstrates the crucial representation jump from text as rendered content to text as manipulable points and path commands.
- Bridge value: **glyph -> geometry -> particles/fields/meshes/simulation**.
- DC//LAB use: conceptual reference even when implementation uses Godot-native font/SDF resources instead.

### B — Generative Typography with Processing — CreativeApplications.Net
- URL: https://www.creativeapplications.net/tutorial/generative-typography-processing-tutorial/
- Tags: `typography`, `flow-field`, `reaction-diffusion`, `voronoi`, `3d`, `particles`
- Why: starts repeatedly from typographic forms, then moves into aggregate drawing, particles, flow fields, reaction-diffusion, Voronoi and 3D geometry.
- Bridge value: **type -> mask/geometry -> unrelated generative algorithms**.
- Research lesson: the typography can be a seed or boundary condition rather than the final rendered object.
- License note: tutorial/project code is historical; verify exact repository/dependency licenses before any reuse.

### B — Space Type Generator
- URL: https://spacetypegenerator.com/
- Author: Kiel Mutschelknaus.
- Tags: `kinetic-type`, `spatial-type`, `generative-type`, `layout`, `motion`
- Why: a family of typographic generators that reinterpret type through cylinders, fields, coils, ribbons, cascades, layers and other spatial constructions.
- Bridge value: **typesetting -> spatial/topological system**.
- DC//LAB use: mine transformation categories, not surface styling.

### A/B — Axis-Praxis
- URL: https://www.axis-praxis.org/
- Playground: https://www.axis-praxis.org/playground/
- Tags: `variable-fonts`, `axes`, `animation`, `responsive-type`, `interaction`
- Why: exposes variable-font axes as continuous controls, including animated axes and fit-to-width experiments.
- Bridge value: **font design space -> continuous realtime parameter space**.
- DC//LAB use: think of `wght`, `wdth`, `opsz`, `slnt` or custom axes as artistic uniforms/signals rather than static font choices.

### A/B — DrawBot
- URL: https://www.drawbot.com/
- Variable-font animation discussion: https://forum.drawbot.com/topic/50/tutorial-request-how-to-animate-a-variable-font
- Tags: `typography`, `variable-fonts`, `drawing`, `animation`, `code`
- Why: type/design-oriented scripting environment where typographic values, vector drawing and frame-based animation share one programmable space.
- Bridge value: **type design practice -> procedural/time-based graphics**.

### A — OpenType Font Variations
- URL: https://learn.microsoft.com/en-us/typography/opentype/spec/otvaroverview
- Tags: `variable-fonts`, `interpolation`, `font-engineering`, `axes`
- Why: canonical technical model behind continuous typographic design spaces.
- Bridge value: **designed masters -> interpolated multidimensional state space**.

### A/B — msdfgen
- URL: https://github.com/Chlumsky/msdfgen
- Tags: `typography`, `msdf`, `sdf`, `gpu`, `distance-fields`
- Why: core reference for turning vector shape boundaries into distance-field representations suitable for scalable realtime rendering.
- Bridge value: **font outline -> distance field -> shader mathematics**.
- License note: verify current upstream license before incorporating code/tools into a pipeline.

## 3. Typography -> shaders / realtime rendering

### B/C — Codrops: Animating Letters with Shaders
- URL: https://tympanus.net/codrops/2025/03/24/animating-letters-with-shaders-interactive-text-effect-with-three-js-glsl/
- Tags: `typography`, `glsl`, `interaction`, `displacement`, `threejs`
- Why: explicit practical chain from letters to custom shader displacement plus raycast interaction.
- Bridge value: **type surface -> GLSL material -> interactive deformation**.
- DC//LAB use: study the chain and interaction architecture; reimplement in Godot rather than copying a demo.

### B/C — Codrops: Kinetic Typography with Three.js
- URL: https://tympanus.net/codrops/2020/06/02/kinetic-typography-with-three-js/
- Tags: `typography`, `3d`, `glsl`, `mesh`, `kinetic-type`
- Why: uses text as a texture/material on geometry and manipulates it through shaders.
- Bridge value: **2D type -> 3D surface -> shader-driven motion**.

### B/C — Codrops: Circular 3D text + shaders
- URL: https://tympanus.net/codrops/2025/02/03/building-an-on-scroll-3d-circle-text-animation-with-three-js-and-shaders/
- Tags: `typography`, `msdf`, `3d`, `scroll`, `distortion`
- Why: demonstrates spatial text placement plus shader distortion driven by interaction speed.
- Bridge value: **typographic layout -> spatial geometry -> input-derived deformation**.

## 4. Realtime node systems -> portable computational ideas

### A — TouchDesigner Text TOP
- URL: https://docs.derivative.ca/Text_TOP
- Tags: `typography`, `realtime`, `texture`, `unicode`, `node-system`
- Why: canonical example of converting text into a realtime image/texture stream that can then enter compositing, feedback and GLSL networks.
- Bridge value: **text -> texture signal -> realtime processing graph**.

### A — TouchDesigner GLSL TOP
- URL: https://docs.derivative.ca/Write_a_GLSL_TOP
- Tags: `glsl`, `texture-processing`, `realtime`, `node-system`
- Why: clear model for treating a shader as a per-pixel operation inside a larger realtime signal graph.
- Bridge value: **node graph -> shader operator -> composable visual system**.

### A — TouchDesigner Feedback TOP
- URL: https://docs.derivative.ca/Feedback_TOP
- Tags: `feedback`, `temporal-memory`, `texture`, `realtime`
- Why: explicit previous-frame feedback model.
- Bridge value: **image processing -> memory/stateful system**.
- DC//LAB use: reason about feedback as state and memory, then implement with Godot viewport/texture or compute patterns where appropriate.

### C — TouchDesigner tutorial: kinetic typography + GLSL + feedback
- URL: https://www.youtube.com/watch?v=uk-GVKMTk9Y
- Tags: `typography`, `glsl`, `feedback`, `grid`, `procedural`, `touchdesigner`
- Why: combines text sources, procedural timing, feedback trails and grid-based GLSL processing in one network.
- Bridge value: **typography + temporal logic + feedback + shader grid**.
- Tier note: tutorial/community source; use for pattern discovery, not authority.

## 5. Shader mathematics -> general visual grammar

### A — The Book of Shaders
- URL: https://thebookofshaders.com/
- Tags: `glsl`, `shaping`, `color`, `patterns`, `noise`, `matrices`, `simulation`
- Why: progression from shaping functions and coordinate transforms into patterns, noise, image processing and simulation.
- Bridge value: **mathematical operator -> reusable visual transformation**.
- DC//LAB use: treat chapters as verbs that can operate on type, grids, masks, fields and simulations.

### B — LYGIA Shader Library
- URL: https://github.com/patriciogonzalezvivo/lygia
- Tags: `shader-grammar`, `space`, `color`, `sdf`, `distort`, `simulate`, `filters`
- Why: organizes shader knowledge into reusable conceptual families across languages.
- Bridge value: **technical shader taxonomy -> vocabulary of cross-domain operators**.
- License note: Prosperity/Patron licensing was recorded in the existing creative-coding catalog; do not vendor code without explicit review.

## 6. Simulation -> design material

### A — The Nature of Code
- URL: https://natureofcode.com/
- Tags: `forces`, `particles`, `agents`, `oscillation`, `cellular-automata`, `evolution`
- Why: translates physical/biological/system concepts into programmable visual behavior.
- Bridge value: **behavior model -> visual composition material**.

### B/C — TouchDesigner reaction-diffusion recipe
- URL: https://yuazi.github.io/touchdesigner/06_recipes_and_projects/y-3/reaction-diffusion
- Tags: `reaction-diffusion`, `glsl`, `feedback`, `simulation`, `texture`
- Why: makes the Gray-Scott feedback structure explicit as texture state updated by GLSL.
- Bridge value: **scientific simulation -> realtime texture grammar**.
- DC//LAB use: useful for understanding state representation and how masks/type could become initial or boundary conditions.

### B/C — Advanced Generative Systems in TOPs
- URL: https://joemighty.github.io/CreativeCoding/touchdesigner/expert/06-generative-systems/
- Tags: `reaction-diffusion`, `cellular-automata`, `physarum`, `fluids`, `glsl`, `feedback`
- Why: groups several generative simulations around the same iterative texture-feedback architecture.
- Bridge value: **many simulations -> one reusable computational pattern**.

## 7. Experimental computational typography / future directions

### A/B — MIT Media Lab: Tomorrow's Typography
- URL: https://www.media.mit.edu/projects/tomorrow-s-typography/overview/
- Tags: `computational-typography`, `interaction`, `pose`, `generative-ai`, `experimental-type`
- Why: explores new modes for creating and manipulating typographic form using computational interaction techniques.
- Bridge value: **type design -> new input/interaction modalities**.
- DC//LAB use: broadens the question beyond mouse-driven deformation toward alternate ways of authoring type in realtime.

## 8. Professional generative / dynamic identity references already in design library

These remain important companions and do not need duplication of all their material here:

- onformative — https://onformative.com/
- FIELD — https://field.io/
- Studio Dumbar — https://studiodumbar.com/work
- DIA — https://dia.tv/
- DEMO Festival — https://demofestival.com/

Use them to study how computational behavior becomes a coherent public-facing identity, not merely a technical demo.

## Research extraction template

When adding a new cross-domain source, record:

```text
SOURCE:
PRIMARY DOMAINS:
REPRESENTATION CHANGE:
TRANSFERABLE OPERATOR:
POSSIBLE DRIVERS:
DESIGN CONSTRAINTS:
WHAT NOT TO COPY:
POSSIBLE GODOT REPRESENTATION:
LICENSE / PROVENANCE NOTE:
```

The source earns its place here when it teaches a transferable bridge, not merely because its output looks good.