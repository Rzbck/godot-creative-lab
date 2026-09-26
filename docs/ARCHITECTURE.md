# Architecture — DataC0re Creative Lab

## Status

Godot 4.7.1 creative-coding workstation. Repository state + matching runtime telemetry are authoritative when they disagree with chat history.

## Product model

DC//LAB separates:

1. **WORKSTATION / EDITOR** — Gallery, Settings, PREVIEW, parameters, review/curation and navigation.
2. **PROGRAM / LIVE OUT** — audience-facing persistent output.
3. **SKETCH** — isolated creative runtime with state, parameters and interaction.

Navigation is not transport: PROGRAM continues while the workstation browses or edits another PREVIEW. `TAKE LIVE` explicitly replaces PROGRAM.

## Main runtime

Entry scene: `res://app/main/main_runtime.tscn`.
Top layer: `res://app/main/main_runtime_window_memory.gd`.

Important chain:

```text
main_runtime_window_memory.gd
    -> main_runtime_gallery_compact_review.gd
        -> main_runtime_gallery_feedback_trash.gd
            -> main_runtime_gallery_adaptive_filters.gd
                -> main_runtime_gallery_organizer.gd
                    -> main_runtime_program_output.gd
                        -> main_runtime_gallery_persistence.gd
                            -> main_runtime_live_output.gd
                                -> lower output/window/telemetry layers
```

Always inspect the actual `extends` chain before host edits.

## Workstation window / shutdown revision 4

State persists in `user://creative_lab_window_state.cfg`.

Current rules:

- never toggle main `Window.visible` during startup; Godot 4.7.1 rejects this;
- apply saved screen/mode/position/size in `_enter_tree()`;
- logical Maximize is borderless **WINDOWED** usable-screen geometry with a 2 px bottom guard;
- F11 remains separate artwork presentation;
- shutdown telemetry writes `session_close_flush`, flushes and explicitly closes the telemetry `FileAccess`, then starts one hidden final publisher with reason `session_close_request`.

The explicit close order removes the prior race between an automatic close publisher and the dedicated final publisher. Host validation must still prove a fresh non-empty final publication.

## Gallery architecture

Sketches are data-driven from `sketches/*/definition.json`. Source catalogue: **001–040** before local curation.

### Thumbnail/runtime model

- each card owns a real sketch instance in a SubViewport;
- idle thumbnails freeze; only hovered preview animates;
- persisted parameters can be mirrored into the hidden thumbnail instance;
- active PREVIEW and PROGRAM can instantiate the same PackedScene at the same time.

This means mutable resources inside a sketch **must not be shared between scene instances**.

### ShaderMaterial isolation contract

A host stale-frame bug proved that shared ShaderMaterial resources are unsafe: a hidden Gallery thumbnail could overwrite uniforms or state textures used by PREVIEW/PROGRAM.

Permanent contract:

- every runtime sketch `ShaderMaterial` subresource sets `resource_local_to_scene = true`;
- repository CI enforces this for every `sketches/**/runtime/*.tscn`;
- PREVIEW, PROGRAM and Gallery thumbnail may share immutable Shader resources, but never the mutable ShaderMaterial uniform state;
- stateful CPU→GPU textures should be committed atomically. 037/040 use two ImageTexture buffers: update inactive -> switch shader sampler.

### Browser presentation revision 2

Filtering metadata and browsing presentation are separate concerns.

- search still indexes title/index/engine/description/all tags;
- adaptive quick-tag rail stays bounded, with rare tags in the drawer;
- default browsing is flat `INDEX ↑`, giving deterministic 001→040 order;
- alternative sorts: INDEX ↓, TITLE A–Z, FAMILY;
- FAMILY restores semantic first-tag sections;
- GRID and LIST modes are available;
- GRID card/preview size is adjustable;
- browser state persists in `user://creative_lab_gallery_view.cfg`;
- sort/reflow reparents existing cards/SubViewports rather than recreating sketch instances.

Local Trash remains reversible and never deletes Git source.

## Review / preference feedback revision 4

Compact row remains:

`REVIEW <avg> RATE TRASH`

RATE is an opaque centered in-app modal with six 1–5 axes:

- visual
- interaction
- originality
- aliveness
- controls
- performance

It also contains free text **WHY / NOTES**.

Reviews persist in `user://creative_lab_reviews.cfg`. Written notes are stored beside numeric ratings and included in `creative_preference_snapshot`. `SAVE REVIEW` persists explicitly; modal close saves pending note text.

Ratings/notes schedule a telemetry checkpoint roughly 0.8 s after the last change, so preference evidence does not rely on successful application shutdown.

## Current stateful render fixes

### 037 DENDRITE BLOOM

- hidden 96×54 phase/nutrient/age state remains compact for live sync;
- two ImageTextures alternate for complete GPU state commits;
- final shader reconstructs the hidden field using weighted multi-tap sampling before normals/material shading;
- this reduces visible grid stair-stepping without multiplying synchronized solver state.

### 038 ELECTRIC LACE

- vector field-line system remains the artwork;
- visible charges are directly grabbable only inside a real hit radius;
- empty-space click does nothing;
- drag directly moves the charge, release preserves small inertia.

### 040 SCHLIEREN VEIL

- hidden 80×45 density/heat/velocity field remains compact;
- double-buffered ImageTexture commit prevents sampling a texture while it is being updated;
- multi-tap reconstruction occurs before density-gradient schlieren optics.

## Visual Finish Gate

Technical diversity is not a quality guarantee. Read `knowledge/cross-domain/VISUAL_FINISH_GATE.md`.

Required creative pipeline:

`adaptive draw -> prototype -> observe -> mutate -> art-direct -> visual-finish gate -> keep/reject`

Since sketch 036, repository CI requires `definition.json.visual_finish` with:

- `composition`
- `material_model`
- `final_render`
- at least three `detail_scales`
- `interaction_stateful=true`

This is a process contract, not an automated beauty score.

## Full-canvas render contract

Logical artwork coordinates normally remain 1280×720. Physical PREVIEW/PROGRAM surfaces adapt to actual viewport size.

A node named `ShaderSurface` must use:

`res://sketches/_shared/full_canvas_surface.gd`

CI rejects fixed 1280×720 ShaderSurface offsets.

Low-resolution simulation grids are hidden state only. Final visible output must reconstruct appropriate high-resolution geometry/material/detail; do not expose enlarged coarse solver pixels as finished art.

## Temporal-quality contract

Preferred:

`time -> force/state/memory/event -> coupled system -> render`

Rejected by default:

`time -> sin/cos -> visible position/scale/alpha/warp`

Also reject visible phase wraps, global resets, respawn walls and synchronized restarts. Physical periodic forcing is allowed only when visible representation stays continuous.

`scripts/ci/audit_temporal_motion.py` audits the corpus. For 026+, direct clock trig requires `TEMPORAL_INTENT:`.

## Adaptive creative draw

Files:

- `knowledge/cross-domain/creative_draw_space.json`
- `knowledge/cross-domain/ADAPTIVE_CREATIVE_DRAW.md`
- `scripts/creative/draw_recipe.py`

The engine selects distant carriers/representations/operators/temporal models/interactions/constraints/render paths and penalizes recent repetition. Explicit REVIEW data is bounded probability evidence only. It is a collision generator, not an art director.

## Preference evidence

Recovered evidence strongly rejects 026–035 overall. Latest non-empty intermediate telemetry also recovered:

- 031 avg 2.0
- 032 avg 1.5
- 033 avg 1.0
- 034 avg ~2.17
- 035 avg 1.0

New 036–040 scores were not available remotely because the final close publication was empty. Never infer them from qualitative comments. 038 did receive explicit positive qualitative feedback; preserve that signal without turning it into a clone rule.

## Performance representation

- dense fields: simulate at appropriate cadence and render via suitable texture/material representation;
- expensive neighbour/contact work belongs in simulation, not duplicated in `_draw()`;
- hidden state resolution should balance dynamics/live-sync cost while the final representation restores visual resolution;
- vector geometry is preferred when it preserves useful line/facet detail;
- MultiMesh/GPU paths remain available for large populations;
- high FPS never compensates for weak art direction.

## Telemetry

Local runtime telemetry: `res://.telemetry_runtime/`.
Sanitized remote telemetry:

```text
branch: telemetry/runtime
latest.jsonl
sessions/
```

Publishing must never block the UI. Review checkpoints are asynchronous. After any host test, inspect matching telemetry before asking for logs or drawing conclusions.

## PREVIEW / PROGRAM synchronization

When linked, editor PREVIEW is simulation authority and PROGRAM follows synchronized state. On navigation/detach, final state syncs and PROGRAM continues autonomously. Never create unrelated linked timelines.

PROGRAM touch/mouse maps through the same logical design space as PREVIEW.

## Historical non-regressions

- 005 source path stays `005_pressure_lattice`, visible artwork stays **REGISTER TYPE**.
- generalized glyph-contour treatment is not a house style.
- do not restore a permanent full tag wall.
- ShaderMaterial mutable state remains local to each scene instance.
- RATE remains opaque/centered/in-app.
- no main-window visibility toggles at startup.
- Spout/NDI remain future adapters and must never be represented as installed/working when they are not.
