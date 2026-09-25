# DC//LAB Physical + Chemical Systems Atlas

Purpose: add real-world pattern formation, matter behaviour and measurable physical/chemical constraints to the collision-first bank.

This is a mechanism atlas, not a visual-style menu. The goal is to borrow **rules, thresholds, conservation laws, instability conditions and material consequences**, then build original realtime systems in Godot.

## Research principle

When drawing from real-world science, preserve at least one genuine causal relationship from the phenomenon.

Weak use:

`ferrofluid reference -> black spikes aesthetic`

Stronger use:

`field strength crosses a threshold -> flat surface destabilizes -> modes compete -> peaks sharpen -> hysteresis/relaxation after field change`

Interaction should preferably modify a physical condition: source, boundary, field, forcing, pressure, concentration, temperature, catalyst, obstacle, load or phase.

---

## 1. Belousov–Zhabotinsky / excitable chemical media

Real behaviour:
- local chemical oscillation;
- propagating concentration waves;
- excitation followed by a refractory period;
- colliding waves annihilate;
- broken fronts curl into spirals;
- pacemakers can entrain slower regions;
- parameter changes can move the system between oscillatory, excitable, bistable and chaotic regimes.

Useful computational abstractions:
- 2–3 scalar fields on a grid;
- excitable cellular model;
- Oregonator-like reduced kinetics;
- phase oscillator field with refractory state.

Good interaction mappings:
- touch injects catalyst;
- dwell creates a pacemaker;
- drag breaks a wavefront to seed a spiral;
- a persistent obstacle becomes a non-reactive region;
- parameter changes move between excitable and oscillatory regimes.

Potential controls:
`EXCITABILITY`, `REFRACTORY`, `CATALYST`, `DIFFUSION`, `PACEMAKER RATE`, `INHIBITION`, `WAVE SPEED`, `CHAOS BIAS`.

Source:
- https://www.scholarpedia.org/article/Belousov-Zhabotinsky_reaction

---

## 2. Liesegang precipitation / dissolution fronts

Real behaviour:
- one reagent diffuses through a gel containing another reagent;
- precipitation happens only after local supersaturation exceeds a threshold;
- precipitation depletes nearby reagent and creates a no-growth zone;
- repeated diffusion + threshold crossing forms bands or concentric rings;
- spacing and width can change with distance;
- precipitation can be coupled to later dissolution, yielding moving fronts and waves;
- external fields can bias morphology because ionic species are involved.

Useful computational abstractions:
- radial or planar concentration fields;
- moving reaction front;
- thresholded nucleation memory;
- precipitate/depletion/dissolution fields;
- bands stored as geometry rather than pixels when appropriate.

Good interaction mappings:
- pointer becomes reagent reservoir;
- drag lays a concentration gradient;
- hold changes local nucleation threshold;
- another input dissolves existing precipitate instead of adding more;
- force/vector field bends future ring growth.

Potential controls:
`DIFFUSION`, `SUPERSATURATION`, `NUCLEATION`, `DEPLETION`, `DISSOLUTION`, `FRONT SPEED`, `BAND MEMORY`, `FIELD BIAS`.

Sources:
- https://pubs.acs.org/doi/10.1021/acs.langmuir.9b03018
- https://pubs.acs.org/doi/10.1021/ja906890v

---

## 3. Spinodal decomposition / Cahn–Hilliard phase separation

Real behaviour:
- an initially mixed material spontaneously separates into two phases after a quench;
- small fluctuations grow without a nucleation barrier in the spinodal region;
- material is conserved;
- interfaces cost energy;
- domains coarsen over time;
- coupling to flow or ordering can create fibrillar, droplet or bicontinuous structures.

Useful computational abstractions:
- conserved scalar phase field;
- Cahn–Hilliard-like update;
- mass-conserving blur/sharpen cycle;
- phase-field + advection;
- phase-field + particles/geometry sampling the interface.

Good interaction mappings:
- touch locally quenches temperature;
- drag advects composition but must conserve mass;
- dwell changes mobility or interfacial tension;
- interaction can reverse a region from mixing to demixing.

Potential controls:
`QUENCH DEPTH`, `MOBILITY`, `INTERFACE ENERGY`, `COARSENING`, `MASS BIAS`, `ADVECTION`, `THERMAL MEMORY`, `SURFACE TENSION`.

Sources:
- https://pages.nist.gov/fipy/en/stable/VKML.html
- https://pages.nist.gov/fipy/en/benchmark_patched_2054173bf/generated/examples.cahnHilliard.mesh2D.html
- https://www.nist.gov/publications/phase-behavior-polyolefin-blend

---

## 4. Bénard–Marangoni convection

Real behaviour:
- temperature/concentration gradients change surface tension;
- surface-tension differences drive flow along an interface;
- beyond threshold, organized convection cells can appear;
- hexagonal cellular patterns and transitions are common;
- convection transports the very scalar field that created the flow, producing feedback.

Useful computational abstractions:
- scalar temperature field -> surface-tension gradient -> velocity field -> scalar advection;
- cellular flow lattice whose geometry changes with forcing;
- droplets/particles advected by Marangoni velocity.

Good interaction mappings:
- touch is a heat source/sink;
- moving pointer paints surfactant/concentration;
- dwell changes local surface tension permanently for a while;
- boundaries can be thermally insulated or conducting.

Potential controls:
`THERMAL GRADIENT`, `SURFACE TENSION`, `VISCOSITY`, `COOLING`, `ADVECTION`, `CELL SCALE`, `SURFACTANT`, `BOUNDARY LOSS`.

Sources:
- https://journals.aps.org/pre/abstract/10.1103/PhysRevE.47.3316
- https://meetings-archive.aps.org/dfd/2024/r35/5

---

## 5. Faraday waves / parametric resonance

Real behaviour:
- vertical periodic forcing destabilizes a fluid surface above a threshold;
- standing waves appear at subharmonic frequency;
- forcing frequency, damping, depth and capillarity select spatial modes;
- stripes, squares, hexagons and higher-order quasi-patterns can compete;
- slow variation of forcing can capture the system into resonance.

Useful computational abstractions:
- modal wave superposition with nonlinear saturation;
- height field with parametric forcing;
- oscillator lattice with mode competition;
- low-mode spectral representation for performance.

Good interaction mappings:
- touch changes local forcing phase;
- drag changes excitation direction;
- dwell shifts local resonance;
- release lets the surface fall back below threshold.

Potential controls:
`DRIVE`, `FREQUENCY`, `DAMPING`, `CAPILLARITY`, `DEPTH`, `MODE COUPLING`, `RESONANCE WIDTH`, `CHIRP`.

Sources:
- https://journals.aps.org/pre/abstract/10.1103/PhysRevE.47.R788
- https://journals.aps.org/pre/abstract/10.1103/PhysRevE.60.559
- https://journals.aps.org/pre/abstract/10.1103/PhysRevE.72.016310

---

## 6. Rosensweig instability / ferrofluid patterning

Real behaviour:
- a magnetic fluid surface can become unstable in a normal magnetic field;
- above a critical field, a flat surface develops peaks;
- peak amplitude grows after crossing threshold;
- mode coupling can form ordered peak arrays;
- field geometry can bias orientation, fingering and droplet breakup;
- ferrofluid + vibration can couple magnetic and Faraday instabilities.

Useful computational abstractions:
- scalar height field driven by magnetic potential;
- spectral peak modes;
- particle droplets with dipole-like attraction + surface penalty;
- SDF surface whose curvature competes with field energy.

Good interaction mappings:
- pointer is a movable magnet;
- multitouch creates competing magnets;
- dwell crosses local instability threshold;
- drag changes field direction and peak orientation;
- release leaves viscous relaxation/hysteresis.

Potential controls:
`FIELD STRENGTH`, `MAGNET RADIUS`, `SURFACE TENSION`, `VISCOSITY`, `PEAK SHARPNESS`, `MODE COUPLING`, `HYSTERESIS`, `RELAXATION`.

Sources:
- https://journals.aps.org/pre/abstract/10.1103/PhysRevE.69.066306
- https://journals.aps.org/pre/abstract/10.1103/PhysRevE.76.066301
- https://journals.aps.org/pre/abstract/10.1103/PhysRevE.77.016304

---

## 7. Diffusion-limited aggregation (DLA)

Real behaviour:
- diffusing walkers attach to an existing cluster on contact;
- growth concentrates at exposed tips;
- shielding starves interior regions;
- the result is dendritic/fractal branching;
- analogous morphologies appear in electrodeposition, mineral growth, lightning, coral and some crystals.

Useful computational abstractions:
- walkers + occupancy grid;
- growth probability biased by field/flow;
- signed-distance attachment front;
- branch graph extracted from occupancy.

Good interaction mappings:
- touch injects walkers;
- obstacles reshape shielding;
- drag creates electric-field bias;
- hold can dissolve or passivate tips.

Potential controls:
`WALKERS`, `STICKINESS`, `DIFFUSION STEP`, `FIELD BIAS`, `BRANCH THICKNESS`, `DISSOLUTION`, `SHIELDING`, `SEED COUNT`.

Source:
- https://paulbourke.net/fractals/dla/

---

## 8. Granular jamming / force chains

Real behaviour:
- most grains carry modest load while a smaller set forms strong force chains;
- contact network is heterogeneous and changes under load;
- systems can jam, creep, fail and avalanche;
- rearrangement is often intermittent rather than smooth;
- force chains can redirect suddenly after a small perturbation.

Useful computational abstractions:
- packed disks/polygons with contact graph;
- position-based collision resolution;
- force-chain weights on contacts;
- frictional stick/slip state;
- stress propagation graph.

Good interaction mappings:
- touch applies load rather than displacement;
- drag moves a confining wall;
- dwell increases friction or glues grains;
- release can trigger delayed avalanche.

Potential controls:
`PACKING`, `FRICTION`, `LOAD`, `STIFFNESS`, `FORCE CHAIN GAIN`, `CREEP`, `AVALANCHE`, `CONFINEMENT`.

Sources:
- https://journals.aps.org/pre/abstract/10.1103/PhysRevE.72.041307
- https://journals.aps.org/pre/abstract/10.1103/j8ch-x534

---

## 9. Interfacial instabilities: Rayleigh–Taylor, Kelvin–Helmholtz, Saffman–Taylor

### Rayleigh–Taylor
Dense material above light material -> fingers/plumes when support disappears.

Interaction ideas:
- pointer locally flips effective gravity;
- draw a stabilizing magnetic region;
- touch seeds initial perturbation rather than directly drawing fingers.

Source:
- https://journals.aps.org/prl/abstract/10.1103/PhysRevLett.99.204502

### Kelvin–Helmholtz
Velocity shear across an interface -> roll-up vortices and mixing.

Interaction ideas:
- drag sets relative stream velocity;
- interaction paints local viscosity;
- regions can suppress or re-enable roll-up.

Source:
- https://journals.aps.org/pre/abstract/10.1103/PhysRevE.93.041102

### Saffman–Taylor / viscous fingering
A less/more viscous phase displacing another in confined geometry -> branching fingers.

Interaction ideas:
- pointer is injection pressure;
- drag moves injection site;
- particles/wetting modify future interface stability.

Source:
- https://journals.aps.org/prl/abstract/10.1103/PhysRevLett.117.034501

---

## Interaction lessons from installation practice

Good interactive systems frequently treat the participant as **part of the physics** rather than a cursor overlay.

Transferable patterns:
- body/hand/foot positions become collision geometry or force fields;
- movement changes the future path of a population;
- particles or liquid react to boundaries rather than tracking the user literally;
- a few simple visual elements can feel alive when each has motivation/state;
- interaction should be legible and playful but still leave autonomous behavior after release.

References:
- TouchDesigner floor/water interaction discussion: https://forum.derivative.ca/t/floor-interaction/146455
- Solace process notes: https://www.creativeapplications.net/project/solace/
- Derivative community: https://derivative.ca/community

---

## Performance translation for Godot

Real-world simulation vocabulary can become expensive quickly. Preserve the causal structure while choosing the cheapest representation that keeps the phenomenon recognizable.

Rules:
- separate **simulation resolution** from **display resolution**;
- update expensive neighbour solvers at a fixed rate instead of every render frame;
- render dense scalar fields as one texture/shader pass rather than thousands of CanvasItem primitives when possible;
- avoid recomputing neighbourhood statistics again during draw if simulation already computed them;
- use GPUParticles / particle shaders for large populations that do not need CPU-authoritative individual logic;
- use MultiMesh/RenderingServer for many identical rendered instances;
- use compute shaders only when the scale justifies the complexity and Forward+/Mobile support is acceptable;
- keep PREVIEW and PROGRAM deterministic/live-sync compatible.

Godot references:
- https://docs.godotengine.org/en/4.7/tutorials/performance/using_multimesh.html
- https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/particle_shader.html
- https://docs.godotengine.org/en/4.7/tutorials/shaders/compute_shaders.html

---

## Collision cards to add to random draws

Real-world phenomenon cards:
- BZ excitable waves
- Liesegang precipitation
- spinodal phase separation
- Marangoni convection
- Faraday resonance
- Rosensweig ferrofluid instability
- diffusion-limited aggregation
- granular jamming / force chains
- Rayleigh–Taylor fingering
- Kelvin–Helmholtz shear roll-up
- Saffman–Taylor viscous fingering

Physical-condition driver cards:
- concentration
- temperature
- pressure
- surface tension
- viscosity
- magnetic field
- gravity vector
- forcing frequency
- supersaturation threshold
- friction
- confinement
- catalyst / inhibitor

Interaction consequence cards:
- move a field source
- change a boundary condition
- inject reagent / heat / mass
- remove reagent / dissolve material
- apply load
- quench a phase
- create an obstacle
- alter friction / viscosity / surface tension
- seed an instability
- break a wavefront
- move a pacemaker

The desired result is not scientific illustration. It is **artistic systems whose surprising behaviour comes from real causal structure**.