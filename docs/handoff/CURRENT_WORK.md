# Current work — DC//LAB

Last refreshed: 2026-09-25.

## Active branch / PR

- branch: `feat/creative-sketches-002-004-20260924`
- draft PR: #7
- base: `feat/gallery-project-workflow-20260923`
- never merge/change `main` without explicit user approval
- final remote HEAD + exact-head CI are authoritative

## Stable product behavior

Preserve Gallery real previews/hover animation, adaptive search/filtering, parameter persistence, REVIEW/Trash, PREVIEW/PROGRAM separation, persistent PROGRAM across navigation, TAKE LIVE, physical output input, linked state sync, full-canvas output and async telemetry.

Current top runtime: `app/main/main_runtime_window_memory.gd`.
Source catalogue after this pass: **001–040**.

## Host evidence that drove this pass

The latest host log on `672385c8...` showed `ERROR: Can't change visibility of main window` from `main_runtime_window_memory.gd:_enter_tree`. Main-window visibility toggling is rejected on Godot 4.7.1.

Intermediate telemetry session `003706451ab202f2` recovered ratings that had previously looked lost:

- 026 = all 1 (avg 1.0)
- 027 = 2 visual, all other axes 1 (avg ~1.17)
- 028 = all 1
- 029 = all 1
- 030 = all 1

21-review axis averages: visual ~2.0, interaction ~1.857, originality ~1.857, aliveness ~1.619, controls ~1.762, performance ~2.571.

031–035 have no trustworthy numeric snapshot; host direct verdict is “pas fameux”. Treat 026–035 as evidence that technical diversity and more rendering detail still do not automatically create strong artwork.

## New creative quality contract

`knowledge/cross-domain/VISUAL_FINISH_GATE.md` is mandatory for substantial work.

Pipeline:

`draw -> prototype -> observe -> mutate -> art-direct -> visual-finish gate -> keep/reject`

Since 036, CI requires each definition to declare `visual_finish` with composition, material model, final render, >=3 detail scales and stateful interaction. This is a process guard only; RATE/host judgment remains the aesthetic authority.

## Batch 036–040

### 036 POLAR STRESS

- photoelastic/birefringent stressed glass;
- four persistent stress anchors;
- analytic principal stress field;
- polarized spectral fringes, edge caustics, micro glass grain;
- touch changes a real load;
- full-resolution shader, 8 params.

### 037 DENDRITE BLOOM

- anisotropic crystal phase growth + nutrient depletion/remelting;
- hidden 96x54 neighbour-coupled solver;
- full-resolution faceted mineral material and micrograin;
- touch seeds local future growth;
- 9 params.

### 038 ELECTRIC LACE

- five stateful charges;
- antialiased vector field-line integration/rebuild;
- line halo + hairline core;
- touch moves a charge, globally recomputing topology;
- 8 params.

### 039 SOAP CONSTELLATION

- eight pressure/radius/velocity soap cells;
- pairwise surface-tension relaxation;
- full-resolution thin-film interference/seams/pearly detail;
- touch loads and moves a cell;
- 9 params.

### 040 SCHLIEREN VEIL

- hidden 80x45 density/heat/velocity field;
- advection, diffusion, buoyancy and vorticity;
- reservoir-driven plumes rather than synchronized reset;
- full-resolution density-gradient schlieren material;
- touch injects heat/density/vorticity;
- 9 params.

First runtime CI #296 caught invalid CanvasItem `SCREEN_PIXEL_SIZE` use. Corrected 036/037/039/040 to use logical design aspect + `FRAGCOORD` microdetail. Runtime commit `bebe9fe8...` passed CI #297 fully.

## Window-state revision 3

`main_runtime_window_memory.gd` no longer touches `root_window.visible`.

- state applied in `_enter_tree()` as mode/screen/geometry only;
- custom Maximize remains borderless WINDOWED work-area geometry with 2 px bottom guard;
- F11 remains independent artwork presentation;
- saved state remains `user://creative_lab_window_state.cfg`.

Needs Windows host validation.

## Telemetry close revision

Previous close publisher could race with an open telemetry handle; user also interrupted final publisher with Ctrl+C. Revision 3 flushes and releases the `FileAccess` handle before spawning hidden PowerShell publisher. Host validation must close normally and confirm a non-empty final session/latest.

## FARADAY QUASI

Current fix removes wrapped forcing phase from visible shader coordinates and removes direct click-local height bump. Test idle 30 s then click/hold/drag/release repeatedly. Any global seam/cut remains a blocker.

## Temporal / performance rules

- no generic `time -> sin/cos -> visible wobble`;
- no visible phase wrap/reset/respawn wall;
- low-res state is allowed only behind a higher-quality final representation;
- `ShaderSurface` uses shared full-canvas sizing;
- neighbour/contact work belongs in simulation cadence and is not duplicated in `_draw()`.

## Next host test

1. launch with no main-window visibility error;
2. test Maximize/Restore + close/reopen window state;
3. test FARADAY cut;
4. confirm 40 source cards;
5. judge 036–040 frozen frame, idle motion, interaction/recovery;
6. RATE all five;
7. close normally and let telemetry publisher finish;
8. next AI inspects matching telemetry first.

## Mandatory completion

After material changes: code -> durable docs -> exact final remote HEAD -> exact-head CI -> report SHA/result -> canonical PowerShell if host test useful -> telemetry-first after host test.
