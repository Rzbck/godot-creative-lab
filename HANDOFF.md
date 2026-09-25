# HANDOFF — DataC0re Creative Lab

Canonical restart point. Resolve the real remote branch HEAD and its exact-head CI before trusting any recorded SHA. Repository state + matching host telemetry beat chat history.

Last material refresh: 2026-09-25.

## Repository

- GitHub: `Rzbck/godot-creative-lab`
- local root: `E:\_Project\GodotCreativeLab`
- Godot GUI: `C:\Godot\Godot_v4.7.1-stable_win64.exe`
- Godot console: `C:\Godot\Godot_v4.7.1-stable_win64_console.exe`
- active branch: `feat/creative-sketches-002-004-20260924`
- draft PR: #7
- PR base: `feat/gallery-project-workflow-20260923`
- never merge/change `main` without explicit user approval

## Stable product contract

PROGRAM persists across Gallery/Settings/other PREVIEW. `TAKE LIVE` replaces PROGRAM explicitly. Physical PROGRAM touch/mouse remains supported. Linked PREVIEW/PROGRAM share one generative state/timeline. Per-sketch parameters persist. Gallery cards use real thumbnails; only hovered previews animate. Search/filter/group metadata comes from `definition.json`. PROGRAM is artwork-only. Telemetry publishing stays asynchronous/non-blocking. REVIEW stays compact; local Trash never deletes Git source.

Current top runtime: `res://app/main/main_runtime_window_memory.gd`.
Current source catalogue: **001–040**.

## Latest host evidence / creative reset

The host rejected 026–030 numerically and 031–035 qualitatively. Do not treat technical diversity as evidence of artistic success.

Recovered `creative_preference_snapshot` from intermediate telemetry session `003706451ab202f2` contains 21 reviewed sketches. Important new vectors:

- 026 VOID TENSION — 1,1,1,1,1,1; avg 1.0.
- 027 GLASS TIDE — 2,1,1,1,1,1; avg ~1.17.
- 028 LUMEN MAZE — all 1; avg 1.0.
- 029 FIBER FELT — all 1; avg 1.0.
- 030 REACTOR SKIN — all 1; avg 1.0.

Updated 21-review axis averages are approximately:

- visual 2.0
- interaction 1.857
- originality 1.857
- aliveness 1.619
- controls 1.762
- performance 2.571

Earlier positive evidence remains:

- 020 ECHO TISSUE ~4.17
- 012 CHEMICAL BLOCKS ~3.33
- 017 EDGE BLOOM ~2.83

031–035 have no trustworthy numeric snapshot; host direct verdict is simply “pas fameux”. Never invent scores.

## Visual finish is now a hard workflow stage

Read `knowledge/cross-domain/VISUAL_FINISH_GATE.md`.

Required pipeline:

`adaptive draw -> prototype -> observe -> mutate -> art-direct -> visual-finish gate -> keep/reject`

The adaptive draw engine is a collision generator, not an art director. Technical novelty alone is insufficient.

For substantial kept work the final image should satisfy:

- frozen frame already works as an image;
- authored composition and useful negative space;
- material/light logic appropriate to the claimed carrier;
- multiple useful detail scales;
- coarse simulation may drive state but may not simply be enlarged as final art;
- no phase-wrap seam, visible reset, respawn wall or synchronized restart;
- interaction enters state/material logic instead of overlaying a cursor effect.

Since sketch 036, `scripts/ci/validate_repository.py` requires a machine-readable `visual_finish` block in `definition.json` with composition, material model, final render path, at least three detail scales and `interaction_stateful=true`. CI does not judge beauty; it prevents skipping the finish stage.

## Batch 036–040 — current host-validation target

All definitions include `creative_seed`, `creative_signature` and `visual_finish`. Actual implemented signatures are recorded in `knowledge/cross-domain/creative_draw_space.json`.

### 036 POLAR STRESS

Photoelastic stressed glass / birefringence.

- four persistent load anchors with damped state;
- analytic stress tensor and principal stress difference;
- polarized interference fringes, gradient caustics and pixel-scale glass grain;
- touch relocates and strengthens a real load;
- full-resolution CanvasItem shader; no shader TIME;
- 8 controls.

### 037 DENDRITE BLOOM

Anisotropic crystal growth.

- hidden 96×54 phase/nutrient/age solver at fixed simulation cadence;
- neighbour exchange, nutrient depletion and remelting;
- touch locally seeds material/nutrient;
- final full-resolution shader reconstructs mineral relief, growth-front facets, translucency and micro grain;
- 9 controls.

### 038 ELECTRIC LACE

Electrostatic vector engraving.

- five stateful charges;
- dozens of field lines integrated through the actual field and rebuilt at simulation cadence;
- antialiased vector halo/core rendering rather than a coarse bitmap;
- touch grabs/moves nearest charge and changes the entire topology;
- 8 controls.

### 039 SOAP CONSTELLATION

Pressure-coupled soap cells / thin-film optics.

- eight bubbles with velocity, radius and pressure state;
- pairwise surface-tension relaxation and state-dependent autonomous events;
- touch loads/moves a bubble;
- full-resolution SDF-like thin-film material with interference, seams and micro pearlescence;
- 9 controls.

### 040 SCHLIEREN VEIL

Density/heat/velocity fluid field rendered as schlieren imagery.

- hidden 80×45 coupled fluid state at 30 Hz;
- neighbour diffusion, advection, buoyancy/vorticity and three reservoir-driven plumes;
- touch injects heat, density and vorticity;
- final full-resolution shader renders density gradients, knife-edge response and micro refractive detail;
- 9 controls.

The first CI attempt (#296) caught invalid `SCREEN_PIXEL_SIZE` usage in CanvasItem shaders. 036/037/039/040 now use logical 16:9 aspect and `FRAGCOORD` for pixel-scale detail. Runtime correction commit `bebe9fe8...` passed CI #297 completely before the final documentation commits.

## Workstation window revision 3

The previous host test on `672385c8...` logged:

`ERROR: Can't change visibility of main window.`

Root cause: revision 2 called `root_window.visible = false` in `_enter_tree()`. Godot 4.7.1 does not allow changing visibility of the main window.

Revision 3:

- never toggles main Window visibility;
- applies saved screen/mode/rect directly in `_enter_tree()` before the first scene frame;
- custom Maximize remains borderless WINDOWED usable-screen geometry with a 2 px bottom guard, never the native fullscreen path;
- F11 artwork presentation remains separate;
- window state still persists in `user://creative_lab_window_state.cfg`.

Status: repository/CI validated, Windows host validation required.

## Telemetry close fix

The latest host console showed the final publisher starting and then the terminal was interrupted with `Ctrl+C`; latest close publication became empty. Intermediate publication was still recoverable and supplied the 026–030 ratings.

Revision 3 close path now:

- emits `session_close_request`;
- flushes telemetry;
- releases the `FileAccess` handle before publisher spawn;
- starts PowerShell hidden;
- quits Godot after the final publisher has been started.

Host test must close normally and allow the publisher to finish. Next AI should inspect `telemetry/runtime` first and require non-empty matching telemetry before trusting new ratings.

## FARADAY QUASI

Old cut root cause was mathematically real: a wrapped forcing phase was multiplied by fractional shader coefficients, making transformed visual phases discontinuous at wrap; click also added a direct visible height bump.

Current 025 keeps forcing phase internal, uses continuous visual modal phases and touch modifies modal state instead of drawing a cursor-local bump. Still host-validate idle + repeated click/drag/release.

## Temporal-quality contract

Preferred:

`time -> force/state/memory/event -> coupled system -> render`

Rejected by default:

`time -> sin/cos -> visible position/scale/alpha/warp`

Periodic forcing can be valid physically, but the visible result still must not reveal a discontinuity or cheap clock. For 026+, direct clock trig requires `TEMPORAL_INTENT:`. Keep `knowledge/cross-domain/TEMPORAL_MOTION_QUALITY.md` and CI audit active.

## Adaptive creative draw

Read:

- `knowledge/cross-domain/ADAPTIVE_CREATIVE_DRAW.md`
- `knowledge/cross-domain/creative_draw_space.json`
- `scripts/creative/draw_recipe.py`

Recent/historical feature reuse is penalized. Explicit REVIEW evidence provides bounded probability bias only; 24% exploration remains preference-free. Record implemented/mutated signatures, not discarded raw draws.

## Review / curation

Sidebar remains `REVIEW <avg>/5  RATE  TRASH`. RATE is an opaque centered in-app modal. Reviews persist in `user://creative_lab_reviews.cfg`. Gallery cards show rating badges. Local Trash is reversible and never deletes version-controlled source.

## Full-canvas / performance

A node named `ShaderSurface` must use `res://sketches/_shared/full_canvas_surface.gd`; CI rejects legacy fixed 1280×720 surfaces. Dense solvers should use hidden state + appropriate final representation. Do not recompute expensive neighbourhood/contact work in `_draw()`.

## Required next host validation

1. Launch: no `Can't change visibility of main window` error; inspect whether remembered state appears cleanly.
2. Maximize/Restore several times, close/reopen expanded and windowed/moved states.
3. FARADAY QUASI: idle at least 30 s then repeated click/hold/drag/release; no cut.
4. Confirm source Gallery has 40 sketches before local curation.
5. Judge 036–040 first as frozen frames, then 20–30 s idle, then interact/remove hand.
6. RATE 036–040 on all six axes.
7. Close normally; do not Ctrl+C the publisher.
8. Next AI reads matching non-empty telemetry first: preference snapshot, window restore, surface/perf events.

## Historical non-regressions

- 001 remains technical foundation/reference.
- 005 internal path remains `005_pressure_lattice`, visible artwork **REGISTER TYPE**; never restore Pressure Lattice.
- generalized glyph-contour pass across 006–010 was host-rejected; never make contours the house representation.
- 026–030 are numerically rejected evidence; 031–035 qualitatively weak evidence.
- do not stop PROGRAM on navigation.
- do not create independent linked timelines.
- do not restore fixed ShaderSurface sizing.
- do not restore native transparent/off-centre RATE popup.
- do not toggle main-window visibility during startup.
- do not fake Spout/NDI.

## Mandatory completion protocol

After every material repository change: finish code, update durable docs/state when state changed, resolve final remote HEAD after all docs, wait exact-head CI, report exact short SHA + exact CI, automatically include canonical PowerShell when host validation is useful, then telemetry-first after the host test.
