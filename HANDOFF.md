# HANDOFF — DataC0re Creative Lab

Canonical restart point for a new human or AI session.

**Always resolve the current remote branch HEAD and exact-head CI before trusting recorded SHAs.** Repository state is authoritative; chat history is secondary.

Last material refresh: **2026-09-25**.

## Repository / active work

- GitHub: `Rzbck/godot-creative-lab`
- local workstation: `E:\_Project\GodotCreativeLab`
- Godot GUI: `C:\Godot\Godot_v4.7.1-stable_win64.exe`
- Godot console: `C:\Godot\Godot_v4.7.1-stable_win64_console.exe`
- active branch: `feat/creative-sketches-002-004-20260924`
- draft PR: `#7`
- PR base: `feat/gallery-project-workflow-20260923`
- never merge/change `main` without explicit user approval

## Product state to preserve

DC//LAB is a Godot creative-coding workstation with data-driven Gallery discovery, real thumbnails, hover previews, generated parameter inspector/persistence, PREVIEW / PROGRAM separation, persistent PROGRAM while navigating, `TAKE LIVE`, physical display selection, PROGRAM touch/mouse forwarding, linked PREVIEW/PROGRAM state synchronization, async telemetry and versioned creative research.

Normal logical artwork space: `1280×720`.

PROGRAM canvas is artwork-only: no sketch title/index/tags/debug/project metadata unless the text is genuinely part of the artwork.

## Gallery discovery / adaptive tags

The Gallery no longer renders every metadata tag permanently.

Top runtime layer is now:

`res://app/main/main_runtime_gallery_adaptive_filters.gd`

Runtime chain starts:

```text
main_runtime_gallery_adaptive_filters.gd
    -> main_runtime_gallery_organizer.gd
        -> main_runtime_program_output.gd
        -> ...
```

Adaptive filter contract:

- `ALL` always visible;
- max 6 generated quick tags in the permanent rail;
- quick tags are selected automatically from catalogue frequency/discrimination;
- universal tags matching the entire catalogue are omitted as useless filters;
- rare/singleton/remaining tags are inside a collapsed `MORE` drawer;
- selecting a rare tag promotes it into the compact rail while active;
- Gallery search still indexes every tag whether or not it is visible in the rail;
- primary Gallery groups still derive from the first `definition.json` tag;
- no per-sketch UI hard-coding or manually curated filter list is required.

This behavior exists specifically to keep Gallery discovery compact as sketch/tag count grows. Do not restore a permanent all-tags wall.

Runtime CI #233 passed policy, Godot 4.7.1 import, main-scene smoke and cleanliness for the adaptive filter runtime state. Host validation of layout/interaction is still pending.

## Historical creative state

001–010 remain available. `005_pressure_lattice` visibly remains **REGISTER TYPE**; original Pressure Lattice is rejected. A generalized contour pass (`6c20a094...`) across 006–010 was host-rejected because several glyphs looked broken/inverted and the series converged around one technique. Do not restore it.

## Collision-first evolution

### 011–015

First raw collision batch:

- **SWARM RELAY** — agents + dynamic graph;
- **CHEMICAL BLOCKS** — Gray-Scott reaction-diffusion;
- **CUT CELL** — nearest-site territories + cut/healing graph;
- **RIBBON MORPH** — raster morphology + ribbons;
- **PHASE PACK** — packed bodies + phase rules + distance field.

Host feedback: technically/creatively better than the earlier type-heavy direction, but visually weak, under-parameterized (3 controls each) and not organic enough in how pixels/cells influence one another.

### 016–020

Blind draw seed: `202609242031`.

- `016_predator_vein` / **PREDATOR VEIN** — nutrient graph + neighbour field + predators/scars; 8 controls.
- `017_edge_bloom` / **EDGE BLOOM** — excitable tissue + refractory state + spores; 9 controls.
- `018_current_memory` / **CURRENT MEMORY** — wave membrane + delayed memory + particle current; 9 controls.
- `019_soft_flock` / **SOFT FLOCK** — boids + Verlet membrane + erosion/repair; 9 controls.
- `020_echo_tissue` / **ECHO TISSUE** — eight-neighbour tissue + morphology + delayed feedback; 9 controls.

Host feedback: clearly better / starting to become interesting, but real-world physical/chemical matter was still missing and some sketches appeared to fall below the user's very high smooth-FPS baseline.

017 and 020 were subsequently optimized structurally:

- dense cellular fields render through low-resolution `ImageTexture` instead of thousands of CanvasItem primitives per frame;
- 020 caches neighbour density during simulation instead of rescanning neighbourhoods in draw.

Remote telemetry for that host test was stale and corresponded to the older 011–015 runtime, so do not claim exact per-sketch FPS from it.

## 021–025 — physical / chemical collision labs

Blind draw seed: `202609250742`.

- `021_rosensweig_field` / **ROSENSWEIG FIELD** — magnetic threshold + coupled peak modes + viscosity/hysteresis; 8 controls; fullscreen shader.
- `022_liesegang_front` / **LIESEGANG FRONT** — diffusion + supersaturation + precipitation/depletion/dissolution bands; 8 controls.
- `023_spinodal_marangoni` / **SPINODAL MARANGONI** — conserved-ish phase field + thermal quench + Marangoni-style advection; 9 controls; low-res texture field.
- `024_granular_jam` / **GRANULAR JAM** — packed grains + contacts + force chains + creep + delayed avalanche; 9 controls.
- `025_faraday_quasi` / **FARADAY QUASI** — parametric resonance + mode competition + standing-wave shader; 8 controls.

Runtime commit: `50e7d9f9296768a09a56c7a8f7ac421a4d823389`.
CI #224 passed Godot 4.7.1 import, main-scene smoke and tracked-file cleanliness for that runtime commit.

## Durable creative rules

Read:

- `knowledge/cross-domain/TECHNIQUE_PALETTE.md`
- `knowledge/cross-domain/RANDOM_COLLISION_ENGINE.md`
- `knowledge/cross-domain/COLLISION_SOURCE_CATALOG.md`
- `knowledge/cross-domain/PHYSICAL_CHEMICAL_SYSTEMS_ATLAS.md`
- `knowledge/cross-domain/ORGANIC_COUPLING_AND_CONTROLS.md`
- `knowledge/cross-domain/REALTIME_PERFORMANCE_BUDGET.md`

Current rules:

1. substantial collision labs normally expose **6–9 meaningful independent controls** when mechanism supports them;
2. at least half the controls should alter future evolution, not only current rendering;
3. cellular/raster work claiming organic behavior must exchange state through neighbours/resources/pressure/phase/delay/constraints;
4. prefer several time scales: immediate response + slower memory/repair/transport/fatigue;
5. raw collision-first work still requires a coherent default palette/composition and respectable frozen frames;
6. interaction should perturb a living system and leave consequences the system redistributes;
7. real-world science references must preserve at least one genuine causal relationship/threshold instead of borrowing surface appearance only;
8. performance architecture matters: dense fields should use texture/shader representations when appropriate, simulation cadence should be separated from render cadence, and expensive neighbourhood/contact calculations should not be repeated just for drawing.

Preferred exploration mode remains:

`blind technical/phenomenon collision -> coupled prototype -> observe -> interpret -> art-direct -> mutate`

No technique is the default house style. Random stacking without state coupling is rejected.

## Next host validation

Expected Gallery count: **25 sketches**.

First validate adaptive Gallery tags:

1. default filter area shows `ALL`, at most six quick tags and optional `MORE`;
2. universal tags such as a 25/25 tag do not occupy permanent space;
3. `MORE` reveals rare/remaining tags and is closed by default;
4. selecting a rare tag promotes it into the compact rail while active;
5. hidden tags remain searchable;
6. resize does not recreate the original multi-row tag wall.

Then continue artwork/performance validation:

1. compare 017 + 020 smoothness after optimization;
2. watch 021–025 for 20–30 seconds at defaults;
3. interact, release, observe delayed physical/chemical consequences;
4. explore the 8–9 controls;
5. test strongest mechanisms on PROGRAM/touch;
6. close normally so telemetry can publish;
7. inspect fresh `telemetry/runtime` and require a matching tested HEAD/session before attributing FPS.

## PROGRAM / LIVE OUT architecture

Navigation is not transport. PROGRAM must continue while browsing Gallery/Settings or opening another PREVIEW. `TAKE LIVE` replaces PROGRAM. Linked output follows synchronized source state; detached PROGRAM continues autonomously from the last synchronized state.

Inspect `res://app/main/main_runtime.tscn` and its actual `extends` chain before changing host architecture.

## Telemetry-first debugging

After any host runtime test:

1. inspect branch `telemetry/runtime`;
2. read `latest.jsonl` and relevant session data;
3. verify telemetry corresponds to the tested HEAD/session;
4. only ask for manual logs/screenshots if telemetry genuinely lacks the evidence.

## Mandatory AI completion protocol

After every material repository change, before final response:

1. finish intended feature-branch commits;
2. update `CURRENT_WORK.md`, this handoff, `project_state.json`, `NEXT_AI_PROMPT.md` and `OPERATIONS.md` where durable state/workflow changed;
3. resolve the final remote branch HEAD **after all code + docs commits**;
4. wait for and inspect CI for that exact SHA;
5. report exact short HEAD + CI result;
6. when host validation is relevant, automatically include the canonical PowerShell from `OPERATIONS.md` that syncs, waits for exact-head CI success and only then launches Godot;
7. after the user tests, inspect telemetry first.

## Rejected regressions

Do not casually reintroduce root-window fullscreen as normal PROGRAM output, the failed cross-window texture path, synchronous telemetry network work, independent linked PREVIEW/PROGRAM simulations, Gallery overlays over cards, permanent all-tags filter walls, fake Spout/NDI, Pressure Lattice, project metadata inside artwork, or glyph contours as the default creative representation.

See `docs/handoff/CURRENT_WORK.md` for detailed current work and `docs/handoff/OPERATIONS.md` for the canonical exact-CI PowerShell.
