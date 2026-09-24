# DC//LAB Creative Coding Knowledge Library

This folder is the project's external research memory for creative coding, realtime graphics, shaders and generative systems.

The goal is simple: when we design a new sketch, we should not start from vague model memory. We start here, inspect recognized references, trace the underlying technique, verify licensing, then build our own Godot-native interpretation.

Last research pass: **2026-09-24**.

## Companion design library

Creative technique is only half of the work. Typography, hierarchy, margins, grid, color, poster composition, motion grammar and visual-system thinking live in the companion library:

`knowledge/design/README.md`

For new sketches, use both libraries together: **creative-coding technique + professional design system**.

## How to use this library

1. Start with `CONCEPT_ATLAS.md` and choose a technical/aesthetic family.
2. Open `SOURCE_CATALOG.md` and inspect several sources, not just one.
3. Prefer primary documentation, original authors and maintained repositories.
4. Treat community galleries as inspiration, not as code to copy blindly.
5. Before reusing code, verify the upstream license for the exact file/repository/version.
6. Translate the idea into DC//LAB's runtime contract: preview, PROGRAM/LIVE OUT, touch/mouse input, persistent parameters and deterministic sync.
7. Cross-check the visual system against `../design/TYPOGRAPHY_ATLAS.md` and `../design/GRAPHIC_DESIGN_ATLAS.md`.
8. Add any useful new source to both `SOURCE_CATALOG.md` and `sources.json`.

## Source tiers

- **A — Primary / canonical:** official engine documentation, original author, foundational book/project, research or well-established reference.
- **B — Curated technical library:** maintained reusable code, high-quality open-source collection, focused technical resource.
- **C — Inspiration / community:** galleries and user-contributed sketches. Excellent for visual research, but provenance and licensing must be checked per work.

## Main domains

- `shader-math`: GLSL/Godot shader language, coordinates, shaping functions, color, blending.
- `noise-patterns`: random, gradient/simplex noise, Voronoi/cellular, fBm, domain warping.
- `sdf-raymarching`: signed distance fields, 2D/3D primitives, ray marching, repetition, smooth booleans.
- `particles-fields`: particles, flow fields, attractors, trails, boids, vector fields.
- `simulation`: feedback, reaction-diffusion, cellular automata, fluids, waves, physics.
- `typography`: glyph fields, SDF/MSDF text, deformation, layout, kinetic type.
- `image-feedback`: screen textures, post effects, datamosh-like feedback, blur, trails, displacement.
- `procedural-geometry`: tessellation, Voronoi/Delaunay, terrain, mesh displacement, instancing.
- `interaction-live`: touch, pointer, audio, sensors, live parameter control, installation behavior.
- `webgpu-compute`: WGSL/TSL, compute-oriented workflows and modern GPU architecture.
- `creative-systems`: generative design methodology, autonomous agents, emergence, evolutionary systems.

## DC//LAB translation rules

Every external reference is only a starting point. A DC//LAB sketch should aim for:

- one clear visual idea rather than a pile of effects;
- a stable 1280×720 logical design space unless the concept requires otherwise;
- preview and PROGRAM output representing the same composition/state;
- direct pointer/touch interaction where meaningful;
- parameters that expose artistic decisions, not implementation noise;
- persistent settings across sessions;
- no debug labels, sketch titles or technical captions burned into the final render;
- controlled GPU/CPU cost so the workstation remains usable during LIVE OUT.

## Files

- `SOURCE_CATALOG.md` — curated human-readable source library.
- `CONCEPT_ATLAS.md` — technique map and directions to mine for future sketches.
- `sources.json` — machine-readable source index for future tooling/search.

## Research policy

This library stores links, summaries, tags and our own notes. It does **not** vendor third-party source code by default. If we later decide to import a library or code fragment, that should happen explicitly with its license reviewed and recorded.
