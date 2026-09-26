# NEXT AI PROMPT — DC//LAB

Resume from the repository, not from assumptions.

## Repository position

- repo: `Rzbck/godot-creative-lab`
- active branch: `feat/creative-sketches-002-004-20260924`
- draft PR: #7
- base: `feat/gallery-project-workflow-20260923`
- never merge/change `main` without explicit user approval
- expected source catalogue: **001–060**
- top runtime: `res://app/main/main_runtime_favorites.gd`

Read `docs/handoff/CURRENT_WORK.md` and `docs/handoff/project_state.json` first.

## Mandatory first action after the user's host test

Inspect fresh `telemetry/runtime` before repairing or generating anything. Consume all three preference channels automatically:

1. numeric RATE axes;
2. written WHY / NOTES;
3. ★ FAVORITE / POTENTIAL state.

The user should not have to repeat any existing review or favorite in chat.

The review session consumed to create this pass was `31a1daf3d902aca6`, telemetry HEAD `c6aeb0ee36704bea5b868f3e2245893977cbf4bf`.

## Preference signal that drove this pass

- 050 FERRO TRACE: interaction was a positive signal; user wanted more points/sources and stronger visual customisation.
- 051 CAPILLARY BRIDGE: too sparse, visually weak, limited interaction and controls.
- 052 FIBER MEMORY: too basic, insufficiently granular, weak interaction/parameters.
- 053 AVALANCHE BED: rejected as incomprehensible/visually poor and not reading as generative art.
- 054 HINGE CHOIR: originality 4 and explicitly considered to have potential, but interaction was too click-like; user wanted felt pendulum physics, collisions, chain reactions, more depth and better performance.
- 055 SNAP LATTICE: idea exists but too passive; user wants more mobile/generative/alive systems.
- 046 INK SHEAR remains useful as a visual/originality signal, but its interaction/performance were weak and the user specifically disliked circles appearing on click.

Durable rule: reuse qualities, not surfaces. A favorite is evidence of interest/potential, not a clone instruction.

## Favorites feature

`app/main/main_runtime_favorites.gd` layers on top of the validated host chain.

- local favorite state persists in the curation config;
- Project inspector has `☆ ADD FAVORITE / POTENTIAL` / `★ FAVORITE / POTENTIAL`;
- Gallery badge shows `★` for favorites;
- `sketch_favorite_changed` publishes individual changes;
- `creative_favorite_snapshot` publishes the complete favorite set plus title/tags/creative signature;
- preference checkpoints also emit favorite snapshots;
- **054 HINGE CHOIR is seeded favorite once** per explicit user request. The user can remove it afterward.

## 054 HINGE CHOIR repaired

The old click-impulse array was replaced by a denser tactile pendular system:

- 48 weighted pendula;
- continuous grab near a rod, drag through an arc, release with retained momentum;
- gravity and neighbour torque coupling;
- actual weighted-bob collisions + adjustable rebound;
- state-driven center-crossing escapement for sustained collective motion without direct clock wobble;
- controls: coupling, bearing drag, escapement drive, gravity, lever length, collision rebound;
- polygonal weighted bobs rather than transient click circles;
- lower oscillator count than the prior version to target the previous performance=1 review.

## Current new batch awaiting host rating

### 056 FOAM PRESS
70 irregular polygonal foam cells. Continuous grab/stir interaction, contact pressure, adhesion and jamming; bounded pressure pulses. Packing/adhesion/viscosity/pressure/pulse/hand response should visibly separate loose mobile foam from sticky jammed rafts.

### 057 RIBBON WAKE
16 broad elastic ink ribbons with persistent drag-written rest-shape memory. Tension/drag/spatial current/cross-link/width/memory should separate taut graphic rails, soft coupled wakes and long-lived folds. No click-circle overlay.

### 058 VASCULAR PULSE
84-node elastic vessel graph carrying pressure. Continuous drag pumps a neighbourhood; pressure propagates/leaks, junctions recoil, repeated flow persistently remodels vessel thickness. Conduction/leak/remodel/pump/recoil/contrast should expose different transport regimes.

### 059 SWARM LENS
190 oriented shard agents with up to six persistent draggable alternating-polarity diamond sources. Press empty space to add a source or drag an existing one. Field strength/orbit-radial balance/reach/drag/coherence/wander should create capture, orbit, repulsion and streaming regimes.

### 060 CRYSTAL ZIPPER
18 x 10 continuous triangular faceted material. Drag writes directional stress; cracks propagate after release and heal later. Toughness/propagation/healing/diffusion/shear/relief should separate ductile strain from brittle zipper cascades. No decorative square background.

All 056–060 use `canvas_geometry`. `knowledge/cross-domain/creative_draw_space.json` includes history through 060 and the new 054 contact/collision signature.

## Validation state

Implementation/fix HEAD before durable docs: `3fd00c7047d6977dfba94cfac894c3b7ccceb4c5`.
CI #354 passed completely on that exact implementation HEAD:
- repository policy;
- temporal audit;
- adaptive creative draw self-test;
- Godot 4.7.1 import;
- main-scene smoke;
- tracked cleanliness.

CI #353 failed only because the new runtime script's generated `.gd.uid` was initially untracked; no parser/runtime smoke step failed. The UID was committed before #354.

The final durable-doc HEAD is newer than the implementation HEAD and must also have exact-head CI green before handoff is complete.

## What to judge in the next host session

1. Gallery count must be 60.
2. 054 must show ★ initially.
3. Toggle favorite on another sketch and verify persistence.
4. Re-test 054 for continuous grab/release, pendulum inertia, collisions, chain reactions, regime changes and performance.
5. Watch 056–060 at defaults for ~20–30 seconds.
6. Sweep every parameter through a large range; if a control appears to do nothing, fail it.
7. Interaction must be immediately readable and leave meaningful state/delayed consequence where intended.
8. Judge whether autonomous motion feels alive without generic clock wobble.
9. Pay close attention to performance.
10. RATE + WHY/NOTES + ★ normally. Close normally so telemetry publishes.
11. Next AI must read fresh telemetry before any next repair/generation pass.

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
- RATE remains opaque/centered/in-app.
- no fake Spout/NDI.
- no main-window visibility toggle at startup.

## Creative rules

Controls must create visible regime/composition changes. Interaction should be continuous where that improves agency, immediate and stateful. Avoid gratuitous click markers. Hidden coarse simulation is acceptable; visible solver pixels are not finished artwork. Technical diversity is not proof of visual quality. Generic direct-clock wobble is rejected as default aliveness. Performance remains a first-class acceptance axis.

## Completion contract

Any material change must follow: code/push -> durable docs/state -> exact remote HEAD -> exact-head CI -> report SHA/result. For host validation, automatically provide the canonical PowerShell from `docs/handoff/OPERATIONS.md` that syncs the branch, waits for CI on the exact SHA and only then launches Godot. Keep PR #7 draft unless the user explicitly asks otherwise. Never merge/change `main` without explicit approval.
