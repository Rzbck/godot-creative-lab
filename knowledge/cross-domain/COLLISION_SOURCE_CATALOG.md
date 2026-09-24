# DC//LAB Collision Research Source Catalog

Purpose: sources that are useful because they show **technique hybridization, complex systems, emergent behavior, generative language design or unusual representation bridges**.

This is not a style-copy list. Extract mechanisms and relationships, then reimplement original systems in Godot.

## A — Primary / canonical technical foundations

### Nature of Code — Daniel Shiffman
https://natureofcode.com/

Why useful:
- forces, oscillation, particle systems, steering, autonomous agents;
- cellular automata, fractals, evolutionary systems;
- strong mental model for simple local rules producing complex global behavior.

Research use:
- population systems;
- force/constraint combinations;
- autonomous behavior before user input;
- moving from individual particles to rule-based systems.

### The Book of Shaders
https://thebookofshaders.com/

Why useful:
- shaping functions, coordinate transforms, patterns, random/noise;
- image processing and convolution;
- ping-pong simulation, Conway, ripples, watercolor, reaction-diffusion;
- a single source spans drawing, generative processes, image space and simulation.

Research use:
- shader techniques as modular operators;
- simulation buffers;
- combine mask/image processing with procedural coordinates instead of treating shaders as one visual genre.

### LYGIA shader library
https://github.com/patriciogonzalezvivo/lygia
https://lygia.xyz/

Why useful:
- unusually broad modular vocabulary: space, color, animation, generative, SDF, filters, distort, geometry, morphology, sampling, simulation;
- useful as a taxonomy of independent shader operators that can be randomly combined.

Important:
- license review required before copying code into DC//LAB;
- use the taxonomy freely as research vocabulary.

### TouchDesigner official curriculum — Feedback
https://learn.derivative.ca/courses/100-fundamentals/lessons/102-tops-working-with-images/topic/creating-a-feedback/

Why useful:
- feedback as previous-frame state, not merely a decorative trail;
- foundation for temporal memory, accumulation and recurrent image systems.

### TouchDesigner official curriculum — Particle POP
https://learn.derivative.ca/courses/review/lessons/109-pops-working-with-points/topic/working-with-particles-in-pops/

Why useful:
- GPU particle state loops;
- cumulative forces and damping;
- initial-state variation through attributes;
- good reference for thinking about state as data textures/buffers.

## B — Strong specialist hybrid-technique references

### Simon Alexander-Adams — Creating Generative Visuals with Complex Systems
https://www.simonaa.media/tutorials/complex-systems-workshop

Why especially relevant:
- reaction-diffusion + cellular automata;
- explicitly demonstrates using their outputs to drive particle systems and geometry;
- adds audio and motion-control interaction;
- emphasizes iterative reuse of techniques in new contexts.

This is close to the collision-first direction DC//LAB wants.

### Derivative — Interactive particles & raymarching SDF geometry
https://derivative.ca/community-post/tutorial/interactive-particles-raymarching-sdf-geometry/63516

Bridge:
`raymarched SDF surface -> particle positions/forces -> interaction`

Why useful:
- demonstrates a real representation bridge instead of a stack of unrelated post effects.

### Derivative — Reaction-Diffusion Feedback Effects
https://derivative.ca/community-post/tutorial/reaction-diffusion-feedback-effects-touchdesigner-tutorial/66191

Bridge:
`feedback state -> reaction-diffusion-like pattern -> further transformation`

Why useful:
- small node vocabulary producing unexpected evolving states;
- good candidate source for chemical systems that later drive unrelated representations.

### Derivative — Last of Us-inspired reaction-diffusion text
https://derivative.ca/community-post/tutorial/last-us-inspired-text-effects-touchdesigner/67688

Bridge:
`text mask -> two feedback networks -> reaction-diffusion growth`

Why useful:
- typography is not necessarily deformed directly; it becomes a boundary/source for another system.

### TouchDesigner / Interactive & Immersive HQ — GPU particle systems
https://nvoid.gitbooks.io/introduction-to-touchdesigner/content/GLSL/12-7-GPU-Particle-Systems.html

Why useful:
- particle state stored in textures;
- feedback used to preserve previous positions;
- bridge between image buffers, GLSL and geometric populations.

### elekktronaut tutorials
https://www.elekktronaut.com/tutorials

Specific useful examples:
- Feedback Particles
- Feedback Mold
- Descending Feedback
- Slitscan
- Particle Paths
- Kinetic Typography With Instancing
- Generative Blueprints
- Tile Patterns

Why useful:
- broad practical catalogue of small techniques that can be treated as independent cards;
- especially useful for collision research because many tutorials combine TOP feedback, instancing, noise, geometry, audio or typography in compact systems.

Do not copy final looks; extract mechanisms.

### Codrops Creative Hub
https://tympanus.net/codrops/hub/tutorials/

Why useful:
- large technique catalogue across WebGL/WebGPU, particles, physics, cloth, typography, distortion, masks, morphing, postprocessing and interaction;
- good source for obscure rendering/interaction cards outside our normal Godot habits.

Useful case studies:
- living particle systems;
- WebGL typography;
- interactive particles;
- image/text distortion via masks;
- WebGPU text destruction/gommage.

### Entagma
https://entagma.com/

Why useful:
- procedural Houdini thinking;
- frequently crosses SDFs, gradients, packing, particle advection, simulation, instancing and geometry;
- excellent source for techniques that are not screen-space shader effects.

Example bridge:
`SDF gradient -> surface projection -> particle packing`

## C — Generative-art process and material diversity

### Generative Hut
https://www.generativehut.com/

Why useful:
- spans p5.js, Python, Observable, Cinema4D, plotters, physical ink/paper and generative geometry;
- prevents realtime GPU work from becoming the only mental model;
- physical plotter/material constraints can inspire realtime constraints.

### Raven Kwok
https://ravenkwok.com/

Specific research cases:

#### 1DDCB
https://ravenkwok.com/1ddcb/

Bridge:
`recursive quadtree -> cell vertices -> Voronoi tessellation -> layered geometric chaos`

This is a strong example of feeding the structure created by one algorithm directly into another.

#### Legion
https://ravenkwok.com/legion/

Bridge:
`2D particles -> soft-body constraints -> Kinect body blobs -> gradual constraint revocation`

Excellent example of interaction modifying the internal constraint graph rather than applying a cursor filter.

#### 1D985
https://ravenkwok.com/1d985/

Bridge:
`K-D tree recursion -> per-level transformation matrices -> audiovisual/spatial adaptation`

Useful for hierarchy and recursion as living composition.

## D — Studio systems / art-direction references

### Universal Everything
https://www.universaleverything.com/

Research principle:
- describes its practice as **Living Motion Systems**;
- builds bespoke generative languages intended to evolve across audiences, spaces and contexts;
- combines physics, AI, motion capture and spatial technologies according to the work.

Useful works:

#### Future You
https://www.universaleverything.com/artworks/future-you

Body movement drives a system with tens of thousands of possible generated forms.

#### Infinity
https://www.universaleverything.com/media-art/infinity

Endless code-generated characters; useful reference for generative variation as the artwork rather than a single effect.

#### Into the Sun
https://www.universaleverything.com/media-art/into-the-sun

Viewer movement drives plant growth and sound — interaction becomes behavior in an environment.

### onformative
https://onformative.com/

Research principle:
- art + design + technology through research;
- design is described as setting direction rather than adding superficial aesthetics;
- generative systems, data-driven narratives and immersive interaction are treated as integrated practice.

Useful works:

#### IBM FLUX
https://backend.onformative.com/work/ibm-flux

Real-time streams and sensors drive multiple visual modes across a physical display sculpture.

#### CX-Shanghai
https://onformative.com/work/cx-shanghai/

City data changes composition and mood; useful for external state producing large-scale visual regime changes.

### FIELD.IO
https://field.io/

Useful case:

#### Scalable Storytelling
https://field.io/work/scalable-storytelling

Process:
`visual library -> analysis of form/texture/depth -> parameterized generative identity system`

Important lesson:
- source material can be decomposed into features and recombined into a coherent generative language instead of directly restyled.

## Research rules

For every new collision session:

1. sample at least one source from a simulation/algorithm family;
2. sample one source from a different representation family;
3. optionally sample one studio case for art-direction/system thinking;
4. extract only transferable mechanisms;
5. generate a random collision without copying the source composition;
6. implement a raw prototype;
7. assign meaning after observing behavior.

Do not turn the source catalog into a menu of visual styles.
