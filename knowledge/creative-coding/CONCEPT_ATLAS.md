# Creative Coding Concept Atlas

A map of technique families to mine when designing future DC//LAB sketches. Each section points back to the external catalog instead of relying on vague memory.

## 1. Coordinate fields and shaping functions

**Core ideas:** normalized coordinates, aspect correction, remapping, `smoothstep`, easing, polar coordinates, repetition, symmetry, signed distance to simple shapes.

**Research first:** The Book of Shaders, LYGIA math/space/draw, Godot Shading Reference.

**Sketch directions:** elastic grids, warped posters, polar typography, radial instruments, shape morphs, optical patterns.

**Godot route:** CanvasItem fragment shader for per-pixel work; GDScript/Node2D when individual elements need direct interaction.

## 2. Noise, fBm and domain warping

**Core ideas:** gradient/simplex noise, cellular/Worley noise, multi-octave fBm, turbulence, ridged noise, coordinate warping, curl-like vector fields.

**Research first:** The Book of Shaders, Ashima WebGL Noise, Red Blob Games, LYGIA generative functions.

**Sketch directions:** liquid color fields, procedural topographies, smoke-like typography, living surfaces, animated contour maps.

**Quality rule:** noise should have a compositional job. Avoid adding noise merely to make an image look "generative".

## 3. Signed distance fields and ray marching

**Core ideas:** SDF primitives, unions/intersections/subtraction, smooth booleans, repetition, deformation, sphere tracing/ray marching, normals from distance gradients.

**Research first:** Inigo Quilez articles, Shadertoy references, LYGIA SDF functions.

**Sketch directions:** impossible sculpture, procedural architecture, tunnels, soft-body typography, abstract 3D objects, infinite repetition.

**Godot route:** fullscreen CanvasItem for 2D SDF; Spatial/CanvasItem raymarching for 3D procedural fields.

## 4. Particle systems and vector fields

**Core ideas:** velocity/acceleration, attractors/repulsors, flow fields, curl noise, trails, neighborhood rules, spawning/lifetime.

**Research first:** Nature of Code, OpenProcessing, GPU/compute references.

**Sketch directions:** calligraphic particle flow, swarm typography, magnetic ink, wind-driven dust, point-cloud choreography.

**Scale-up path:** GDScript/Node2D for hundreds; MultiMesh/particles/compute for thousands+.

## 5. Autonomous agents and emergence

**Core ideas:** steering, seek/flee/arrive, separation/alignment/cohesion, local rules, feedback between agents and environment.

**Research first:** Nature of Code.

**Sketch directions:** flocks forming letters, crowd flow, living line systems, emergent networks, generative drawing machines.

**Design value:** useful when the visual should feel alive without obvious looping animation.

## 6. Cellular automata and reaction systems

**Core ideas:** neighborhood state updates, Conway-like automata, Gray-Scott reaction-diffusion, ping-pong textures, thresholding/morphology.

**Research first:** The Book of Shaders simulation chapters, Godot compute shaders, GPU feedback references.

**Sketch directions:** chemical typography, growing ornament, coral/lichen fields, self-eroding posters, evolving masks.

**Godot route:** ping-pong SubViewports/textures for moderate resolution; compute for larger grids.

## 7. Fluids, advection and dye fields

**Core ideas:** velocity fields, advection, divergence, pressure projection, vorticity, dye transport, obstacles.

**Research first:** NVIDIA GPU Gems fluid chapters.

**Sketch directions:** touch-driven ink, fluid typography, smoke ribbons, interactive pool projections, color mixing surfaces.

**Warning:** fluid simulation is expensive and stateful; build a low-resolution solver first and upscale visually.

## 8. Feedback and recursive image systems

**Core ideas:** previous-frame texture, decay, transform feedback, displacement, threshold, color drift, recursive compositing.

**Research first:** Godot screen-reading shaders, Twigl backbuffer work, Shadertoy multipass/reference projects.

**Sketch directions:** video-synth trails, datamosh-like smears, recursive typography, kaleidoscopic echo, motion memory.

**Live value:** feedback systems are especially effective for touch and audio interaction because the gesture leaves a history.

## 9. Kinetic typography

**Core ideas:** glyph metrics, grid/layout systems, per-glyph transformation, SDF/MSDF text, baseline control, kerning, deformation fields.

**Research first:** Generative Design, p5.js examples, contemporary shader/typography references discovered through OpenProcessing/Radiant.

**Sketch directions:** liquid type, chromatic lens, dissolve type, optical type grids, type-to-particles, text woven into vector fields.

**DC//LAB rule:** typography must respect safe margins and remain intentionally composed at every parameter extreme.

## 10. Chromatic and optical effects

**Core ideas:** RGB channel offsets, dispersion, chromatic aberration, refraction, lens distortion, moiré, scanlines, halftone, interference.

**Research first:** Radiant, Shadertoy, Godot Shaders, The Book of Shaders color/shaping sections.

**Sketch directions:** interactive lens systems, diffraction-like type, spectral trails, CRT-inspired live visuals.

**Quality rule:** channel splitting should reinforce a focal action; avoid global RGB split as a default style.

## 11. Procedural geometry and tessellation

**Core ideas:** grids, Voronoi, Delaunay, Poisson/blue-noise sampling, mesh subdivision, displacement, instancing.

**Research first:** Red Blob Games, GPU Gems procedural terrain, VertexShaderArt.

**Sketch directions:** living maps, crystalline fields, generative architecture, mesh typography, adaptive tiling.

## 12. Vertex-driven art

**Core ideas:** derive geometry entirely from vertex ID/index, procedural positions, point sprites, line strips, instanced geometry.

**Research first:** VertexShaderArt, Three.js WebGPU/instancing examples.

**Sketch directions:** dense point sculptures, waveform meshes, procedural ribbons, audio-reactive geometry.

**Why it matters:** not every generative visual should be a fullscreen fragment shader.

## 13. Audio-reactive systems

**Core ideas:** FFT bands, spectral centroid, onset detection, envelope followers, beat phase, smoothing, mapping audio features to visual state.

**Research path:** add dedicated DSP/audio sources in the next research pass; combine with particles, feedback, SDF and typography rather than treating audio as only a scale multiplier.

**Sketch directions:** spectral typography, rhythm-driven field deformation, live feedback compositor, particle emission tied to transients.

## 14. Camera / computer-vision interaction

**Core ideas:** silhouette, optical flow, pose/hand landmarks, motion energy, segmentation, depth fields.

**Research path:** add dedicated OpenCV/MediaPipe/GPU optical-flow sources in the next pass.

**Sketch directions:** body-distorted type, motion-painted feedback, silhouette erosion, gesture-controlled fields.

## 15. Touch-first installation systems

**Core ideas:** multi-touch IDs, pressure where available, gesture velocity, touch history, multiple simultaneous attractors, input normalization across screen resolutions.

**Research first:** our own validated PROGRAM/touch telemetry plus external interactive installation references.

**Sketch directions:** collaborative particle fields, multi-user paint/fluid systems, elastic surfaces, touch typography.

**DC//LAB rule:** PROGRAM input must keep working while the workstation browses/edits another sketch.

## 16. Modern compute / WebGPU thinking

**Core ideas:** compute passes, storage buffers/textures, simulation/render separation, GPU-side state, indirect/instanced rendering.

**Research first:** Godot compute shaders, Three.js TSL/WebGPU, GPU Gems.

**Sketch directions:** million-particle fields, large reaction systems, GPU boids, dense autonomous geometry.

## 17. Live visual / VJ architecture

**Core ideas:** PREVIEW vs PROGRAM, persistent output, deck A/B/C, crossfade, compositing layers, cue/timeline, parameter snapshots, MIDI/OSC, output routing.

**Research basis:** DC//LAB's current PROGRAM layer is the seed. Future research should add Resolume/TouchDesigner/Notch/VDMX-style architecture references without cloning their UI.

**Next milestones:**
- PROGRAM persists while browsing — implemented.
- TAKE LIVE from another preview — implemented.
- A/B deck abstraction.
- crossfader / transition shader.
- layer compositing.
- snapshots/presets.
- timeline/cues.
- MIDI/OSC mapping.

## 18. Procedural worlds and environmental systems

**Core ideas:** terrain masks, biomes, erosion approximations, rivers, layered noise, atmospheric fields, volumetric rendering.

**Research first:** Red Blob Games, GPU Gems terrain/fluid references.

**Sketch directions:** abstract topographic maps, fantasy projection environments, evolving landscapes, volumetric underwater worlds.

## 19. Code-golf / demoscene thinking

**Core ideas:** mathematical compression, procedural synthesis, tiny shaders, reuse of coordinate transforms, compact feedback loops.

**Research first:** Twigl, Shadertoy, Inigo Quilez.

**Use carefully:** study the conceptual elegance, not the unreadable compression style. DC//LAB production code should remain maintainable.

## 20. Cross-domain combinations worth exploring

High-value combinations for future sketches:

- **SDF typography + reaction-diffusion** → letters become chemical boundaries.
- **Flow field + glyph particles** → text disintegrates into coherent vector motion.
- **Feedback + chromatic lens** → lens leaves recursive spectral memory.
- **Fluid advection + touch** → direct interactive installation surface.
- **Voronoi + typography** → adaptive typographic cells.
- **Audio onset + feedback** → rhythmic visual memory instead of simple pulsing.
- **Raymarching + typography masks** → 3D worlds revealed through type.
- **Multi-touch + autonomous agents** → visitors become moving attractors/repulsors.
- **Compute particles + PROGRAM deck system** → large realtime visual instruments suitable for live performance.
