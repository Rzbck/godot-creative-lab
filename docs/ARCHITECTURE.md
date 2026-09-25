# Architecture — DataC0re Creative Lab

## Status

Implemented Godot 4.7.1 creative-coding workstation.

This document describes the current runtime model, not the original scaffold plan.

## Product model

DC//LAB separates three responsibilities:

1. **WORKSTATION / EDITOR** — Gallery, Settings, PREVIEW, parameter controls, reviews, curation and navigation.
2. **PROGRAM / LIVE OUT** — audience-facing output on a selected physical display.
3. **SKETCH** — isolated creative runtime with parameters and optional live-state synchronization contract.

Navigation is not PROGRAM transport.

```text
Gallery / Settings / PREVIEW
          |
          | TAKE LIVE
          v
       PROGRAM
          |
          v
selected physical display
```

PROGRAM can keep running while the workstation browses the Gallery or edits another project.

## Files / ownership

```text
app/                     application UI + runtime host
sketches/                isolated creative works
shared/                  reusable project resources
knowledge/               research / design / cross-domain system
scripts/                 validation and telemetry publishing utilities
.telemetry_runtime/      local runtime telemetry (ignored)
```

Each sketch owns scene/scripts/resources under `sketches/<id>/` and provides `definition.json` metadata.

## Main runtime

Entry scene:

`res://app/main/main_runtime.tscn`

Current top runtime script:

`res://app/main/main_runtime_gallery_feedback_trash.gd`

Important chain:

```text
main_runtime_gallery_feedback_trash.gd
    -> main_runtime_gallery_adaptive_filters.gd
        -> main_runtime_gallery_organizer.gd
            -> main_runtime_program_output.gd
                -> main_runtime_gallery_persistence.gd
                    -> main_runtime_live_output.gd
                        -> lower output/window/telemetry layers
```

Always inspect the actual `extends` chain before changing host architecture. Do not refactor working output/window layers merely for cleanliness without real host regression testing.

## Gallery architecture

Sketches are discovered from `sketches/*/definition.json`.

Current Gallery behavior:

- real `SubViewport` thumbnail render per sketch;
- idle thumbnails freeze; only hovered card animates;
- persisted sketch parameters restore into thumbnails;
- first tag defines automatic primary group;
- search indexes id/index/title/engine/description/**all tags**;
- adaptive tag rail keeps `ALL` plus at most six useful generated quick tags;
- universal tags are omitted when they filter nothing;
- rare/remaining tags live in collapsed `MORE`;
- active rare tag is promoted while selected;
- empty groups disappear;
- card grids respond to available width.

The tag rail is statistical/presentational, not a second manually curated taxonomy. Rich metadata may continue to grow without creating a permanent tag wall.

## User review / creative-feedback loop

Every opened sketch receives a workstation-side `REVIEW` block after its creative parameters.

Six independent 1–5 criteria are currently stored:

- visual;
- interaction;
- originality;
- aliveness;
- controls;
- performance.

Reviews persist locally in:

`user://creative_lab_reviews.cfg`

Rated Gallery cards display a compact aggregate badge (`R x.x`). Changes emit sanitized numeric `sketch_review_changed` telemetry including the criterion scores and average. Future AI sessions should treat these explicit host ratings as first-class creative evidence when deciding what to improve, mutate, repeat or avoid.

Review data does not modify sketch source files.

## Local trash / curation

The workstation can hide a sketch from the local Gallery through `MOVE TO TRASH`.

State persists in:

`user://creative_lab_curation.cfg`

Behavior:

- trashed sketch disappears from normal catalogue immediately;
- Gallery shows `TRASH n` only when trash is non-empty;
- drawer supports `RESTORE`;
- retention can be 7 / 14 / 30 days (default 30);
- expired items move to local `retired` state;
- `PURGE` also moves the item to local retired state immediately.

Important safety boundary: workstation trash/purge **does not delete version-controlled `res://sketches/...` source files**. Actual Git deletion remains an explicit repo operation. This keeps accidental artistic deletion reversible at the source-history level and works in packaged/read-only builds.

## Sketch rendering / full-canvas contract

Logical design size is normally `1280×720`, but the real PREVIEW/PROGRAM surface can be any size.

A logical design size is not a fixed render rectangle.

For shader-backed sketches, a node named `ShaderSurface` is a semantic full-canvas surface and must use:

`res://sketches/_shared/full_canvas_surface.gd`

The component follows the actual `SubViewport` size in thumbnails, resizable/maximized PREVIEW, F11 presentation and PROGRAM.

The host additionally scans named `ShaderSurface` controls and applies a runtime sizing fallback. When a sketch opens it emits `sketch_surface_contract` telemetry with viewport size, surface count, minimum coverage and pass/fail.

Repository policy in `scripts/ci/validate_repository.py` fails when a runtime scene contains `ShaderSurface` but:

- does not reference the shared full-canvas component;
- restores a fixed `offset_right = 1280`;
- restores a fixed `offset_bottom = 720`;
- omits a script assignment on the surface.

This guard was added after host validation showed FARADAY QUASI receiving a correct 1520×852 PREVIEW while its own `ColorRect` remained fixed at 1280×720.

Drawing-based Node2D sketches should keep using logical-to-surface transforms from the shared design base. Any aspect-fit margin/background must be intentional artwork, never accidental host gray.

See `docs/SKETCH_CONTRACT.md` for the complete sketch-facing contract.

## Parameters / persistence

A sketch exposes the established parameter schema/value methods. The host generates its inspector and persists creative parameter values in:

`user://creative_lab_sketch_settings.cfg`

Ratings and curation use their separate workstation-owned config files described above.

## PREVIEW / PROGRAM behavior

### Linked state

When the project open in PREVIEW is also in PROGRAM:

- editor instance is simulation authority;
- output renderer follows;
- parameters/runtime state mirror continuously;
- workstation remains interactive.

### Detached state

When the user returns to Gallery or opens another project:

- PROGRAM is not stopped;
- final linked state is synchronized;
- PROGRAM becomes autonomous from that state;
- the new editor project gets normal PREVIEW behavior.

### TAKE LIVE

A different PREVIEW project can replace the current PROGRAM using `TAKE LIVE` without closing the workstation.

## Physical output

PROGRAM runs on a dedicated native output surface for the selected display while workstation UI remains available.

A historical cross-window texture-sampling approach produced gray output on the validated Windows host. Current live output uses a separate renderer instance synchronized to source state. Do not resurrect the failed texture path casually.

## Touch / pointer input

Requirements:

- `ScreenTouch` / `ScreenDrag`;
- mouse motion / primary button;
- physical coordinates mapped into logical design space;
- linked input updates source/master then syncs to output;
- detached PROGRAM remains interactable while workstation browses elsewhere.

## Telemetry architecture

Local runtime telemetry:

`res://.telemetry_runtime/`

Sanitized online telemetry:

```text
branch: telemetry/runtime
latest.jsonl
sessions/
```

Publication is asynchronous/queued and must never block the UI.

Telemetry includes window/layout, SubViewport/render state, output display, PREVIEW/PROGRAM linkage, input mapping, resize/navigation, Gallery filter state, review events, trash/restore events and shader-surface coverage diagnostics.

After a host test, always require telemetry to match the tested HEAD/session before drawing performance conclusions.

## UI / layout rules

- app chrome never appears in PROGRAM;
- output remains visually clean;
- PREVIEW resizing cannot expose unrendered host gray because a sketch surface stayed fixed-size;
- Gallery overlays/tooltips do not obscure artwork;
- Gallery filtering remains compact as the catalogue grows;
- project metadata is never burned into artwork unless intentionally part of the piece.

## Knowledge / creative research

Consult the relevant layers before substantial creative work:

- `knowledge/creative-coding/`;
- `knowledge/design/`;
- `knowledge/cross-domain/`.

Current exploration often uses collision-first research, physical/chemical causal systems, organic coupling and explicit realtime performance budgets. References provide principles and mechanisms, not looks to copy.

## Optional future outputs

Spout and NDI remain future adapters. They are not implemented and must not be represented as working.
