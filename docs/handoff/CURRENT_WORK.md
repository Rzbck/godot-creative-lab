# Current work — DC//LAB

Last refreshed: 2026-09-26.

## Active branch / PR

- branch: `feat/creative-sketches-002-004-20260924`
- draft PR: #7
- base: `feat/gallery-project-workflow-20260923`
- never merge/change `main` without explicit user approval
- source catalogue: **001–055**
- top runtime: `app/main/main_runtime_gallery_host_fixes.gd`

## Feedback state consumed before 051–055

The feedback loop is telemetry-first and written RATE comments remain first-class evidence. The user explicitly reported that 046–050 were already better than the previous batch and asked to continue from those notes.

Confirmed bounded evidence available at the handoff boundary:
- 046 INK SHEAR: visual 4 / interaction 2 / originality 4 / aliveness 2 / controls 2 / performance 1.
- Earlier written feedback remains durable: 041 lacked physical feel and could visually break under strong pull; 042 needed stronger interaction and parameters that visibly change the result; 043 had unreadable/non-felt interaction; 044 was too pixelated, lacked reset and had weak controls; 045 was rejected visually/conceptually.

The latest `telemetry/runtime` branch contains later review checkpoints from session `6b82f797db3cfd8d`, but the full session JSONL is large enough that the connector did not expose a safe complete reconstruction of every 047–050 note during this pass. **Do not invent missing ratings or prose.** Continue to consume fresh telemetry first after the next host test.

Durable interpretation:
- interaction must produce an immediate readable consequence;
- release must leave persistent/delayed material state when the concept calls for it;
- controls must create genuinely different regimes/compositions rather than cosmetic amount changes;
- visible coarse solver pixels are rejected as final artwork;
- physical/material causality should be legible;
- performance matters: 046 showed that a visually stronger sketch can still fail badly on runtime cost;
- reset must work;
- technical novelty alone is not artistic success.

## Feedback-driven batch 051–055

This batch deliberately uses **zero fullscreen shaders** and targets direct material causality with bounded CPU work.

### 051 CAPILLARY BRIDGE

- 84 discrete droplets with bounded neighbour attraction;
- pointer writes persistent wet spots carrying gesture velocity;
- droplets bridge, cluster and flow toward wet memory;
- surface tension, wetting, evaporation, bridge reach, feed and inertia create isolated-bead / chain / clustering regimes.

### 052 FIBER MEMORY

- 42 x 13 point woven fiber field;
- pointer directly combs fibers and writes persistent directional offsets;
- neighboring strands transmit twist while memory controls recovery;
- low-amplitude clock terms only modulate autonomous current; they are not the state driver.

### 053 AVALANCHE BED

- continuous 96-column granular ridge rather than visible solver cells;
- pointer above the surface pours material; pointer in/below the bed excavates it;
- repose angle, cohesion and compaction change whether the bed flows, clumps or holds steep cuts;
- autonomous feed and drift keep the landscape evolving.

### 054 HINGE CHOIR

- 8 x 8 directly manipulable mechanical levers;
- pulling one hinge stores angular energy which propagates through neighbors;
- coupling, damping, drive, phase bias, lever length and impulse memory alter isolated/propagating/collective behavior;
- clock phase only shapes decaying stored impulse ringing.

### 055 SNAP LATTICE

- 16 x 9 large bistable folded facets, intentionally not presented as solver pixels;
- pressing a cell injects a local snap that can stay isolated or cascade;
- barrier, coupling, damping, bias and spontaneous activity move the field between stable domains and cascades;
- interaction leaves persistent state domains.

`knowledge/cross-domain/creative_draw_space.json` now records 051–055 as well as all previous 016–050 history.

## Implementation validation completed

Implementation/fix HEAD `25cb01539d0b4b767140dab79ee9215e739d1a44` passed **CI #348** completely before this durable-doc bundle:
- repository policy — success;
- temporal audit — success;
- adaptive creative draw self-test — success;
- Godot 4.7.1 import — success;
- main-scene smoke — success;
- tracked cleanliness — success.

The first run (#346) correctly caught undocumented direct-clock modulation in 052 and 054. Both now carry explicit `TEMPORAL_INTENT` comments and the exact implementation run is green.

Important: **051–055 are technically validated, not artistically accepted.** User ratings/WHY NOTES after a real host test remain authoritative.

## Existing host/product contracts to preserve

- PROGRAM persists across navigation; TAKE LIVE explicitly replaces it.
- physical PROGRAM touch/mouse works.
- linked PREVIEW/PROGRAM share one timeline/state.
- per-sketch params persist.
- real Gallery thumbnails; idle frozen, hover live.
- adaptive tag rail stays bounded; never restore the permanent all-tags wall.
- TRASH is exclusive and local only; never delete Git source.
- Gallery supports INDEX ↑/↓, TITLE, FAMILY, GRID/LIST and grid size.
- LIST stays dense (~68 px); preview is decorative background, not a large left thumbnail.
- PREV/NEXT switches PREVIEW by numeric source order and must not replace PROGRAM.
- ShaderMaterial mutable state is local to scene instances.
- full-canvas shader surface rule remains enforced.
- RATE remains centered/opaque/in-app.
- written RATE comments are first-class evidence and must be consumed automatically.
- no fake Spout/NDI.

## Next host validation

After the exact final documentation HEAD CI is green:

1. Confirm Gallery shows **55 source sketches**.
2. Test 051 → 055 at defaults for ~20–30 seconds before touching controls.
3. For every sketch, judge whether autonomous behavior remains interesting without generic clock wobble.
4. Interact, release, and check that the action is immediately legible and leaves a meaningful consequence.
5. Sweep every parameter through a large range; any control that appears to do nothing is a failure signal.
6. 051: write separated wet zones and verify droplet organization changes persist and later decay.
7. 052: comb opposite directions; test memory/twist extremes and verify the cloth really reorganizes.
8. 053: pour and excavate; compare low/high repose, cohesion and compaction.
9. 054: pull multiple hinges; compare coupling/damping/impulse-memory extremes and verify propagation changes regime.
10. 055: trigger isolated cells and clusters; compare low/high barrier/coupling and verify isolated snaps vs cascades.
11. Pay particular attention to performance because 046 scored 1 there.
12. Continue RATE numeric + WHY/NOTES normally; do not duplicate notes in chat.
13. Close normally so telemetry publishes; next AI must inspect fresh `telemetry/runtime` first before repairing or generating another batch.

## Mandatory completion contract

Material change -> code/push -> durable docs/state -> exact final remote HEAD -> exact-head CI -> report SHA/result. Never merge/change `main` without explicit user approval.
