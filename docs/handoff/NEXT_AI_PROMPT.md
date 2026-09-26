# NEXT AI PROMPT — DC//LAB

Resume from the repository, not from assumptions.

## Repository position

- repo: `Rzbck/godot-creative-lab`
- active branch: `feat/creative-sketches-002-004-20260924`
- draft PR: #7
- base: `feat/gallery-project-workflow-20260923`
- never merge/change `main` without explicit user approval
- expected source catalogue: **001–055**

Read `docs/handoff/CURRENT_WORK.md` and `docs/handoff/project_state.json` first.

## Mandatory first action after the user's host test

Inspect fresh `telemetry/runtime` before repairing or generating anything. Written RATE comments are first-class evidence and the user should not have to repeat them in chat.

The latest observed checkpoint before 051–055 was built was on telemetry HEAD `c8681daea3d1566c95b522658ad348a8d07415b4`, session `6b82f797db3cfd8d`. The session blob was too large for the connector to reconstruct every 047–050 review during the generation pass. Do not invent missing ratings or notes.

Confirmed evidence at that boundary:
- user said 046–050 were already better and asked to advance to the next series;
- 046 INK SHEAR = visual 4 / interaction 2 / originality 4 / aliveness 2 / controls 2 / performance 1;
- earlier durable failures: weak physical feel, unreadable interaction, controls that appear ineffective, visible coarse pixels, missing reset, incomprehensible/weak visual concepts.

## Current new batch awaiting host rating

### 051 CAPILLARY BRIDGE
84 droplets, persistent pointer-written wet zones, bounded capillary attraction. Test isolated beads vs bridges/clusters with surface tension, wetting, evaporation, reach, feed and inertia.

### 052 FIBER MEMORY
42 x 13 fiber field. Pointer combs directly and writes persistent directional memory; twist couples neighboring strands. Clock terms are only low-amplitude autonomous-current modulation, documented with `TEMPORAL_INTENT`.

### 053 AVALANCHE BED
Continuous 96-column granular ridge. Pointer above surface adds mass; pointer in/below surface excavates. Repose, cohesion and compaction should visibly change flow vs stable steep cuts.

### 054 HINGE CHOIR
8 x 8 coupled mechanical levers. Direct manipulation stores angular energy and propagates through neighbors. Clock phase only shapes decaying stored impulse ringing and is documented with `TEMPORAL_INTENT`.

### 055 SNAP LATTICE
16 x 9 large bistable folded facets. Pointer injects local snap-through; barrier/coupling/bias/damping should move behavior from isolated snaps to cascades and persistent domains.

All five use `canvas_geometry`; there are zero new fullscreen shaders in 051–055. This is deliberate to prioritize tangible causality and runtime cost after 046's performance score of 1.

## Validation state

Implementation/fix HEAD before durable docs: `25cb01539d0b4b767140dab79ee9215e739d1a44`.
CI #348 passed completely on that exact implementation HEAD:
- repository policy;
- temporal audit;
- adaptive creative draw self-test;
- Godot 4.7.1 import;
- main-scene smoke;
- tracked cleanliness.

An earlier run #346 failed only because 052/054 direct clock trigonometry lacked explicit `TEMPORAL_INTENT`; that was fixed before #348.

The final documentation HEAD is newer than the implementation HEAD and must also have exact-head CI green before handoff is considered complete.

## What to judge in the next host session

1. Gallery source count must be 55.
2. Watch each 051–055 for ~20–30 seconds at defaults.
3. Interaction must be immediately understandable.
4. Release must leave meaningful material/system state where intended.
5. Move every parameter through a large range. If it appears to do nothing, treat it as a failure.
6. Compare materially different regimes rather than cosmetic intensity.
7. Pay close attention to runtime/performance.
8. Reset must return to a usable state.
9. Keep PREVIEW/PROGRAM persistence and all existing Gallery contracts intact.
10. Let the user RATE + write WHY/NOTES normally; consume telemetry automatically afterward.

## Product contracts that must not regress

- PROGRAM persists across navigation; TAKE LIVE explicitly replaces it.
- linked PREVIEW/PROGRAM share timeline/state.
- physical PROGRAM touch/mouse works.
- per-sketch parameters persist.
- real Gallery thumbnails; idle frozen, hover live.
- adaptive bounded tag rail; no permanent all-tags wall.
- TRASH is exclusive/local only and never deletes Git source.
- GRID/LIST, sorting, grid size and compact ~68 px LIST remain.
- PREV/NEXT changes PREVIEW only and must not silently replace PROGRAM.
- mutable ShaderMaterial state stays local per scene instance.
- RATE is opaque/centered/in-app and written notes are first-class evidence.
- no fake Spout/NDI.

## Creative rules

Do not clone a high-scoring sketch. Reuse qualities, not surfaces. Controls must create visible regime/composition changes. Interaction must be immediate and stateful. Hidden coarse simulation is acceptable; visible solver pixels are not finished artwork. Technical diversity is not proof of visual quality. Generic direct-clock wobble is rejected as default aliveness.

`knowledge/cross-domain/creative_draw_space.json` includes history through 055; use it to avoid accidental collisions.

## Completion contract

Any material change must follow: code/push -> durable docs/state -> exact remote HEAD -> exact-head CI -> report SHA/result. Keep PR #7 draft unless the user explicitly asks otherwise. Never merge/change `main` without explicit approval.
