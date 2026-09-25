# Current work — DC//LAB

Last refreshed: 2026-09-25.

## Active branch / PR

- branch: `feat/creative-sketches-002-004-20260924`
- draft PR: `#7`
- PR base: `feat/gallery-project-workflow-20260923`
- never merge/change `main` without explicit user approval
- final remote HEAD + exact-head CI are authoritative

## Stable product behavior to preserve

Gallery real previews/hover animation, generated search/filtering, persisted sketch parameters, PREVIEW/PROGRAM separation, persistent PROGRAM across navigation, TAKE LIVE, physical output selection/input, linked state sync, async telemetry, local reversible Trash, full-canvas artwork and artwork-only PROGRAM must not regress.

Current top runtime: `app/main/main_runtime_window_memory.gd`.

## Latest host feedback — treat as a creative reset

The host explicitly rejected 026–030 as **globally visually weak / not beautiful enough**, despite their technical diversity. Do not use that batch as evidence that the adaptive-art direction succeeded.

The host also reported:

- FARADAY QUASI still showed a loop/cut, especially around click interaction;
- the general workstation window behaved incorrectly;
- 026–030 were all rated, but the latest remote telemetry publication lost those numeric ratings;
- future work must be high-resolution, detailed and visually ambitious, using the breadth of available techniques rather than small technical demos.

New durable gate: `knowledge/cross-domain/VISUAL_FINISH_GATE.md`.

Adaptive draw remains a collision generator, not a quality guarantee. Required pipeline:

`draw -> prototype -> mutate -> art-direct -> VISUAL_FINISH_GATE -> keep/reject`

## Telemetry evidence from the failed host pass

`telemetry/runtime` advanced to commit `309bf4e93aa62ce01e472dfdb817f684c05cd1bd`, but its close publication wrote an empty `latest.jsonl` / empty session. Therefore **do not invent the user's new 026–030 scores**.

The previous non-empty telemetry commit `1dc917da35c61c1c7e112684c139dc9d14d528a5` does match tested app head `dba702d0...` and proves:

- startup/restored workstation was `windowed` at `[1600,0]`, size `[1920,1078]`;
- user triggered `window_toggle_maximize` around 8.8 s;
- `window_maximize_requested` resulted in native `fullscreen` `[1920,1080]`;
- the user toggled again roughly 650 ms later.

So the old custom Maximize path was genuinely collapsing into fullscreen on this Windows/Godot setup.

The old usable rating snapshot remains only the earlier 16-review dataset. Direct qualitative host rejection of 026–030 is valid evidence; numeric values are unavailable because of the empty close publication.

## Window fix — revision 2

`main_runtime_window_memory.gd` now separates **workstation expansion** from fullscreen presentation:

- custom Maximize uses a borderless **WINDOWED work-area rectangle**, not `WINDOW_MODE_MAXIMIZED`/fullscreen;
- a 2 px bottom guard prevents Windows/Godot from reclassifying the borderless work-area client as fullscreen;
- logical `maximized` state is persisted even though the native client remains windowed;
- old revision-1 saved fullscreen produced by the Maximize control migrates to the stable expanded state;
- real F11 artwork presentation remains independent;
- close now starts one final telemetry publisher process immediately after flushing instead of relying only on a deferred call that can be lost during quit.

Status: **REPO_VALIDATED, HOST_VALIDATION_REQUIRED**.

## FARADAY QUASI fix

Root cause was mathematical, not subjective:

- controller wrapped `u_forcing_phase` at `2π`;
- shader multiplied the wrapped phase by fractional coefficients (`0.94`, `1.06`, `0.91`);
- those transformed phases are not equivalent across the wrap, so a visible cut was inevitable;
- click also added a direct local height patch, making the discontinuity more obvious.

Fix:

- forcing phase remains internal to the physical pump/state integrator;
- shader no longer receives or renders the wrapped forcing phase;
- visual modal phases are unwrapped and continuous;
- touch modifies modal energy/detuning only, with smooth decay;
- direct click-local shader bump was removed;
- full-resolution surface shading was rebuilt with continuous harmonics, finite-difference normals and material response.

Status: **REPO_VALIDATED, HOST_VALIDATION_REQUIRED**.

## High-fidelity batch 031–035

All five use deterministic seed provenance and implemented signatures recorded in `creative_draw_space.json`.

### 031 FOLD CHAMBER

- vector-resolution Delaunay triangulated relief;
- 150 irregular vertices, neighbour-constrained spring surface;
- autonomous physical loads + pressure injection;
- per-facet normals/material shading and stressed hairline seams;
- no coarse image texture as final output.

### 032 LUMEN SWARM

- MultiMesh path, up to 900 luminous streak instances;
- inertial source + spatial flow/advection;
- source can be moved by touch without population reset;
- separate halo/core instancing for detail and depth.

### 033 OBSIDIAN CATHEDRAL

- full-resolution raymarched SDF architecture;
- AO, normals, micro-facets, roughness/specular, spectral grazing response;
- persistent fracture state from touch affects material/stress and mechanical orientation;
- no shader TIME / no loop choreography.

### 034 PHOSPHOR SAND

- 128×72 temporal memory field is **hidden state only**;
- final visible image is a full-resolution shader material with state gradients, optical relief, FRAGCOORD micro-grain, particulate highlights and spectral response;
- touch writes memory; autonomous events occur only after the material genuinely settles.

### 035 DUNE CHOIR

- actual damped 2D wave PDE;
- output is dense antialiased perspective vector topography, not an enlarged grid texture;
- longitudinal seams + curvature-derived peak glints provide multiple scales of detail;
- autonomous excitation is hysteretic and only returns after energy decays.

Code batch CI #287 passed repository policy, Godot 4.7.1 import, main-scene smoke and tracked-file cleanliness before the subsequent documentation commits.

## Visual-finish contract

Read `knowledge/cross-domain/VISUAL_FINISH_GATE.md` for all future substantial creative work.

Hard requirements now include:

- strong frozen frame before motion is considered;
- authored composition / negative space;
- at least three useful detail scales where appropriate;
- final PROGRAM image must be full-resolution in appearance;
- coarse solvers may drive state but may not simply be visibly scaled up;
- material/light should support the claimed carrier;
- no phase-wrap seam, reset, respawn wall or synchronized visible restart;
- interaction must enter system state/material logic, not overlay a cursor effect.

## Required next host test

1. Launch: workstation should appear directly in its remembered logical state, with no small-window/fullscreen hop.
2. Custom Maximize/Restore several times: it must stay stable and must not become native fullscreen.
3. Close/reopen once expanded, then once windowed/moved/resized: each state should restore coherently.
4. FARADAY QUASI: idle 30 s, then click/hold/drag/release repeatedly. There must be no global cut or click seam.
5. Open 031–035 at large PREVIEW/fullscreen PROGRAM resolution. Judge frozen frame first, then idle motion, then interaction/recovery.
6. RATE 031–035 normally.
7. Close normally; next AI must inspect fresh telemetry first and verify the close publication is non-empty before trusting ratings.

## Non-regressions

Do not stop PROGRAM on navigation, create independent linked timelines, block Godot UI with telemetry Git work, restore failed cross-window texture sampling, fake Spout/NDI, restore Pressure Lattice, make glyph contours a default representation, restore permanent all-tags UI, reintroduce fixed 1280×720 ShaderSurface nodes, restore transparent native RATE popup, use naked global-clock wobble as generic aliveness, or expose coarse simulation pixels as the final visual simply because the solver is convenient.
