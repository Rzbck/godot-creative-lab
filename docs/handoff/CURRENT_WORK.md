# Current work — DC//LAB

Last refreshed: 2026-09-26.

## Active branch / PR

- branch: `feat/creative-sketches-002-004-20260924`
- draft PR: #7
- base: `feat/gallery-project-workflow-20260923`
- never merge/change `main` without explicit user approval
- resolve final remote HEAD after all docs, then require CI on that exact SHA

## Current runtime / catalogue

Main scene: `res://app/main/main_runtime.tscn`.
Top runtime: `res://app/main/main_runtime_gallery_host_fixes.gd` -> `main_runtime_window_memory.gd` -> existing validated chain.
Source catalogue: **001–045** before local curation.

Preserve real Gallery thumbnails/hover animation, parameter persistence, PREVIEW/PROGRAM separation, persistent PROGRAM across navigation, TAKE LIVE, physical output input, linked state sync, artwork-only PROGRAM output and async telemetry.

## Host status

The user has **not yet performed a new host test** after the latest 037/038/040 fixes or after 041–045 were added. Treat current work as repo/CI validated only.

Prior direct feedback driving this pass:

- 037: coarse cells + stale/black-frame flashes during interaction/parameter scrub.
- 038: concept liked, but charges needed direct manipulation.
- 040: same stale-frame glitch.
- RATE needed free-text explanations.
- Gallery needed file-browser sort/view/size, visual LIST rows and a real Trash view.

## Gallery host fixes

A thin top layer `main_runtime_gallery_host_fixes.gd` isolates the new UX fixes from the lower runtime.

### LIST

The previous revision explicitly hid the card TextureRect. Current LIST builds a second card presentation that reuses the same SubViewport texture:

- preview left (~260 px wide);
- index/title/engine/tags/description right;
- row height ~132 px;
- GRID/LIST toggling does not recreate sketches.

### TRASH

The previous Trash button only opened a drawer while normal Gallery cards remained visible behind it. Current Trash is exclusive:

- normal `gallery_scroll`, search row and browser controls hide while Trash is open;
- only local Trash rows remain visible;
- normal tags/MORE exit Trash mode;
- restore/purge still never mutate Git source.

## Stateful shader fixes retained

Shared mutable ShaderMaterial was the architectural stale-frame root cause. Permanent contract:

- `resource_local_to_scene = true` on sketch ShaderMaterials;
- CI enforces it;
- PREVIEW/PROGRAM/thumbnail may share immutable Shader resources, never mutable uniform/texture state;
- 037/040 use double-buffer state textures and weighted state reconstruction;
- 044/045 were built with local materials and double-buffered state textures from the start.

038 keeps its positive concept but now uses direct visible-charge hit test/drag and release inertia; empty-space click grabs nothing.

## New 041–045 batch

### 041 TENSION ORGAN

Physical soft-body membrane: 17×10 constraint mesh, structural/diagonal springs, stochastic autonomous forcing through the material, direct node grab, residual release energy, stress-dependent facet material.

### 042 MYCELIUM RELAY

Branching agent ecology: chemotaxis, energy, moving nutrients and persistent trails. Dragging paints a nutrient path into the world; agents discover it later instead of following a cursor immediately.

### 043 SLIT MEMORY

Real temporal slicing: ten coupled channels and a 180-frame live history. User interaction writes persistent time folds into the history lookup, bending/compressing/repeating time while the source dynamics continue.

### 044 EXCITABLE GLASS

Hidden 96×54 excitable/refractory medium. Autonomous pacemakers drive waves. Quiet touch seeds excitation; active touch quenches it. Full-res multi-tap glass shader reconstructs relief/caustics/micro detail.

### 045 RIFT VOLUME

Full-res SDF raymarch with three toroidal masses and a folded membrane. Damped CPU anchors move without shader TIME. Touch writes a persistent scar field that erodes geometry and kicks nearby masses. AO/normals/mineral lighting finish the surface.

All five include live-sync state, `creative_signature` and `visual_finish` metadata.

## Code validation before docs

Code/UID HEAD: `c43be4300105e8677db22dd7c291a59d80fbc9f5`.
CI #307 fully green:

- Repository policy: success
- temporal audit: success
- adaptive draw self-test: success
- Godot 4.7.1 import: success
- main-scene smoke: success
- tracked cleanliness: success

First CI #305 had only one failure: Godot generated `.uid` files for the new scripts/shaders. Those UIDs were then versioned; no runtime/script/shader error was reported.

## REVIEW / telemetry

RATE revision 4 includes six numeric axes + `WHY / NOTES`, persisted locally and included in `creative_preference_snapshot`. Rating/note changes schedule a remote checkpoint ~0.8 s later.

Last useful remote ratings remain 031–035: 2.0, 1.5, 1.0, ~2.17, 1.0. The latest final close before this batch was empty. There is no trustworthy new numeric verdict for 036–045 yet.

## Creative rules

`VISUAL_FINISH_GATE.md` and `TEMPORAL_MOTION_QUALITY.md` remain mandatory.

- technical distance alone is not quality;
- frozen frame must work;
- interaction should alter state/topology/material/history;
- several useful detail scales;
- no coarse solver exposed as final artwork;
- no generic clock wobble, visible phase wrap, global reset or respawn wall.

## Next host validation

1. LIST: preview stays visible on left of each row.
2. TRASH: only Trash contents shown; test restore/purge and exit to normal Gallery.
3. 037/040: continuous parameter scrub + interaction, no old/black-frame flash.
4. 038: direct charge drag, empty-space no-op.
5. 041–045: frozen frame, 20–30 s idle, interaction/recovery, parameter extremes.
6. RATE with written WHY/NOTES.
7. Close normally; inspect telemetry first afterwards.

## Mandatory completion

After material changes: code -> durable docs/state -> exact final remote HEAD -> exact-head CI -> report SHA/result -> canonical PowerShell when host testing is useful -> telemetry-first after host test.
