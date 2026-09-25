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

Important chain begins:

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

## Workstation window memory revision 3

State persists in `user://creative_lab_window_state.cfg`.

The host proved two separate Windows/Godot problems:

1. native maximize on a borderless monitor-sized client could collapse into fullscreen semantics;
2. Godot 4.7.1 rejects changing visibility of the main Window from `_enter_tree()`.

Current strategy:

- saved screen/mode/position/size is applied in `_enter_tree()` without changing `Window.visible`;
- logical Maximize is a borderless **WINDOWED** usable-screen rectangle with a 2 px bottom guard;
- `_workstation_expanded` prevents that geometry from overwriting the normal restore rectangle;
- F11 is separate artwork presentation state;
- first-frame cleanliness and restore behavior require host validation, but CI has no runtime error in headless mode.

## Gallery architecture

Sketches are data-driven from `sketches/*/definition.json`. Current source catalogue: **001–040**.

Gallery behavior:

- real SubViewport thumbnails;
- idle thumbnails freeze; hovered card animates;
- persisted sketch parameters restore;
- search indexes metadata/all tags;
- adaptive tag rail exposes only a bounded useful subset plus `MORE`;
- local Trash is reversible and never deletes Git source;
- review badges reflect persisted explicit ratings.

## Review / preference feedback

Compact row:

`REVIEW <avg> RATE TRASH`

RATE is an opaque centered in-app modal with six 1–5 axes:

- visual
- interaction
- originality
- aliveness
- controls
- performance

Reviews persist in `user://creative_lab_reviews.cfg`.
Telemetry publishes individual changes plus consolidated `creative_preference_snapshot`.

Recovered 21-review evidence strongly rejects 026–030; 031–035 are qualitatively weak according to the host. Ratings bias future exploration but never dictate it; 24% of adaptive draws remain preference-free.

## Visual Finish Gate

Technical diversity is not a quality guarantee. Read:

`knowledge/cross-domain/VISUAL_FINISH_GATE.md`

Required creative pipeline:

`adaptive draw -> prototype -> observe -> mutate -> art-direct -> visual-finish gate -> keep/reject`

Since sketch 036, repository CI requires `definition.json.visual_finish` with:

- `composition`
- `material_model`
- `final_render`
- at least three `detail_scales`
- `interaction_stateful=true`

This is deliberately a process contract, not an automated beauty score.

## Current batch 036–040

- 036 POLAR STRESS — analytic photoelastic stress field / birefringent full-res material.
- 037 DENDRITE BLOOM — hidden phase/nutrient crystal solver -> full-res faceted mineral material.
- 038 ELECTRIC LACE — antialiased vector electrostatic field-line integration around stateful charges.
- 039 SOAP CONSTELLATION — pressure-coupled foam cells -> full-res thin-film interference material.
- 040 SCHLIEREN VEIL — hidden density/heat/velocity field -> full-res schlieren gradient optics.

Each has 8–9 meaningful controls and stateful interaction. Implemented creative signatures are recorded in `knowledge/cross-domain/creative_draw_space.json`.

## Full-canvas render contract

Logical artwork coordinates remain normally 1280×720. Physical PREVIEW/PROGRAM surfaces adapt to their actual viewport.

A node named `ShaderSurface` must use:

`res://sketches/_shared/full_canvas_surface.gd`

CI rejects fixed 1280×720 ShaderSurface offsets.

Low-resolution simulation grids are allowed as hidden state only. The final visible image must reconstruct appropriate high-resolution geometry/material/detail; do not expose enlarged nearest-neighbour solver pixels as finished art.

## Temporal-quality contract

Preferred:

`time -> force/state/memory/event -> coupled system -> render`

Rejected by default:

`time -> sin/cos -> visible position/scale/alpha/warp`

Also reject visible phase wraps, global resets, respawn walls and synchronized restarts. Physical periodic forcing is allowed only when the visible representation stays continuous.

`scripts/ci/audit_temporal_motion.py` audits the corpus. For 026+, direct clock trig requires `TEMPORAL_INTENT:`.

## Adaptive creative draw

Files:

- `knowledge/cross-domain/creative_draw_space.json`
- `knowledge/cross-domain/ADAPTIVE_CREATIVE_DRAW.md`
- `scripts/creative/draw_recipe.py`

The engine selects distant carriers/representations/operators/temporal models/interactions/constraints/render paths and penalizes recent repetition. Explicit REVIEW data is only bounded probability evidence. It is a collision generator, not an art director.

## Performance representation

- dense fields: simulate at an appropriate cadence, render via texture/fullscreen material when suitable;
- expensive neighbour/contact work belongs in simulation, not duplicated in `_draw()`;
- vector geometry is preferred when it preserves useful line/facet resolution;
- MultiMesh/GPU paths remain available for large populations;
- performance is part of visual quality, but high FPS alone never compensates for weak art direction.

## Telemetry

Local runtime telemetry lives under `res://.telemetry_runtime/`.
Sanitized remote telemetry:

```text
branch: telemetry/runtime
latest.jsonl
sessions/
```

Publishing must never block the UI. Revision 3 close handling flushes and releases the active telemetry file before spawning the final hidden PowerShell publisher, fixing the previous empty-close race in principle. Host validation still required.

After any host test, inspect matching telemetry before asking for logs or drawing conclusions.

## FARADAY continuity rule

FARADAY QUASI established an important failure case: a physically periodic state can still render badly if a wrapped phase is transformed with non-integer coefficients. Current 025 keeps forcing phase internal and visual modal phases continuous. Treat any visible seam/cut as a blocker.

## PREVIEW / PROGRAM synchronization

When linked, editor PREVIEW is simulation authority and PROGRAM follows synchronized state. On navigation/detach, final state syncs and PROGRAM continues autonomously. Never create unrelated linked timelines.

PROGRAM touch/mouse maps through the same logical design space as PREVIEW.

## Knowledge references

For substantial work consult relevant sections of:

- `TECHNIQUE_PALETTE.md`
- `RANDOM_COLLISION_ENGINE.md`
- `COLLISION_SOURCE_CATALOG.md`
- `PHYSICAL_CHEMICAL_SYSTEMS_ATLAS.md`
- `ORGANIC_COUPLING_AND_CONTROLS.md`
- `REALTIME_PERFORMANCE_BUDGET.md`
- `TEMPORAL_MOTION_QUALITY.md`
- `ADAPTIVE_CREATIVE_DRAW.md`
- `VISUAL_FINISH_GATE.md`

References supply mechanisms and constraints, never surfaces to copy.

## Optional future outputs

Spout and NDI remain future adapters and must never be represented as already working.
