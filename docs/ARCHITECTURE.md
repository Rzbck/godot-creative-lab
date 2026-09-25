# Architecture — DataC0re Creative Lab

## Status

Implemented Godot 4.7.1 creative-coding workstation. Repository state + matching runtime telemetry are authoritative when they disagree with chat history.

## Product model

DC//LAB separates:

1. **WORKSTATION / EDITOR** — Gallery, Settings, PREVIEW, parameters, review/curation and navigation.
2. **PROGRAM / LIVE OUT** — audience-facing output on a selected physical display.
3. **SKETCH** — isolated creative runtime with parameters, interaction and optional live-state synchronization.

Navigation is not PROGRAM transport. PROGRAM keeps running while the workstation browses or opens another PREVIEW. `TAKE LIVE` replaces PROGRAM explicitly.

## Main runtime

Entry scene:

`res://app/main/main_runtime.tscn`

Current top runtime layer:

`res://app/main/main_runtime_window_memory.gd`

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

Always inspect the actual `extends` chain before changing host architecture.

## Workstation native-window state

Native workstation state persists in:

`user://creative_lab_window_state.cfg`

Persisted state includes mode, physical screen, position/size and restore rect.

Startup restoration occurs before the first visible workstation frame:

1. top runtime hides the root Window in `_enter_tree()`;
2. saved native state is applied;
3. normal UI `_ready()` chain/layout runs;
4. after settle, the root Window is revealed;
5. `workstation_window_state_restored` telemetry records the result.

First run defaults to fullscreen. F11 artwork presentation is a separate transport/presentation state and must not overwrite the saved workstation state.

This was introduced after host telemetry proved the previous implementation visibly appeared at 1280×720 then switched to fullscreen roughly 730 ms later.

## Gallery architecture

Sketches are discovered from `sketches/*/definition.json`. Current source catalogue: **001–030**.

Current Gallery behavior:

- real SubViewport thumbnail render per sketch;
- idle thumbnails freeze; only hovered card animates;
- persisted sketch parameters restore into thumbnails;
- first tag defines automatic primary group;
- search indexes id/index/title/engine/description/all tags;
- permanent filter rail bounded to `ALL` + at most six generated useful tags;
- universal tags omitted; rare/rest tags in collapsed `MORE`;
- active rare tag promoted while selected;
- empty groups disappear; card grids respond to width.

Do not restore a permanent all-tags wall.

## Review / preference feedback loop

Parameter sidebar contains one compact row:

`REVIEW <avg> RATE TRASH`

RATE opens a centered **in-app opaque modal**, not a native popup, with six explicit 1–5 criteria:

- visual;
- interaction;
- originality;
- aliveness;
- controls;
- performance.

Reviews persist in `user://creative_lab_reviews.cfg`. Rated cards display `R x.x`.

Telemetry:

- `sketch_review_changed` — individual edits;
- `creative_preference_snapshot` — complete current reviewed set + axis averages.

Future creative decisions should use explicit ratings as bounded probability evidence. They must not become a clone/ranking mechanism. Adaptive exploration keeps 24% preference-free draws.

## Local Trash / curation

`TRASH` hides a sketch locally from the Gallery. State lives in `user://creative_lab_curation.cfg`.

- RESTORE supported;
- 7/14/30 day retention;
- expiration/PURGE means local retirement;
- workstation never deletes version-controlled `res://sketches/...` files.

Actual source deletion remains explicit Git work.

## Full-canvas render contract

Logical design coordinates are normally `1280×720`, but physical render surfaces follow real PREVIEW/PROGRAM size.

A node named `ShaderSurface` must use:

`res://sketches/_shared/full_canvas_surface.gd`

CI rejects fixed 1280×720 ShaderSurface offsets. Host publishes `sketch_surface_contract` telemetry.

Drawing-based sketches use logical-to-surface transforms from `design_sketch_base.gd`; any aspect-fit margin must be intentional artwork, never exposed host gray.

## Temporal-quality contract

Preferred:

`time -> force/state/memory/event -> coupled system -> render`

Rejected by default:

`time -> sin/cos -> visible position/scale/alpha/warp`

Periodic forcing is valid when it is genuinely the mechanism. Rules: `knowledge/cross-domain/TEMPORAL_MOTION_QUALITY.md`.

`scripts/ci/audit_temporal_motion.py` audits the corpus. Existing <=025 findings are warnings; for 026+ direct clock trigonometry requires nearby `TEMPORAL_INTENT:` justification.

## Adaptive creative draw

Files:

- `knowledge/cross-domain/creative_draw_space.json`
- `knowledge/cross-domain/ADAPTIVE_CREATIVE_DRAW.md`
- `scripts/creative/draw_recipe.py`

A recipe draws carrier, two distant representation families, two distant operator families, temporal model, interaction consequence, design constraint and render path.

Historical/recent reuse is penalized and recent signature distance enforced. Explicit REVIEW data applies only bounded preference bias; 24% of draws deliberately ignore preference bias.

For 026+, `definition.json` includes non-empty `creative_signature`. Implemented signatures 026–030 are recorded in draw history.

## Current adaptive batch 026–030

- 026 VOID TENSION — constraint network + Voronoi territory + fracture/repair.
- 027 GLASS TIDE — asynchronous wave fronts + SDF glass topology.
- 028 LUMEN MAZE — graph light transport + jam/release + remembered obstacles.
- 029 FIBER FELT — constrained fibers + local compaction mask + phase transition.
- 030 REACTOR SKIN — reaction-diffusion + membrane stress + fracture/repair.

They deliberately emphasize neighbour interaction, state memory and consequences that continue after touch because current ratings show aliveness/controls are the weakest catalogue axes.

## Parameters / persistence

Sketch parameter values persist in:

`user://creative_lab_sketch_settings.cfg`

Substantial labs normally expose 6–9 meaningful independent controls when mechanism supports them.

## Performance representation

Dense state fields should render through ImageTexture/fullscreen shader where suitable instead of thousands of Canvas primitives. Expensive neighbourhood/contact work belongs in simulation cadence and should not be recomputed in `_draw()`.

## PREVIEW / PROGRAM synchronization

When PREVIEW and PROGRAM are linked, editor sketch is simulation authority and PROGRAM follows synchronized state. On navigation/detach, final state synchronizes and PROGRAM continues autonomously. Do not create unrelated linked timelines.

## Physical output / input

PROGRAM uses the established output path on the selected display. A historical cross-window texture-sampling path produced gray output and must not be casually restored.

Touch/mouse on PROGRAM is forwarded into the same logical design space used by PREVIEW.

## Telemetry

Local runtime telemetry: `res://.telemetry_runtime/`

Sanitized online telemetry:

```text
branch: telemetry/runtime
latest.jsonl
sessions/
```

Publication is asynchronous and must never block UI. After host test, require matching tested HEAD/session before conclusions.

## Knowledge / research

For substantial work consult relevant creative-coding/design material plus:

- `TECHNIQUE_PALETTE.md`
- `RANDOM_COLLISION_ENGINE.md`
- `COLLISION_SOURCE_CATALOG.md`
- `PHYSICAL_CHEMICAL_SYSTEMS_ATLAS.md`
- `ORGANIC_COUPLING_AND_CONTROLS.md`
- `REALTIME_PERFORMANCE_BUDGET.md`
- `TEMPORAL_MOTION_QUALITY.md`
- `ADAPTIVE_CREATIVE_DRAW.md`

References provide mechanisms/principles, not surfaces to copy.

## Optional future outputs

Spout and NDI remain future adapters and must not be represented as working.
