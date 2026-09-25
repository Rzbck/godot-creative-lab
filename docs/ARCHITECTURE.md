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

Entry scene: `res://app/main/main_runtime.tscn`.

Current top runtime layer: `res://app/main/main_runtime_window_memory.gd`.

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

## Workstation window state — revision 2

State persists in `user://creative_lab_window_state.cfg` and is restored before the first visible workstation frame.

The previous custom Maximize path used native maximize on a borderless Windows client. Host telemetry proved that Godot/Windows could reclassify the resulting monitor-sized client as fullscreen. That path is rejected.

Revision 2 keeps workstation expansion distinct from artwork presentation:

- logical `maximized` is implemented as borderless `WINDOWED` geometry using the current screen usable rect;
- a 2 px bottom guard prevents the exact monitor-sized client from being reclassified as fullscreen;
- the normal window restore rect remains separately tracked;
- revision-1 saved fullscreen created by the old Maximize path migrates to logical maximized;
- F11 / PROGRAM presentation stays separate and does not overwrite workstation state;
- `workstation_window_state_restored` records the restored logical/native state.

Current state: **REPO_VALIDATED / HOST_VALIDATION_REQUIRED**.

## Gallery architecture

Sketches are discovered from `sketches/*/definition.json`. Current source catalogue: **001–035**.

Current Gallery behavior:

- real SubViewport thumbnail render per sketch;
- idle thumbnails freeze; only hovered card animates;
- persisted sketch parameters restore into thumbnails;
- first tag defines automatic primary group;
- search indexes id/index/title/engine/description/all tags;
- permanent filter rail stays bounded with collapsed rare tags;
- empty groups disappear and card grids respond to width.

Do not restore a permanent all-tags wall.

## Review / preference feedback loop

Parameter sidebar contains `REVIEW <avg> RATE TRASH`.

RATE is a centered **in-app opaque modal**, not a native popup. Reviews persist in `user://creative_lab_reviews.cfg`; rated cards display `R x.x`.

Telemetry:

- `sketch_review_changed` — individual edits;
- `creative_preference_snapshot` — consolidated reviewed set + axis averages.

Explicit ratings are bounded creative evidence, not clone instructions. If telemetry is empty/stale, never invent ratings. Direct qualitative host feedback should be recorded as qualitative evidence.

The host explicitly rejected 026–030 as globally visually weak. Their technical diversity is not evidence of successful art direction.

## Local Trash / curation

`TRASH` hides a sketch locally from the Gallery. State lives in `user://creative_lab_curation.cfg`.

RESTORE is supported; expiration/PURGE means local retirement only. The workstation never deletes version-controlled `res://sketches/...` files.

## Full-canvas render contract

Logical design coordinates are normally `1280×720`, but physical render surfaces follow real PREVIEW/PROGRAM size.

Any node named `ShaderSurface` must use `res://sketches/_shared/full_canvas_surface.gd`. CI rejects fixed 1280×720 ShaderSurface offsets. Host publishes `sketch_surface_contract` telemetry.

Drawing-based sketches use the logical-to-surface transform from `design_sketch_base.gd`; any margin/background must be intentional artwork, never host gray.

## Visual-finish contract

Substantial creative work must read and satisfy `knowledge/cross-domain/VISUAL_FINISH_GATE.md`.

Technical novelty or signature distance is not enough. A kept work should provide:

- a strong frozen frame before motion is considered;
- authored composition, hierarchy and negative space;
- persistent visual identity anchors;
- several meaningful detail scales where appropriate;
- final PROGRAM imagery that reads as high-resolution rather than an enlarged coarse solver;
- material/light logic coherent with the claimed carrier;
- no visible phase wrap, reset, respawn wall or synchronized restart;
- interaction entering state/material logic rather than overlaying a generic cursor effect.

A low-resolution solver may exist as hidden state, but the final renderer must reconstruct a convincing high-resolution surface/geometry/field.

## Temporal-quality contract

Preferred:

`time -> force/state/memory/event -> coupled system -> render`

Rejected by default:

`time -> sin/cos -> visible position/scale/alpha/warp`

Periodic forcing is valid when it is actually the mechanism, but its state must remain visually continuous. FARADAY QUASI's old wrapped forcing phase multiplied by fractional shader coefficients is the canonical example of a physically-motivated oscillator still failing the visual contract.

`scripts/ci/audit_temporal_motion.py` audits the corpus. Existing <=025 findings are warnings; for 026+ direct clock trigonometry requires nearby `TEMPORAL_INTENT:` justification.

## Adaptive creative draw

Files:

- `knowledge/cross-domain/creative_draw_space.json`
- `knowledge/cross-domain/ADAPTIVE_CREATIVE_DRAW.md`
- `scripts/creative/draw_recipe.py`
- `knowledge/cross-domain/VISUAL_FINISH_GATE.md`

The draw selects carrier, distant representation/operator families, temporal model, interaction consequence, design constraint and render path. Historical/recent reuse is penalized. Explicit REVIEW data applies only bounded preference bias; 24% of draws deliberately ignore preference bias.

The draw is only a collision generator. Required pipeline:

`draw -> prototype -> observe -> interpret -> mutate -> art-direct -> visual-finish gate -> keep/reject`

For 026+, `definition.json` includes non-empty `creative_signature`. Record the implemented/mutated signature, not a discarded raw draw.

## Creative batches

026–030 remain in source/history but are **creatively rejected by host**.

Current high-fidelity batch 031–035 deliberately spans different final render representations:

- **031 FOLD CHAMBER** — Delaunay vector relief + constrained spring surface + facet shading.
- **032 LUMEN SWARM** — MultiMesh luminous streak field + spatial advection + inertial source.
- **033 OBSIDIAN CATHEDRAL** — full-resolution SDF raymarch architecture with AO/material response and persistent fracture state.
- **034 PHOSPHOR SAND** — hidden 128×72 memory field driving a full-resolution reconstructed material surface.
- **035 DUNE CHOIR** — damped 2D wave PDE rendered as dense perspective antialiased vector topography.

Their code batch passed repository policy + Godot 4.7.1 import/smoke before subsequent documentation commits. Final completion still requires CI on the exact final HEAD.

## FARADAY QUASI correction

025 no longer exposes wrapped forcing phase to the shader. Visual modal phases remain continuous, and pointer input modifies modal state rather than adding a click-local height bump. This correction is repository-validated but still needs Windows host visual validation.

## Parameters / persistence

Sketch parameter values persist in `user://creative_lab_sketch_settings.cfg`. Substantial labs normally expose 6–9 meaningful independent controls when the mechanism supports them.

## PREVIEW / PROGRAM synchronization

When PREVIEW and PROGRAM are linked, editor sketch is simulation authority and PROGRAM follows synchronized state. On navigation/detach, final state synchronizes and PROGRAM continues autonomously. Do not create unrelated linked timelines.

## Physical output / input

PROGRAM uses the established output path on the selected display. A historical cross-window texture-sampling path produced gray output and must not be casually restored.

Touch/mouse on PROGRAM is forwarded into the same logical design space used by PREVIEW.

## Telemetry

Local runtime telemetry: `res://.telemetry_runtime/`.

Sanitized online telemetry:

```text
branch: telemetry/runtime
latest.jsonl
sessions/
```

Publication is asynchronous and must never block UI. A publisher PID is not proof upload succeeded.

The latest failed host pass exposed a close-path publication bug where an empty final payload replaced `latest.jsonl`. The close path now flushes and starts one final publisher before quitting. This fix requires host validation; next session must require a non-empty matching telemetry session before trusting new ratings.

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
- `VISUAL_FINISH_GATE.md`

References provide mechanisms/principles, not surfaces to copy.

## Optional future outputs

Spout and NDI remain future adapters and must not be represented as working.
