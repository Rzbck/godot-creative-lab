# Sketch Contract

This document describes the implemented DC//LAB sketch contract.

## Discovery

Creative works live under:

```text
sketches/<id>/
```

Each Gallery sketch provides `definition.json` with at least:

- stable `id`;
- `index`;
- visible `title`;
- scene path;
- engine label;
- semantic tags;
- description.

The host discovers sketches from metadata. Do not hard-code Gallery UI per sketch.

## Ownership boundary

A sketch owns:

- creative rendering;
- its exposed parameter schema/values;
- its autonomous simulation/state;
- its live-sync state contract when generative;
- interaction behavior inside the artwork.

The host owns:

- Gallery/navigation;
- PREVIEW sizing;
- PROGRAM / TAKE LIVE transport;
- physical output routing;
- persistence UI;
- ratings/curation;
- telemetry publishing.

## Logical artwork space

Current design-oriented sketches use a logical `1280×720` coordinate system so composition and input mapping remain stable across thumbnail, PREVIEW and PROGRAM sizes.

Logical size is **not** permission to create a fixed 1280×720 render surface.

### Full-canvas shader rule

Any scene node named `ShaderSurface` represents a full artwork surface and must cover the actual `SubViewport` at runtime.

Use:

`res://sketches/_shared/full_canvas_surface.gd`

Do not hard-code:

```text
offset_right = 1280
offset_bottom = 720
```

on a `ShaderSurface`.

The shared component follows the real viewport in Gallery thumbnails, resizable/maximized PREVIEW, F11 presentation and PROGRAM output. The host also contains a runtime fallback and emits `sketch_surface_contract` telemetry with coverage diagnostics.

`scripts/ci/validate_repository.py` rejects tracked runtime scenes that contain a `ShaderSurface` without the shared sizing component or that restore fixed 1280×720 offsets.

This is a non-regression rule: a sketch must never reveal gray/unrendered canvas simply because the workstation PREVIEW is larger than the logical design size.

## Drawing-based sketches

Node2D sketches using `design_sketch_base.gd` should use the established logical-to-surface transform (`begin_design_draw` / `end_design_draw`, or equivalent helpers) so the artwork is composed intentionally in any viewport.

The background/canvas outside an aspect-fitted logical composition must still be intentional artwork, not accidental host gray.

## Parameters

Sketches may expose:

- `get_parameter_schema()`
- `get_parameter_value(id)`
- `set_parameter_value(id, value)`

The host generates controls and persists values in:

`user://creative_lab_sketch_settings.cfg`

Substantial creative laboratories normally expose 6–9 genuinely independent controls when the mechanism supports that depth.

## Live synchronization

When PREVIEW and PROGRAM are linked, the editor instance is the simulation authority. Generative sketches should implement the existing live-sync state methods used by current work rather than starting an unrelated second timeline in PROGRAM.

## Interaction

Pointer/touch coordinates must map through the same logical design transform in PREVIEW and physical PROGRAM output.

Interaction should modify the sketch state; project navigation and output transport remain host responsibilities.

## Artwork / interface boundary

The PROGRAM canvas is artwork-only. Do not burn sketch index, title, tags, debug labels or project metadata into the render unless the text is intentionally part of the artwork itself.

## User curation

Ratings and trash state belong to the workstation, not to sketch source files.

- reviews are stored locally in `user://creative_lab_reviews.cfg` and emitted as sanitized numeric telemetry events;
- local trash/retirement state is stored in `user://creative_lab_curation.cfg`;
- the runtime does not delete version-controlled `res://sketches/...` source files.

Repository deletion remains an explicit human/AI Git operation, separate from workstation curation.
