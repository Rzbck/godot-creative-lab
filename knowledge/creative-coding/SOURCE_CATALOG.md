# Creative Coding Source Catalog

Curated on **2026-09-24**. This is a research index, not a vendored dependency list.

Legend: **A** primary/canonical, **B** curated technical library, **C** inspiration/community.

## 1. Godot / direct implementation references

### A — Godot Shading Reference
- URL: https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/
- Tags: `godot`, `shader-math`, `canvas-item`, `spatial`, `particles`
- Why: authoritative entry point for Godot's shader types and built-ins.
- DC//LAB use: first stop when translating GLSL ideas into Godot.

### A — Converting GLSL to Godot shaders
- URL: https://docs.godotengine.org/en/stable/tutorials/shaders/converting_glsl_to_godot_shaders.html
- Tags: `godot`, `glsl-porting`, `shadertoy`, `book-of-shaders`
- Why: specifically covers moving GLSL/Shadertoy-style code into Godot's combined shader model.
- DC//LAB use: porting checklist before adapting external fragment shader concepts.

### A — Godot compute shaders
- URL: https://docs.godotengine.org/en/stable/tutorials/shaders/compute_shaders.html
- Tags: `godot`, `compute`, `simulation`, `particles`, `gpu`
- Why: canonical route for GPU general-purpose workloads in Godot.
- DC//LAB use: future high-count particles, reaction-diffusion, cellular systems, fluid-like state updates.

### A — Godot screen-reading shaders
- URL: https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html
- Tags: `godot`, `feedback`, `post`, `screen-texture`, `image-feedback`
- Why: documents the back-buffer/screen-texture pattern needed for feedback and post FX.
- DC//LAB use: trails, recursive feedback, displacement, datamosh-like experiments.

### C — Godot Shaders
- URL: https://godotshaders.com/
- Tags: `godot`, `shader-gallery`, `community`, `effects`
- Why: large community-driven Godot shader library.
- DC//LAB use: discover engine-native techniques and compare implementation patterns.
- License note: verify the license on each individual shader before reuse.

## 2. Shader fundamentals and reusable math

### A — The Book of Shaders
- URL: https://thebookofshaders.com/
- GitHub: https://github.com/patriciogonzalezvivo/thebookofshaders
- Tags: `glsl`, `shader-math`, `shaping`, `noise`, `patterns`, `fbm`, `simulation`
- Why: foundational step-by-step shader reference covering shapes, matrices, patterns, random, noise, cellular noise, fBm, image processing and simulations.
- DC//LAB use: canonical conceptual source for 2D procedural shader construction.
- License note: verify upstream terms before copying code; prefer reimplementation from the explained technique.

### B — LYGIA Shader Library
- URL: https://github.com/patriciogonzalezvivo/lygia
- Tags: `glsl`, `hlsl`, `wgsl`, `sdf`, `color`, `noise`, `filters`, `generative`, `shader-library`
- Why: granular multi-language shader function library organized into math, space, color, animation, generative, SDF, drawing, sampling and filtering.
- DC//LAB use: vocabulary/reference for reusable shader building blocks and cross-language comparisons.
- License note: **important** — upstream uses Prosperity/Patron licensing; do not import code into commercial-capable DC//LAB without explicit license review.

### B — glslify
- URL: https://github.com/glslify/glslify
- Tags: `glsl`, `modules`, `shader-library`, `noise`, `easing`, `raymarching`
- Why: established modular GLSL ecosystem and useful map of community shader components.
- DC//LAB use: find known reusable concepts/functions, then port intentionally to Godot.
- License: MIT for glslify itself; modules have their own licenses.

### B — Ashima WebGL Noise
- URL: https://github.com/ashima/webgl-noise
- Tags: `glsl`, `simplex`, `noise`, `procedural`
- Why: classic textureless procedural noise implementations widely referenced in shader work.
- DC//LAB use: compare noise families and performance/visual characteristics.
- License note: inspect repository license before embedding exact implementations.

### A — Inigo Quilez articles
- URL: https://iquilezles.org/articles/
- Tags: `sdf`, `raymarching`, `procedural`, `fractal`, `distance-fields`, `math`
- Why: one of the canonical bodies of work for distance fields, ray marching, procedural geometry and shader math.
- DC//LAB use: SDF scenes, repetition, smooth combinations, palette/math techniques, compact procedural worlds.
- Research note: parts of the site block automated crawling; PDFs and indexed pages remain useful primary references.

## 3. Modern GPU / WebGPU directions

### A — Three.js TSL Guide
- URL: https://threejs.org/tsl/
- Tags: `webgpu`, `tsl`, `wgsl`, `nodes`, `compute`, `modern-gpu`
- Why: current Three.js shader/node approach targeting WebGPU while remaining backend-aware.
- DC//LAB use: track modern GPU composition patterns and compute-oriented ideas that may later map to Godot RenderingDevice/compute.

### A — Three.js WebGPU examples
- URL: https://threejs.org/examples/?q=webgpu
- Tags: `webgpu`, `instancing`, `particles`, `compute`, `rendering`
- Why: practical current examples of modern GPU rendering and TSL workflows.
- DC//LAB use: concept mining for GPU instancing, particles, post and compute.

### A — NVIDIA GPU Gems: Fast Fluid Dynamics Simulation on the GPU
- URL: https://developer.nvidia.com/gpugems/gpugems/part-vi-beyond-triangles/chapter-38-fast-fluid-dynamics-simulation-gpu
- Tags: `fluids`, `simulation`, `gpu`, `feedback`, `advection`
- Why: foundational practical GPU fluid simulation reference.
- DC//LAB use: future interactive dye/smoke/velocity-field sketches.

### A — NVIDIA GPU Gems 3: Real-Time 3D Fluids
- URL: https://developer.nvidia.com/gpugems/gpugems3/part-v-physics-simulation/chapter-30-real-time-simulation-and-rendering-3d-fluids
- Tags: `fluids`, `volume`, `raymarching`, `simulation`, `gpu`
- Why: extends fluid ideas into 3D simulation and volume rendering.
- DC//LAB use: long-term volumetric/live installation research.

## 4. Generative systems / computational design

### A — The Nature of Code
- URL: https://natureofcode.com/
- GitHub: https://github.com/shiffman/NatureOfCode
- Tags: `particles`, `forces`, `oscillation`, `agents`, `cellular-automata`, `fractals`, `evolution`
- Why: canonical creative-coding treatment of motion systems, particles, autonomous agents and emergent systems.
- DC//LAB use: source for sketches whose core is behavior/simulation rather than fragment-shader texture.

### A — Generative Design code package
- GitHub: https://github.com/generative-design/Code-Package-p5.js
- Tags: `generative-design`, `typography`, `grids`, `patterns`, `interaction`, `p5js`
- Why: code package from the Generative Design book by Groß, Bohnacker, Laub and Lazzeroni.
- DC//LAB use: composition systems, generative typography, grid logic, parametric visual design.
- License note: verify the repository/file license before reuse; use primarily as design/algorithm reference.

### A — Red Blob Games: Noise Functions and Map Generation
- URL: https://www.redblobgames.com/articles/noise/introduction.html
- Tags: `noise`, `procedural`, `signal-processing`, `terrain`, `fbm`
- Why: unusually clear interactive explanation of frequency, amplitude and combining noise for procedural structure.
- DC//LAB use: better-controlled noise instead of arbitrary "add Perlin" usage.

### A — Red Blob Games: Terrain from Noise
- URL: https://www.redblobgames.com/maps/terrain-from-noise/
- Tags: `noise`, `procedural-geometry`, `maps`, `terrain`
- Why: concrete example of turning layered noise into structured procedural worlds.
- DC//LAB use: procedural landscapes, masks, regions, layered visual fields.

## 5. Current curated/open collections

### B — Radiant
- URL: https://github.com/pbakaus/radiant
- Site: https://radiant-shaders.com/
- Tags: `shader-gallery`, `particles`, `physics`, `noise`, `organic`, `geometric`, `interactive`
- Why: current open-source collection (2025+) of self-contained Canvas/WebGL visual effects categorized by visual style; includes mouse/touch interaction and tunable parameters.
- DC//LAB use: strong source for contemporary visual families and interaction conventions.
- License: MIT at repository level at time of research; re-check before importing.

### B — Twigl
- URL: https://github.com/doxas/twigl
- Site: https://twigl.app/
- Tags: `glsl`, `live-coding`, `code-golf`, `feedback`, `sound-shader`
- Why: live one-tweet shader environment with backbuffer and sound modes.
- DC//LAB use: compact shader idioms, feedback concepts, live-coding aesthetics.
- License: MIT for Twigl application; individual shared shader authorship still matters.

### B — VertexShaderArt
- URL: https://github.com/greggman/vertexshaderart
- Site: https://vertexshaderart.com/
- Tags: `vertex-shader`, `procedural-geometry`, `particles`, `gpu-art`
- Why: gallery/editor centered on generating art primarily through vertex shaders and vertex IDs.
- DC//LAB use: move beyond fragment-only thinking; procedural point/line/mesh sketches.

## 6. Inspiration / community discovery

### C — Shadertoy
- URL: https://www.shadertoy.com/
- Tags: `glsl`, `raymarching`, `sdf`, `feedback`, `procedural`, `community`
- Why: huge shader-art ecosystem and de facto reference culture for compact real-time graphics.
- DC//LAB use: visual research and technique discovery.
- License note: **do not assume reuse rights**. Treat each shader as reference unless its author/license explicitly allows reuse.

### C — GLSL Sandbox
- URL: https://glslsandbox.com/
- Tags: `glsl`, `fragment-shader`, `gallery`, `legacy-reference`
- Why: historically important fragment shader gallery; currently in maintenance/read-only mode.
- DC//LAB use: archive of older shader idioms and minimalist procedural studies.

### C — OpenProcessing
- URL: https://openprocessing.org/
- Tags: `p5js`, `generative-art`, `particles`, `interactive`, `community`
- Why: very large creative coding community with generative art, particle systems and interactive sketches.
- DC//LAB use: broad visual discovery across styles beyond shader-only work.
- License note: user-contributed works vary; inspect author permissions before reuse.

### A/B — p5.js shader tutorial and examples
- Tutorial: https://p5js.org/tutorials/intro-to-shaders/
- Examples: https://p5js.org/examples/
- Tags: `p5js`, `glsl`, `shader-learning`, `interaction`
- Why: clear shader introduction plus concise executable examples.
- DC//LAB use: rapid conceptual prototypes and accessible explanations before a Godot port.

## Research gaps to expand next

The catalog should next grow in these directions:

- kinetic typography / MSDF and signed-distance text;
- reaction-diffusion and Gray-Scott references;
- Physarum/slime-mold simulation;
- boids and GPU flocking implementations;
- Voronoi/Delaunay and blue-noise sampling;
- audio-reactive FFT/onset visual systems;
- optical flow / camera interaction;
- feedback and video-synthesis techniques;
- demoscene archives and production breakdowns;
- touch-first interactive installation references;
- realtime projection / VJ compositing architectures.
