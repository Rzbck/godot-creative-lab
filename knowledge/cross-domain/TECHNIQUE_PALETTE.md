# DC//LAB Technique Palette

This file prevents a recurring creative failure: finding one interesting technical representation, then applying it to every sketch.

A technique is **not** an aesthetic direction. It is one possible representation or mechanism among many.

## Core rule

For substantial creative work, do **not** choose the implementation technique first.

Start from:

1. artistic intention;
2. carrier/material;
3. desired autonomous behavior;
4. interaction consequence;
5. temporal model;
6. composition/design constraint.

Then compare **at least three plausible technical representations** before choosing one.

The chosen representation should make the concept more specific, not merely make it possible.

## Available representation families

### Direct typography / layout

Use when the idea lives at word, line, paragraph, hierarchy or editorial-system level.

- whole-glyph transforms;
- per-glyph transforms;
- kerning/tracking/leading systems;
- glyph metrics;
- variable-font axes;
- alternate glyph substitution;
- line breaking and reflow;
- typographic grids;
- baseline systems.

### Structural typography

Use only when the concept actually depends on internal letter anatomy.

- vector glyph contours;
- sampled contour points;
- stems/counters/apertures/bowls as regions;
- curve/control-point deformation;
- contour topology changes;
- skeleton/medial-axis approximations.

**Contours are one technique, never the default.**

### Raster / masks / image space

- glyph masks;
- alpha masks;
- thresholding;
- morphology: erode/dilate/open/close;
- blur and distance transforms;
- displacement maps;
- image segmentation;
- compositing and masks;
- temporal accumulation buffers.

### SDF / MSDF / distance fields

Useful when boundaries, inside/outside relationships and scale-independent fields matter.

- signed distance deformation;
- boundary growth/erosion;
- smooth unions/intersections;
- distance-driven forces;
- SDF-to-particle forces;
- MSDF text rendering with shader-level deformation.

### Fragment shaders / coordinate systems

- UV remapping;
- domain warping;
- polar/logarithmic coordinates;
- repetition and tiling;
- reaction to masks/fields;
- raymarching;
- procedural textures;
- screen-space post-process;
- optical systems;
- chromatic/registration systems.

A shader should not be used merely because the work is realtime.

### Feedback / temporal image systems

- framebuffer feedback;
- trails;
- delayed buffers;
- recursive transforms;
- history masks;
- temporal erosion;
- persistence/ghosting;
- long-exposure style accumulation.

Useful when the artwork is fundamentally about memory or history rather than geometry.

### Particle / agent systems

- point clouds;
- boids;
- spring particles;
- attraction/repulsion;
- flocking;
- path following;
- agents constrained by glyph/grid geometry;
- birth/death/reproduction;
- local rule systems.

Useful when population behavior is more important than exact shape preservation.

### Vector fields / flow

- curl fields;
- gradient fields;
- advection;
- vortices;
- field lines;
- touch/audio injected velocity;
- type/grid-derived force fields.

### Physical / constraint systems

- springs;
- Verlet-like constraints;
- soft bodies;
- cloth-like lattices;
- rigid-body relationships;
- collision boundaries;
- tension/compression networks;
- fracture constraints.

### Cellular / simulation systems

- cellular automata;
- reaction-diffusion;
- diffusion/decay fields;
- excitable media;
- neighborhood state machines;
- phase transitions;
- growth systems;
- predator/prey or population models.

Use when emergent state is central to the concept, not as decorative noise.

### Geometry / mesh / spatial systems

- procedural meshes;
- triangulation;
- Voronoi/Delaunay;
- extruded type;
- ribbons;
- instancing;
- 3D point clouds;
- depth and camera perspective;
- spatial typography;
- projection surfaces.

### Graph / grid / topology

- editorial cells as graph nodes;
- adjacency relationships;
- path finding;
- propagation networks;
- reconfiguration;
- graph forces;
- topology mutation.

### Data / semantic structures

- text length;
- glyph class;
- frequency;
- semantic categories;
- live data;
- event streams;
- state machines driven by content rather than cursor position.

### Input / sensing

- pointer position;
- velocity;
- acceleration;
- pressure when available;
- multitouch distance/angle;
- dwell;
- audio envelope/FFT;
- camera/pose/depth when explicitly supported;
- external data.

Input is a driver, not the artwork itself.

## Temporal palette

A visual technique and a temporal model are separate choices.

Possible temporal models:

- deterministic loop;
- quasi-periodic oscillation;
- spring/inertia;
- hysteresis;
- delayed response;
- accumulation;
- fatigue;
- memory;
- autonomous agents;
- stochastic events;
- phase transitions;
- self-repair;
- irreversible mutation;
- birth/death;
- regime switching;
- feedback.

## Interaction palette

Avoid repeating `click -> effect`.

Possible consequences:

- inject energy;
- remove energy;
- seed a population;
- kill/erase elements;
- change constraints;
- cut/create graph links;
- alter topology;
- synchronize/desynchronize;
- attract/repel;
- change material properties;
- write memory;
- reveal hidden state;
- switch regimes;
- redirect flow;
- create obstacles/boundaries;
- alter time scale;
- permanently mutate part of the system.

## Selection protocol

Before implementation, write three candidate chains.

Example intention: **language becomes unreliable under repetition**.

Candidate A:

`typographic rows -> phase oscillators -> coupled synchronization -> gesture changes coupling`

Candidate B:

`glyph raster -> temporal feedback -> threshold drift -> touch writes delay mask`

Candidate C:

`words -> graph nodes -> propagation / mutation -> touch cuts or reconnects semantic paths`

Only then choose the representation that creates the strongest artistic identity.

## Diversity rule for a series

When designing several sketches together:

- no more than two should share the same **primary representation**;
- no more than two should share the same **primary temporal model**;
- interaction consequence should differ materially between works;
- palette/composition should not be the only source of differentiation;
- at least one work should avoid typography entirely when the brief allows it;
- at least one work should use a non-pointer autonomous mechanism when appropriate.

If five works can be implemented by changing only text, colors and cursor mapping in one base sketch, the series has failed.

## Technique audit questions

Before accepting a direction:

- Did we choose this technique because it belongs to the concept, or because it was recently convenient?
- What would happen if the typography disappeared?
- What would happen if we replaced the pointer with autonomous state?
- Is the representation deep enough for the claim, but no deeper than necessary?
- Does the piece have behavior that cannot be summarized as an effect preset?
- Is this technically/visually distinct from the other current Gallery works?

The objective is not maximum technical complexity. It is **the right mechanism for a specific artistic idea**.