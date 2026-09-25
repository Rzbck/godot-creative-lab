# DC//LAB Realtime Performance Budget

This document turns host performance feedback into a creative constraint.

Realtime speed is not separate from art direction. If a visual system only works by flooding CanvasItem with thousands of CPU draw calls or repeating the same neighbourhood calculation in simulation and drawing, the representation is wrong for the scale.

## Core rule

Choose the cheapest representation that preserves the phenomenon.

Performance should be designed into the sketch architecture before polish, especially for Gallery hover previews + PREVIEW + PROGRAM workflows.

Do not codify one universal FPS threshold for every machine. The current host has observed some new labs falling below an otherwise very high smooth baseline around 330 FPS; use host telemetry/profiling to attribute exact regressions, and optimize obvious structural hotspots even when remote telemetry is stale.

## Dense scalar / cellular fields

Preferred pattern:

`fixed-rate simulation grid -> one ImageTexture or shader field -> one/few draw calls`

Avoid:

`2000-5000 cells -> draw_rect/draw_circle per cell every render frame`

Rules:
- simulation resolution and display resolution are separate;
- update the field at a fixed simulation cadence (typically 15–60 Hz depending on dynamics), not once per render frame;
- update the display texture only when the simulation steps;
- let filtering/shader reconstruction produce the visual surface;
- cache neighbour-derived quantities during simulation if drawing needs them;
- never recompute an 8-neighbour scan in `_draw()` when it was already computed in the simulation step.

## Particle / population systems

For small populations with important CPU-authoritative state, direct CPU simulation is fine.

As scale grows:
- use spatial partitioning before O(N²) neighbour scans become dominant;
- use `MultiMesh` / RenderingServer for many repeated visual instances;
- use `GPUParticles2D/3D` + particle shaders when individual CPU authority is not required;
- use a texture/buffer representation when particles and fields need bidirectional GPU coupling.

Do not move a system to GPU merely for fashion. GPU state complicates PREVIEW/PROGRAM deterministic synchronization and readback.

## Contact / graph systems

Contact detection, graph reconstruction and force calculation belong to the simulation step.

Drawing should consume cached results:
- contact pairs;
- edge weights;
- force-chain strengths;
- Voronoi/graph relationships;
- stress values.

Do not run the pairwise search again just to draw lines.

When populations become large, consider:
- uniform spatial hashes / grids;
- neighbourhood bins;
- Delaunay/Voronoi updates at a lower cadence than particle motion;
- topology updates only when displacement exceeds a threshold.

## Shader-first systems

Use one fullscreen CanvasItem shader when the visual is naturally an analytic field, optical transform, modal surface or low-state procedural system.

Good examples:
- Faraday modal standing waves;
- magnetic/Rosensweig-like height fields;
- optical interference;
- SDF/raymarch fields with bounded complexity.

Keep CPU state small and send only meaningful uniforms.

Avoid giant loops per fragment whose complexity scales unpredictably with resolution.

## Simulation cadence

Render FPS and simulation rate are different.

A sketch can render at a high rate while simulation advances at:
- 15–24 Hz for slow chemistry/growth;
- 30 Hz for cellular tissue/reaction systems;
- 45–60 Hz for contacts/fast waves;
- lower cadence for graph rebuilds or expensive topology.

Use accumulators and fixed steps for deterministic evolution.

## PREVIEW / PROGRAM and Gallery budget

Remember the workstation can have:
- static Gallery thumbnails;
- one hovered animated thumbnail;
- a PREVIEW simulation;
- a PROGRAM follower/autonomous output.

A sketch that is acceptable alone can still be a bad citizen in the workstation.

Requirements:
- idle Gallery cards remain frozen;
- no hidden sketch should keep expensive simulation running unnecessarily;
- live-sync payloads should contain state, not redundant render geometry when geometry can be reconstructed;
- image/field state should not be duplicated at excessive resolution merely for synchronization.

## Performance acceptance questions

Before a new lab is considered ready for host testing:

- Is the expensive operation tied to simulation cadence rather than render cadence?
- Does `_draw()` contain nested loops over thousands of elements?
- Is any neighbourhood/contact calculation repeated during drawing?
- Could thousands of identical primitives become one texture, MultiMesh or GPU particle pass?
- Is there any O(N²) loop, and what is its bounded N?
- Can the representation scale down gracefully in Gallery PREVIEW without changing its character?
- Does live sync duplicate large arrays more often than necessary?

After host testing:
- inspect fresh `telemetry/runtime` first;
- verify telemetry HEAD/session matches the tested build;
- attribute exact slowdowns only from matching evidence;
- if telemetry is stale, state that limitation and rely only on code-level hotspot analysis until a fresh session publishes.

## Current host-derived optimization case

The 016–020 host test reported some sketches dropping below the user's expected smooth baseline.

Fresh remote telemetry did not publish that run; the latest available remote session still corresponded to the earlier 011–015 build, so exact per-sketch FPS attribution was unavailable.

Code audit still revealed clear structural hotspots:
- `017_edge_bloom`: 64×36 field could issue roughly 2300 CanvasItem circle draws per rendered frame;
- `020_echo_tissue`: 72×40 field could issue roughly 2880 cell draws and also recomputed neighbourhood statistics during `_draw()`.

The corrective pattern is:
- retain fixed-rate coupled simulations;
- convert dense field rendering to one low-resolution `ImageTexture` updated on simulation steps;
- cache density/neighbour data from simulation;
- draw the field in one texture call;
- keep sparse spores/agents as direct geometry.

This pattern is now the default for CPU scalar fields unless a different representation is demonstrably better.
