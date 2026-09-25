# Architecture — DataC0re Creative Lab

## Status

Implemented Godot 4.7.1 creative-coding workstation. Repository state + telemetry are authoritative when they disagree with chat history.

## Product model

DC//LAB separates:

1. **WORKSTATION / EDITOR** — Gallery, Settings, PREVIEW, parameters, compact review/curation and navigation.
2. **PROGRAM / LIVE OUT** — audience-facing output on a selected physical display.
3. **SKETCH** — isolated creative runtime with parameters, interaction and optional live-state synchronization.

Navigation is not PROGRAM transport. PROGRAM keeps running while the workstation browses or opens another PREVIEW. `TAKE LIVE` replaces PROGRAM explicitly.

## Main runtime

Entry scene:

`res://app/main/main_runtime.tscn`

Current top runtime layer:

`res://app/main/main_runtime_gallery_compact_review.gd`

Important chain:

```text
main_runtime_gallery_compact_review.gd
    -> main_runtime_gallery_feedback_trash.gd
        -> main_runtime_gallery_adaptive_filters.gd
            -> main_runtime_gallery_organizer.gd
                -> main_runtime_program_output.gd
                    -> main_runtime_gallery_persistence.gd
                        -> main_runtime_live_output.gd
                            -> lower output/window/telemetry layers
```

Always inspect the actual `extends` chain before changing host architecture.

## Gallery architecture

Sketches are discovered from `sketches/*/definition.json`.

Current Gallery behavior:

- real SubViewport thumbnail render per sketch;
- idle thumbnails freeze; only hovered card animates;
- persisted sketch parameters restore into thumbnails;
- first tag defines automatic primary group;
- search indexes id/index/title/engine/description/all tags;
- permanent filter rail is bounded: `ALL` + at most six generated useful tags;
- universal tags are omitted; rare/rest tags live in collapsed `MORE`;
- active rare tag is promoted while selected;
- empty groups disappear; card grids respond to width.

Do not restore a permanent all-tags wall.

## Review / preference feedback loop

The parameter sidebar contains only a compact row:

`REVIEW  <avg>  RATE  TRASH`

`RATE` opens a temporary popup with six explicit 1–5 criteria:

- visual;
- interaction;
- originality;
- aliveness;
- controls;
- performance.

Reviews persist in `user://creative_lab_reviews.cfg`. Rated cards display `R x.x`.

Two telemetry levels exist:

- `sketch_review_changed` — individual edit event;
- `creative_preference_snapshot` — consolidated current ratings for every reviewed sketch plus axis averages, emitted at startup and after rating changes.

Future creative decisions should use the consolidated explicit ratings when available. Ratings are evidence and probability bias; they must not become a cloning/ranking mechanism that collapses exploration.

## Local trash / curation

`TRASH` hides a sketch locally from the Gallery. State lives in `user://creative_lab_curation.cfg`.

- `TRASH n` drawer appears only when needed;
- RESTORE supported;
- 7/14/30 day retention, default 30;
- expiration / PURGE means local retirement;
- workstation never deletes version-controlled `res://sketches/...` files.

Actual source deletion remains an explicit Git operation.

## Full-canvas render contract

Logical design coordinates are normally `1280×720`, but render surfaces must follow the real PREVIEW/PROGRAM size.

A node named `ShaderSurface` is a semantic full-canvas surface and must use:

`res://sketches/_shared/full_canvas_surface.gd`

CI rejects legacy fixed 1280×720 ShaderSurface offsets. The host also applies a runtime fallback and publishes `sketch_surface_contract` coverage telemetry.

Drawing-based sketches use logical-to-surface transforms from `design_sketch_base.gd`; any aspect-fit margin must be intentional artwork, never exposed host gray.

## Temporal-quality contract

DC//LAB distinguishes **state evolution** from **visible clock animation**.

Preferred:

`time -> force/state/memory/event -> coupled system -> render`

Rejected by default:

`time -> sin/cos -> visible position/scale/alpha/warp`

Periodic forcing is valid when it is genuinely part of the mechanism (for example Faraday excitation), but final visible motion should still emerge through state rather than unrelated decorative wobble.

Rules are documented in:

`knowledge/cross-domain/TEMPORAL_MOTION_QUALITY.md`

`scripts/ci/audit_temporal_motion.py` audits the historical corpus. Existing <=025 findings are warnings; for 026+ direct clock trigonometry requires a nearby `TEMPORAL_INTENT:` explanation. Fixed update cadences are diagnostic warnings, not automatically artistic failures.

## Adaptive creative draw

Future exploration starts from a machine-readable diversity-aware draw rather than repeatedly choosing familiar techniques by intuition.

Files:

- `knowledge/cross-domain/creative_draw_space.json`
- `knowledge/cross-domain/ADAPTIVE_CREATIVE_DRAW.md`
- `scripts/creative/draw_recipe.py`

A recipe draws:

- carrier;
- two representations from different technical families;
- two operators from different families;
- temporal model;
- interaction consequence;
- severe design constraint;
- render path.

Weighting penalizes historically/recently reused features and requires substantial distance from recent signatures. Explicit REVIEW data may apply a bounded preference bias, but 24% of draws deliberately ignore preference bias and remain exploration-first.

For sketch index 026+, `definition.json` must include a non-empty `creative_signature`. Record only implemented/kept work in draw history, not every discarded candidate.

CI self-tests the draw engine across 180 deterministic seeds to detect diversity collapse or oscillator/render-path dominance.

## Parameters / persistence

Sketch parameter values persist in:

`user://creative_lab_sketch_settings.cfg`

Substantial labs normally expose 6–9 meaningful independent controls when the mechanism supports them.

## PREVIEW / PROGRAM synchronization

When PREVIEW and PROGRAM are linked, the editor sketch is simulation authority and PROGRAM follows synchronized state. On navigation/detach, the final state is synchronized and PROGRAM continues autonomously. Do not create unrelated linked timelines.

## Physical output / input

PROGRAM uses a dedicated native output renderer on the selected display. A historical cross-window texture-sampling path produced gray output and must not be casually restored.

Touch/mouse on PROGRAM is forwarded into the same logical design space used by PREVIEW. Linked input updates source/master state; detached PROGRAM remains interactable while the workstation browses elsewhere.

## Telemetry

Local runtime telemetry: `res://.telemetry_runtime/`

Sanitized online telemetry:

```text
branch: telemetry/runtime
latest.jsonl
sessions/
```

Publication is asynchronous and must never block the Godot UI. After a host test, require telemetry to match the tested HEAD/session before drawing conclusions.

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
