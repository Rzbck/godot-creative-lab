# Architecture — DataC0re Creative Lab

## Status

Godot 4.7.1 creative-coding workstation. Repository state + matching runtime telemetry are authoritative when they disagree with chat history.

## Product model

DC//LAB separates:

1. **WORKSTATION / EDITOR** — Gallery, Settings, PREVIEW, parameters, review/curation and navigation.
2. **PROGRAM / LIVE OUT** — audience-facing persistent output.
3. **SKETCH** — isolated creative runtime with state, parameters and interaction.

Navigation is not transport: PROGRAM continues while the workstation browses or edits another PREVIEW. `TAKE LIVE` explicitly replaces PROGRAM.

## Main runtime chain

Entry scene: `res://app/main/main_runtime.tscn`.
Top layer: `res://app/main/main_runtime_gallery_host_fixes.gd`.

```text
main_runtime_gallery_host_fixes.gd
    -> main_runtime_window_memory.gd
        -> main_runtime_gallery_compact_review.gd
            -> main_runtime_gallery_feedback_trash.gd
                -> main_runtime_gallery_adaptive_filters.gd
                    -> main_runtime_gallery_organizer.gd
                        -> main_runtime_program_output.gd
                            -> main_runtime_gallery_persistence.gd
                                -> main_runtime_live_output.gd
                                    -> lower output/window/telemetry layers
```

The host-fix layer is intentionally thin: it overrides only Gallery LIST/TRASH presentation proven wrong in host feedback and leaves the validated lower runtime behavior intact.

## Workstation window / shutdown

State persists in `user://creative_lab_window_state.cfg`.

- never toggle main `Window.visible` during startup;
- apply saved screen/mode/position/size in `_enter_tree()`;
- logical Maximize is borderless WINDOWED usable-screen geometry with a 2 px bottom guard;
- F11 remains separate artwork presentation;
- close telemetry uses one ordered path: write/flush -> explicit FileAccess close -> release -> hidden final publisher -> quit.

Review checkpoints provide a second asynchronous durability path for feedback.

## Gallery architecture

Sketches are data-driven from `sketches/*/definition.json`. Source catalogue: **001–045** before local curation.

Each card owns a real sketch instance in a SubViewport. Idle thumbnails freeze; only hovered previews animate. Persisted parameters can be mirrored into hidden thumbnail instances. Active PREVIEW and PROGRAM can instantiate the same PackedScene simultaneously.

### ShaderMaterial isolation contract

Mutable resources inside a sketch must not be shared between instances.

- every runtime sketch `ShaderMaterial` subresource sets `resource_local_to_scene = true`;
- repository CI enforces this;
- PREVIEW, PROGRAM and Gallery thumbnail may share immutable Shader code but never mutable ShaderMaterial uniforms/textures;
- stateful CPU→GPU textures should be atomically committed. 037, 040, 044 and 045 use two ImageTexture buffers.

### Browser presentation

Filtering metadata and browsing presentation are separate concerns.

- search indexes title/index/engine/description/tags;
- adaptive quick tags stay bounded;
- default browsing is flat `INDEX ↑`;
- INDEX ↓, TITLE A–Z and FAMILY sorts remain available;
- FAMILY restores semantic first-tag groups;
- GRID and LIST reuse the same cards/SubViewports rather than recreating simulations;
- GRID card/preview size is adjustable;
- browser state persists in `user://creative_lab_gallery_view.cfg`.

### LIST host fix

LIST must remain visual. The top runtime creates a second presentation for every card using the same SubViewport texture:

- ~260 px preview on the left;
- index/title/engine/tags/description on the right;
- compact ~132 px row;
- switching modes only changes presentation visibility/layout.

### TRASH host fix

TRASH is an exclusive local curation view, not a filter layered over normal cards.

- opening Trash hides normal Gallery scroll/search/browser controls;
- only the curation drawer rows remain visible;
- normal tag/MORE actions exit Trash mode;
- restore/purge never delete versioned source.

## Review / preference feedback

RATE is opaque, centered and in-app. Six 1–5 axes remain: visual, interaction, originality, aliveness, controls, performance. `WHY / NOTES` adds free text. Reviews persist in `user://creative_lab_reviews.cfg` and are included in `creative_preference_snapshot`.

Ratings/notes schedule a telemetry checkpoint ~0.8 s after changes so useful preference evidence does not depend on application shutdown.

## Current creative systems 041–045

### 041 TENSION ORGAN — constraint mesh

17×10 physical membrane, structural + diagonal springs, damped state, event-driven autonomous force and direct node manipulation. Rendering uses filled stress facets plus fine structural threads.

### 042 MYCELIUM RELAY — agent ecology

Branching tips, energy, chemotaxis, autonomous nutrient basins and persistent grown trails. User gestures paint nutrients into the future state rather than directly positioning the organism.

### 043 SLIT MEMORY — temporal slicing

Ten coupled channels produce a real history buffer. Final geometry samples that history horizontally. Persistent interaction staples modify local history lookup, creating temporal compression/repetition/folds while source dynamics continue.

### 044 EXCITABLE GLASS — excitable medium

Hidden excitation/refractory grid with autonomous pacemakers. Interaction seeds quiet areas or quenches active material. A full-resolution multi-tap glass shader reconstructs relief/front caustics/micro grain from hidden state.

### 045 RIFT VOLUME — SDF raymarch

Three event-driven toroidal masses plus a folded membrane are raymarched full resolution. A hidden persistent scar field erodes the SDF. Interaction adds scars and force. Shader uses finite-difference normals, AO and mineral/specular/rim shading; no shader TIME.

## Visual Finish Gate

Technical diversity is not a quality guarantee. Read `knowledge/cross-domain/VISUAL_FINISH_GATE.md`.

Required pipeline:

`adaptive draw -> prototype -> observe -> mutate -> art-direct -> visual-finish gate -> keep/reject`

Since 036, CI requires `visual_finish` metadata with composition, material model, final render, >=3 detail scales and stateful interaction. This is a process contract, not a beauty score.

Low-resolution simulation grids are hidden state only. Final visible output must reconstruct suitable high-resolution material/geometry/detail.

## Temporal-quality contract

Preferred:

`time -> force/state/memory/event -> coupled system -> render`

Reject direct clock wobble, visible phase wraps, global resets, respawn walls and synchronized restarts. Physical periodic forcing is allowed only when visible representation stays continuous.

## Adaptive creative draw

Files:

- `knowledge/cross-domain/creative_draw_space.json`
- `knowledge/cross-domain/ADAPTIVE_CREATIVE_DRAW.md`
- `scripts/creative/draw_recipe.py`

The engine selects technically distant mechanisms and penalizes recent repetition. REVIEW is bounded probability evidence only. The draw engine generates collisions; it is not an art director.

## Validation / host status

Code/UID batch `c43be4300105e8677db22dd7c291a59d80fbc9f5` passed CI #307 completely before final docs.

The user has not yet host-tested this latest build. Therefore LIST/TRASH behavior and 041–045 aesthetics/interactions remain host-validation-required despite green CI.

## PREVIEW / PROGRAM synchronization

When linked, editor PREVIEW is simulation authority and PROGRAM follows synchronized state. On navigation/detach, final state syncs and PROGRAM continues autonomously. Never create unrelated linked timelines. PROGRAM touch/mouse maps through the same logical design space as PREVIEW.

## Historical non-regressions

- 005 source path stays `005_pressure_lattice`, visible artwork stays **REGISTER TYPE**.
- generalized glyph-contour treatment is not a house style.
- do not restore a permanent full tag wall.
- ShaderMaterial mutable state remains local per scene instance.
- RATE remains opaque/centered/in-app.
- no main-window visibility toggles at startup.
- Spout/NDI remain future adapters and must never be represented as working when they are not.
