# HANDOFF — DataC0re Creative Lab

Canonical restart point for a new human or AI session.

**Always resolve the current remote branch HEAD and exact-head CI before trusting recorded SHAs.** Repository state is authoritative; chat history is secondary.

Last material refresh: **2026-09-24**.

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

## Historical creative state

001–010 remain available. `005_pressure_lattice` visibly remains **REGISTER TYPE**; original Pressure Lattice is rejected. A generalized contour pass (`6c20a094...`) across 006–010 was host-rejected because several glyphs looked broken/inverted and the series converged around one technique. Do not restore it.

## Collision-first batches

### 011–015

First raw collision batch:

- **SWARM RELAY** — agents + dynamic graph;
- **CHEMICAL BLOCKS** — Gray-Scott reaction-diffusion;
- **CUT CELL** — nearest-site territories + cut/healing graph;
- **RIBBON MORPH** — raster morphology + ribbons;
- **PHASE PACK** — packed bodies + phase rules + distance field.

Host feedback: technically/creatively better than the earlier type-heavy direction, but still visually weak, under-parameterized (3 controls each) and not organic enough in how pixels/cells influence one another.

Telemetry confirmed 15 Gallery previews loaded on runtime head `6dd4b307...`; treat that feedback as primarily creative/systemic.

### 016–020 — current batch

Blind draw seed: `202609242031`.

- `016_predator_vein` / **PREDATOR VEIN** — nutrient nodes + dynamic graph + neighbour field cohesion + persistent predators/scars; 8 controls.
- `017_edge_bloom` / **EDGE BLOOM** — 64×36 edge-fed excitable tissue + refractory state + spores that follow/deposit/split; 9 controls.
- `018_current_memory` / **CURRENT MEMORY** — 52×30 wave membrane + delayed field memory + particle current + dynamic reconnection + asymmetric void; 9 controls.
- `019_soft_flock` / **SOFT FLOCK** — boid population + Verlet constraint membrane + link erosion/repair + persistent obstacle; 9 controls; two colors only.
- `020_echo_tissue` / **ECHO TISSUE** — 72×40 eight-neighbour excitable tissue + density morphology + refractory memory + delayed feedback + autonomous reseeding; 9 controls.

Implementation commit: `e2ff8328532a4eab057c63b8bd1d361bc706ba15`.
CI #221 passed Godot 4.7.1 import, main-scene smoke and tracked-file cleanliness for that runtime commit.

All 016–020 use the shared live-sync contract so linked PREVIEW/PROGRAM should represent the same generative state.

## Durable creative rules from host feedback

Read `knowledge/cross-domain/ORGANIC_COUPLING_AND_CONTROLS.md`.

Key rules:

1. substantial collision labs normally expose **6–9 meaningful independent controls** when the mechanism supports them;
2. controls describe real system dimensions, not aliases for `more effect`;
3. at least half the controls should alter future evolution, not only the current frame;
4. cellular/raster work claiming organic behavior must exchange state through neighbours/resources/pressure/phase/delay/constraints;
5. prefer several time scales: immediate response + slower memory/repair/transport/fatigue;
6. raw collision-first work can be exploratory, but Gallery promotion still requires a coherent default palette/composition and respectable frozen frames;
7. interaction should perturb a living system and leave consequences the system redistributes.

## Creative research method

Preferred current exploration mode remains collision-first:

`blind technical collision -> coupled raw prototype -> observe -> interpret -> art-direct -> mutate`

Read in priority order:

1. `knowledge/cross-domain/TECHNIQUE_PALETTE.md`
2. `knowledge/cross-domain/RANDOM_COLLISION_ENGINE.md`
3. `knowledge/cross-domain/COLLISION_SOURCE_CATALOG.md`
4. `knowledge/cross-domain/ORGANIC_COUPLING_AND_CONTROLS.md`
5. relevant design/creative-coding atlases
6. `CROSS_DOMAIN_ATLAS.md` / `IDEA_ENGINE.md` when a successful mechanism deserves a real identity pass.

No technique is the default house style. Random stacking without state coupling is rejected.

## Next host validation

Expected Gallery count after current batch: **20 sketches**.

For 016–020:

1. inspect default visual state before moving sliders;
2. watch 20–30 seconds hands-off;
3. interact once, remove input and watch propagation/repair/migration;
4. then explore the 8–9 controls and verify they create different regimes;
5. test strongest candidates in PROGRAM/touch;
6. inspect fresh `telemetry/runtime` immediately after the test.

The next decision is not automatically another batch. First decide which 016–020 mechanisms are visually/behaviorally worth promoting, mutating or killing.

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

Do not casually reintroduce root-window fullscreen as normal PROGRAM output, the failed cross-window texture path, synchronous telemetry network work, independent linked PREVIEW/PROGRAM simulations, Gallery overlays over cards, fake Spout/NDI, Pressure Lattice, project metadata inside artwork, or glyph contours as the default creative representation.

See `docs/handoff/CURRENT_WORK.md` for detailed current work and `docs/handoff/OPERATIONS.md` for the canonical exact-CI PowerShell.
