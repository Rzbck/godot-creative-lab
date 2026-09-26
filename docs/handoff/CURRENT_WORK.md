# Current work — DC//LAB

Last refreshed: 2026-09-26.

## Active branch / PR

- branch: `feat/creative-sketches-002-004-20260924`
- draft PR: #7
- base: `feat/gallery-project-workflow-20260923`
- never merge/change `main` without explicit user approval
- source catalogue: **001–060**
- top runtime: `app/main/main_runtime_favorites.gd`

## Mandatory feedback loop

The workflow is telemetry-first. After every host test, inspect fresh `telemetry/runtime` before repairing or generating. Numeric RATE values, written WHY/NOTES and favorites are all first-class preference evidence; the user should not have to restate them in chat.

Latest consumed review session before this batch: `31a1daf3d902aca6` on telemetry HEAD `c6aeb0ee36704bea5b868f3e2245893977cbf4bf`.

### Reviews that drove this pass

- 050 FERRO TRACE: visual 3 / interaction 4 / originality 3 / aliveness 2 / controls 3 / performance 3. Positive interaction signal; user wanted more points/sources and a stronger/custom visual finish.
- 051 CAPILLARY BRIDGE: 2 / 2 / 3 / 2 / 1 / 3. Too sparse/weak visually, limited interaction, controls too weak.
- 052 FIBER MEMORY: 2 / 1 / 1 / 1 / 1 / 1. Too basic, insufficiently granular, insufficient parameters.
- 053 AVALANCHE BED: all 1. Incomprehensible/visually poor, read as dirt getting bigger rather than generative art.
- 054 HINGE CHOIR: 2 / 2 / 4 / 1 / 2 / 1. **Strong potential signal**: idea liked, but interaction was too click-like, pendular physics not felt, collisions/chain reactions missing and performance poor.
- 055 SNAP LATTICE: 2 / 2 / 3 / 2 / 1 / 1. Idea exists but not taken far enough; too passive, not mobile/generative/alive enough.

Earlier durable lessons remain active: 046 had strong visual/originality but weak interaction and performance and the user specifically disliked gratuitous circles appearing on click; 042 showed that parameters that appear to do nothing are a failure; visible coarse solver pixels are rejected; 020 ECHO TISSUE remains the strongest historical reference signal without being a clone target.

Durable interpretation:
- favor continuous gestures over one-click effects;
- interaction must be immediately readable and should leave meaningful state where intended;
- controls must create visibly different regimes, not cosmetic amount changes;
- autonomous motion must come from state/system dynamics rather than generic clock wobble;
- more density/source multiplicity can be useful when it improves composition and agency;
- performance is a first-class acceptance axis;
- technical novelty alone is not artistic success.

## Favorites / potential signal

A durable favorites layer now sits at `app/main/main_runtime_favorites.gd` above the validated host runtime chain.

- favorites persist in the existing local curation config;
- Project review controls expose `☆ ADD FAVORITE / POTENTIAL` / `★ FAVORITE / POTENTIAL`;
- Gallery review badges show `★` alongside rating when applicable;
- telemetry event `sketch_favorite_changed` publishes changes;
- telemetry event `creative_favorite_snapshot` publishes the complete favorite set with title/tags/creative signature;
- preference snapshots now also emit a favorite snapshot;
- **054 HINGE CHOIR is seeded as favorite once**, per explicit host request; after that the user remains free to remove it.

Future AI must treat favorites as positive/potential evidence, not as an instruction to copy the sketch surface.

## 054 HINGE CHOIR repair

HINGE CHOIR was rebuilt around the review rather than cosmetically patched:

- 48 long weighted pendula instead of 64 click-triggered levers;
- continuous grab anywhere near a rod, drag through an arc, release with retained angular momentum;
- gravity plus neighbour torque coupling;
- literal bob-to-bob collision impulses with adjustable rebound;
- state-driven center-crossing escapement can sustain motion without direct-clock wobble;
- parameters now expose coupling, bearing drag, escapement drive, gravity, lever length and collision rebound;
- visual finish uses rods + weighted polygonal bobs, not transient click circles;
- reduced count targets the previous performance=1 failure while adding more legible physics.

## Feedback-driven batch 056–060

All five use `canvas_geometry`. They deliberately span different material/system families while sharing continuous interaction, post-release consequence and stronger parameter regimes.

### 056 FOAM PRESS

- 70 irregular wet-foam polygon cells;
- direct grab plus continuous neighbourhood stirring;
- contact pressure, repulsion and adhesion create loose/mobile vs sticky/jammed rafts;
- bounded autonomous pressure pulses keep material alive without clock-phase animation;
- packing, adhesion, viscosity, pressure, pulse and hand response materially alter behaviour.

### 057 RIBBON WAKE

- 16 broad elastic ink ribbons with 18 control points each, rendered as filled bands rather than exposed solver dots;
- drag continuously combs/folds the field and writes persistent rest-shape memory;
- tension, drag, spatial current, cross-links, width and memory move between taut rails, coupled soft waves and long-lived folds;
- explicitly responds to the positive visual signal in 046 while removing the disliked click-circle/breaking behavior.

### 058 VASCULAR PULSE

- 84-node proximity vessel network carrying actual pressure differences;
- continuous drag pumps a neighbourhood and moves elastic junctions;
- pressure propagates, leaks and recoils; repeated flow persistently remodels vessel conductance/thickness;
- bounded autonomous pump events add life;
- controls are designed to expose fast/damped/remodeling/self-pulsing regimes.

### 059 SWARM LENS

- 190 oriented shard agents;
- up to six persistent draggable diamond field sources with alternating polarity;
- press empty space to add a source, or drag an existing source continuously; sources remain after release;
- field strength, orbit/radial balance, reach, drag, coherence and spatial wander produce capture/orbit/repulsion/streaming regimes;
- carries forward 050's request for more points/sources without cloning FERRO TRACE's surface.

### 060 CRYSTAL ZIPPER

- continuous 18 x 10 offset triangular faceted material;
- drag writes directional stress rather than spawning a visual click marker;
- stress diffuses, fractures can propagate after release and later heal;
- toughness/propagation/healing/diffusion/shear/relief separate ductile strain from brittle zipper cascades;
- no decorative square background layer.

`knowledge/cross-domain/creative_draw_space.json` now records history through 060 and updates 054's signature to its collision/contact implementation.

## Validation completed before durable docs

Implementation/fix HEAD `3fd00c7047d6977dfba94cfac894c3b7ccceb4c5` passed **CI #354** completely:
- repository policy — success;
- temporal audit — success;
- adaptive creative draw self-test — success;
- Godot 4.7.1 import — success;
- main-scene smoke — success;
- tracked cleanliness — success.

CI #353 on the first implementation commit failed only because Godot generated the untracked UID for the new top runtime script. The UID was then committed; #354 is green. There were no parser/runtime smoke failures in #353.

Important: **054 repaired and 056–060 are technically validated, not artistically accepted.** Host RATE/WHY/NOTES/FAVORITES remain authoritative.

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
- full-canvas ShaderSurface rule remains enforced.
- RATE remains centered/opaque/in-app.
- written reviews and favorites are first-class preference evidence.
- no fake Spout/NDI.
- no main-window visibility toggling at startup.

## Next host validation

After the exact final documentation HEAD CI is green:

1. Confirm Gallery shows **60 source sketches**.
2. Confirm 054 HINGE CHOIR shows `★` as the seeded favorite/potential sketch.
3. Test favorite toggle on another sketch and verify it survives leaving/reopening the sketch.
4. Re-test 054: continuous grab/drag/release; look specifically for felt pendulum inertia, bob collisions, chain reactions, regime changes and performance.
5. Test 056 → 060 at defaults for ~20–30 seconds before controls.
6. Sweep every parameter through a large range; a parameter that appears to do nothing is a failure.
7. Interact continuously, release, and judge whether a meaningful consequence persists.
8. 056: compare low/high packing and adhesion for loose motion vs jamming.
9. 057: write opposite folds; compare low/high tension/cross-link/memory.
10. 058: pump different regions; compare conduction/leak/remodel/pump extremes.
11. 059: create several sources, drag them, compare radial/orbit polarity and reach/coherence extremes.
12. 060: drag stress paths; compare high toughness/low propagation vs brittle low-toughness/high-propagation and healing.
13. Pay close attention to performance.
14. RATE + WHY/NOTES normally and use ★ for anything liked or worth developing, even if unfinished.
15. Close normally so telemetry publishes. Next AI must inspect fresh `telemetry/runtime` first and consume both reviews and favorites automatically.

## Mandatory completion contract

Material change -> code/push -> durable docs/state -> exact final remote HEAD -> exact-head CI -> report SHA/result. Never merge/change `main` without explicit user approval.
