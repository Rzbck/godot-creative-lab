# Sketch Contract

This document describes the implemented DC//LAB sketch contract.

## Discovery

Creative works live under `sketches/<id>/` and provide `definition.json` with stable id, index, visible title, scene path, engine label, semantic tags and description. The host discovers metadata; do not hard-code Gallery UI per sketch.

For sketch index **026+**, `definition.json` must also contain a non-empty `creative_signature` describing the implemented creative recipe. This signature is machine-readable provenance for anti-repetition and explicit-rating correlation.

## Ownership boundary

A sketch owns creative rendering, exposed parameter schema/values, autonomous simulation/state, live-sync state and interaction inside the artwork.

The host owns Gallery/navigation, PREVIEW sizing, PROGRAM/TAKE LIVE transport, physical output routing, persistence UI, ratings/curation and telemetry publishing.

## Logical artwork space

Current design-oriented work generally uses logical `1280×720` coordinates. Logical size is **not** permission to create a fixed 1280×720 physical render rectangle.

### Full-canvas shader rule

Any scene node named `ShaderSurface` represents a full artwork surface and must cover the real SubViewport. Use:

`res://sketches/_shared/full_canvas_surface.gd`

Do not hard-code fixed 1280×720 offsets. Repository policy rejects tracked runtime scenes that violate this rule. Host telemetry emits `sketch_surface_contract` coverage diagnostics.

### Drawing-based sketches

Node2D sketches using `design_sketch_base.gd` should use the established logical-to-surface transform. Any outside margin/background must be intentional artwork, not host gray.

## Temporal behavior

A realtime sketch should normally expose the consequences of **state**, not the clock itself.

Preferred:

`time -> state / force / memory / event -> coupling -> render`

Avoid generic direct-clock animation such as `sin(sketch_time)` or shader `sin(TIME)` driving visible position, scale, alpha, drift or warp only to make the piece move.

Periodic forcing remains valid when it is the actual mechanism. For sketch index 026+, direct trigonometry from `sketch_time`, `u_time` or shader `TIME` requires a nearby `TEMPORAL_INTENT:` comment explaining that conceptual/physical need; CI enforces this source-level rule.

Visible reset loops should also be avoided: synchronized particle resets, snapping fronts, exact regime changes every N seconds, or phase wraps with visible jumps. Prefer depletion/recharge, thresholds, hysteresis, staggered events and continuous state.

See `knowledge/cross-domain/TEMPORAL_MOTION_QUALITY.md`.

## Creative signature / adaptive draw

The default exploration tool is `scripts/creative/draw_recipe.py` using `knowledge/cross-domain/creative_draw_space.json`.

A substantial new signature normally specifies:

- carrier;
- two representations from different families;
- two operators from different families;
- temporal model;
- interaction consequence;
- design constraint;
- render path.

The draw is a starting constraint, not finished art. Follow with coupled prototype -> observe -> interpret -> art-direct -> mutate.

Do not simply clone the highest-rated sketch. Preference data is a bounded bias and an exploration share remains deliberately un-biased.

## Parameters

Sketches may expose `get_parameter_schema()`, `get_parameter_value(id)` and `set_parameter_value(id, value)`. The host persists values in `user://creative_lab_sketch_settings.cfg`.

Substantial creative labs normally expose 6–9 genuinely independent controls when the mechanism supports that depth.

## Live synchronization

When PREVIEW and PROGRAM are linked, the editor instance is simulation authority. Generative sketches implement the existing live-sync methods instead of starting an unrelated second timeline in PROGRAM.

## Interaction

Pointer/touch coordinates map through the same logical design transform in PREVIEW and physical PROGRAM. Interaction should modify state and preferably leave consequences that the system redistributes after release.

## Artwork / interface boundary

PROGRAM is artwork-only. Do not burn sketch index, title, tags, debug labels or project metadata into output unless that text is genuinely part of the artwork.

## User review / curation

Ratings and trash state belong to the workstation, not sketch source.

- reviews persist in `user://creative_lab_reviews.cfg`;
- individual edits emit `sketch_review_changed`;
- consolidated explicit preferences emit `creative_preference_snapshot`;
- local trash/retirement persists in `user://creative_lab_curation.cfg`;
- workstation purge does not delete version-controlled source.

Repository deletion remains an explicit Git operation.
