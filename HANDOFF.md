# HANDOFF — DataC0re Creative Lab

Canonical restart point. Resolve the real remote branch HEAD and exact-head CI before trusting any recorded SHA. Repository state + matching host telemetry beat chat history.

Last material refresh: 2026-09-26.

## Repository

- GitHub: `Rzbck/godot-creative-lab`
- local root: `E:\_Project\GodotCreativeLab`
- Godot GUI: `C:\Godot\Godot_v4.7.1-stable_win64.exe`
- Godot console: `C:\Godot\Godot_v4.7.1-stable_win64_console.exe`
- active branch: `feat/creative-sketches-002-004-20260924`
- draft PR: #7, base `feat/gallery-project-workflow-20260923`
- never merge/change `main` without explicit user approval

## Stable product contract

PROGRAM persists across Gallery/Settings/other PREVIEW. `TAKE LIVE` explicitly replaces PROGRAM. Physical PROGRAM touch/mouse is supported. Linked PREVIEW/PROGRAM share one state/timeline. Per-sketch params persist. Gallery uses real thumbnails and only the hovered preview animates. PROGRAM is artwork-only. Telemetry stays async/non-blocking. Local Trash never deletes Git source.

Top runtime: `res://app/main/main_runtime_gallery_host_fixes.gd`, which extends the validated `main_runtime_window_memory.gd` chain.
Source catalogue: **001–045** before local curation.

## Host-validation status

Important: the user has **not yet retested** the latest 037/038/040 fixes, Gallery fixes, or new 041–045 batch. Current status is repository/CI validated, host validation required. Do not turn CI success into an aesthetic or Windows-runtime verdict.

Latest direct host feedback before this batch:

- 037 DENDRITE BLOOM: coarse cell stair-stepping and stale/black-frame flashes on interaction/parameter scrub.
- 038 ELECTRIC LACE: positive concept signal (`vraiment sympa`) but interaction was too indirect.
- 040 SCHLIEREN VEIL: stale-frame glitch on click/parameter changes.
- RATE needed free-text explanations.
- Gallery needed deterministic sort, GRID/LIST, adjustable card size, visual list previews, and a real Trash view.

## Stateful shader contract

Gallery keeps real hidden sketch instances for thumbnails. PREVIEW, PROGRAM and thumbnail may instantiate the same PackedScene simultaneously. Mutable shader state must therefore never be shared.

Permanent rules:

- every sketch ShaderMaterial uses `resource_local_to_scene = true`;
- CI rejects future runtime scenes that omit it;
- stateful CPU→GPU textures should be committed atomically; 037, 040, 044 and 045 use double buffering;
- hidden coarse state is allowed, but final PROGRAM must reconstruct a high-resolution material/geometry rather than expose enlarged cells.

037/040 also use weighted reconstruction before final material/gradient shading. 038 now uses real charge hit-testing, direct drag, empty-space no-op and release inertia.

## Gallery host-feedback layer

`main_runtime_gallery_host_fixes.gd` is deliberately thin and sits above the already validated runtime chain.

### LIST

LIST is visual, not text-only:

- each row keeps a real live/frozen preview on the left (~260 px);
- index/title/engine/tags/description remain on the right;
- the existing SubViewport is reused, so changing GRID/LIST does not restart simulations.

### TRASH

TRASH is now an exclusive browser mode:

- opening TRASH hides normal Gallery scroll/search/browser controls;
- only locally removed/restorable items are shown;
- opening a normal tag/MORE exits Trash mode;
- restore/purge semantics remain local and never delete Git source.

## REVIEW revision 4

RATE stays opaque, centered and in-app. It contains six numeric axes plus `WHY / NOTES` text (max 2000 chars). Notes persist in `user://creative_lab_reviews.cfg`, are included in `creative_preference_snapshot`, and rating/note edits schedule an async telemetry checkpoint ~0.8 s later. `SAVE REVIEW` persists explicitly; modal close also saves pending text.

## New batch 041–045

### 041 TENSION ORGAN

- physical 17×10 membrane / constraint mesh;
- structural + diagonal springs, rest tension, damping;
- stochastic target events drive force through the material rather than direct clock wobble;
- direct node grab/drag with residual release velocity;
- stress-dependent filled facets + fine tension threads;
- 6 systemic controls.

### 042 MYCELIUM RELAY

- branching agent ecology up to 72 active tips;
- autonomous nutrient basins plus persistent user-painted nutrient trails;
- chemotaxis, energy, branching and path memory;
- interaction paints future conditions instead of dragging an object;
- persistent hyphal graph/trails with growing tips;
- 6 systemic controls.

### 043 SLIT MEMORY

- ten coupled state channels with a real 180-frame history buffer;
- final image is built from temporal slices of actual history;
- pointer creates persistent time folds that compress/repeat/bend local history lookup;
- underlying system keeps running; no fake shader-time slitscan;
- dense antialiased temporal filament rendering;
- 6 controls.

### 044 EXCITABLE GLASS

- hidden 96×54 excitation/refractory/age medium;
- autonomous pacemakers create state-driven wave fronts;
- quiet click seeds excitation; active click quenches it;
- double-buffered state texture;
- full-resolution multi-tap glass reconstruction with relief, caustics and micro grain;
- 7 controls.

### 045 RIFT VOLUME

- full-resolution SDF raymarch: three toroidal masses + folded connecting membrane;
- CPU-driven damped anchor motion, no shader TIME;
- hidden persistent scar/erosion field with diffusion and memory;
- touch scars/erodes the volume and kicks nearby masses;
- finite-difference normals, AO, mineral/specular/rim material;
- 7 controls.

All 041–045 have `creative_seed`, implemented `creative_signature`, `visual_finish` metadata and live-sync state.

## Validation

Implementation/UID batch before docs: `c43be4300105e8677db22dd7c291a59d80fbc9f5`.
CI #307 is fully green: repository policy, temporal audit, adaptive draw self-test, Godot 4.7.1 import, main-scene smoke and tracked cleanliness.

This is not the final completion SHA: after durable docs/signature history, resolve final HEAD and require exact-head CI again.

## Telemetry evidence

Latest remote final close before this batch was empty. Last useful intermediate snapshot recovered:

- 031 FOLD CHAMBER avg 2.0
- 032 LUMEN SWARM avg 1.5
- 033 OBSIDIAN CATHEDRAL avg 1.0
- 034 PHOSPHOR SAND avg ~2.17
- 035 DUNE CHOIR avg 1.0

036–045 have no trustworthy new numeric host verdict yet. Never invent one.

## Creative quality contract

Read `knowledge/cross-domain/VISUAL_FINISH_GATE.md` and `TEMPORAL_MOTION_QUALITY.md`.

Required pipeline:

`adaptive draw -> prototype -> observe -> mutate -> art-direct -> visual-finish gate -> keep/reject`

Technical diversity is not artistic quality. Frozen frame, material logic, composition, multiple useful scales and meaningful state interaction matter. Reject generic `time -> sin/cos -> visible wobble`, phase-wrap seams, global resets, respawn walls, coarse solver enlargement and superficial pointer overlays.

## Historical non-regressions

- 001 remains technical foundation/reference.
- 005 source stays `005_pressure_lattice`, visible artwork **REGISTER TYPE**; never restore Pressure Lattice.
- generalized glyph contours are not the house style.
- navigation never stops PROGRAM.
- linked outputs never have independent timelines.
- ShaderSurface remains full-canvas through the shared sizing component.
- ShaderMaterial mutable state stays local per scene instance.
- RATE stays opaque/centered/in-app.
- never toggle main-window visibility during startup.
- never fake Spout/NDI.

## Required next host validation

1. Sync exact final HEAD and require exact-head CI before launch.
2. Gallery LIST: verify real visual preview remains on the left of every row.
3. Gallery TRASH: opening it must hide normal cards; test restore/purge and exiting via normal filters.
4. Re-test 037/040 under click/drag + continuous parameter scrub: no stale/black flashes; 037 stair-stepping substantially reduced.
5. Re-test 038 direct charge grab; empty-space click must grab nothing.
6. Test 041–045 first as frozen frames, then 20–30 s idle, then interaction/recovery and parameter extremes.
7. RATE with numeric axes + WHY/NOTES.
8. Close normally; next AI inspects `telemetry/runtime` first.

## Mandatory completion protocol

After every material repository change: finish code, update durable docs/state, resolve final remote HEAD **after all docs**, wait exact-head CI, report exact short SHA + exact CI, automatically include canonical PowerShell when host validation is useful, then telemetry-first after host testing.
