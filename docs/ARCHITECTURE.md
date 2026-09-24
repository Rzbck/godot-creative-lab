# Architecture — DataC0re Creative Lab

## Status

Implemented Godot 4.7.1 creative-coding workstation.

This document describes the current runtime model, not the original scaffold plan.

## Product model

DC//LAB separates three responsibilities:

1. **WORKSTATION / EDITOR** — Gallery, Settings, PREVIEW, parameter controls, navigation.
2. **PROGRAM / LIVE OUT** — the physical audience-facing output on a selected display.
3. **SKETCH** — isolated creative runtime with parameters and optional live-state synchronization contract.

The key rule is that navigation in the workstation is not PROGRAM transport.

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

PROGRAM can keep running while the workstation browses the Gallery or edits a different project.

## Files / ownership

```text
app/                     application UI + runtime host
sketches/                isolated creative works
shared/                  genuinely reusable project resources
knowledge/               external research memory / design references
scripts/                 validation and telemetry publishing utilities
.telemetry_runtime/      local runtime telemetry (ignored)
```

Each sketch owns its scene/scripts/resources under `sketches/<id>/` and provides `definition.json` metadata.

## Main runtime

Godot entry scene:

`res://app/main/main_runtime.tscn`

At the time of this handoff the top runtime script is:

`res://app/main/main_runtime_gallery_organizer.gd`

It extends the implemented runtime layers beneath it. Important current layers include:

```text
main_runtime_gallery_organizer.gd
    -> main_runtime_program_output.gd
        -> main_runtime_gallery_persistence.gd
            -> main_runtime_live_output.gd
                -> lower output/window/telemetry layers
```

Always follow the actual `extends` chain in Git before editing. Several historical layers exist because window/output behavior was iteratively debugged on the real Windows/Godot host.

Do not refactor the chain merely for aesthetic cleanliness while live behavior is stable unless the task explicitly calls for consolidation and includes regression testing.

## Gallery architecture

Sketches are discovered from `sketches/*/definition.json`.

Current Gallery behavior:

- builds a real `SubViewport` render for each thumbnail;
- freezes thumbnails when idle;
- animates only the hovered card;
- restores persisted sketch parameters into thumbnails;
- groups cards automatically using the first tag as primary family;
- exposes all tags as generated filters;
- searches id/index/title/engine/description/tags;
- hides empty groups after filtering;
- keeps group card grids responsive to available width.

The Gallery must scale to many sketches without hard-coded per-project UI changes.

## Sketch contract

A sketch should expose parameter metadata/value access through the established methods used by current sketches.

The host builds the inspector from that contract and persists values in:

`user://creative_lab_sketch_settings.cfg`

For linked PROGRAM output, generative sketches should expose the existing live-sync state contract so the PROGRAM renderer follows the editor simulation rather than running an unrelated second timeline.

Current design sketches use a stable logical design space so different preview/output resolutions do not change composition topology.

## PREVIEW / PROGRAM behavior

### Linked state

When the project currently open in PREVIEW is also the project in PROGRAM:

- editor instance is the simulation authority;
- output renderer is a follower;
- parameters and runtime state are mirrored continuously;
- workstation remains interactive.

### Detached state

When the user returns to Gallery or opens a different project:

- PROGRAM is not stopped;
- final linked state is synchronized;
- PROGRAM renderer becomes autonomous and continues from that state;
- the newly opened editor project gets normal realtime preview behavior.

### TAKE LIVE

If a different project is in PREVIEW while another project is live:

- UI presents `TAKE LIVE`;
- invoking it replaces PROGRAM with the current PREVIEW project;
- transport replacement should not require closing the workstation.

This boundary is intentionally suitable for future A/B/C deck or mixing architecture.

## Physical output

User selects output display in Settings.

PROGRAM runs on a dedicated native output surface while the workstation remains on its own display.

A previously attempted approach that sampled the editor SubViewport texture into another native Window produced gray output on the validated host. Current live output instead uses an output renderer instance with synchronized state.

Do not replace the working PROGRAM model with workstation fullscreen/window-resize behavior without strong host evidence.

## Touch / pointer input

Input from the native PROGRAM surface is explicitly forwarded.

Requirements:

- `ScreenTouch` / `ScreenDrag` supported;
- mouse motion / primary button supported;
- physical coordinates mapped into the sketch logical design space;
- while linked, input updates the source/master sketch and then synchronizes to output;
- while detached, input targets the autonomous PROGRAM sketch even if the workstation is browsing another page/project.

## Telemetry architecture

Local runtime telemetry:

`res://.telemetry_runtime/`

Sanitized online telemetry:

```text
branch: telemetry/runtime
latest.jsonl
sessions/
```

Publication is asynchronous/queued. It must not block the Godot main thread.

Telemetry captures state needed to debug:

- native/root window modes and geometry;
- layout sizes/minimum-size overflow;
- SubViewport/render state;
- numeric render probes;
- physical output display;
- PROGRAM/editor linkage;
- live-sync counts/state;
- touch/mouse forwarding;
- resize/navigation transitions.

## UI / layout

The workstation uses a custom dark compact application shell.

Important rules:

- app chrome never appears in PROGRAM output;
- output remains visually clean;
- runtime resizing must not let preview minimum size explode the application layout;
- Gallery card overlays/tooltips must not obscure previews;
- sketch/debug captions are not burned into final creative output unless intentionally part of the artwork.

## Knowledge / creative research

Before substantial new creative work, consult:

- `knowledge/creative-coding/`
- `knowledge/design/`

The goal is to combine reputable creative-coding methods with professional typography, layout, grid, hierarchy, color and graphic-design principles.

The library stores links/summaries/tags and project notes by default, not copied third-party source code.

## Optional future outputs

Spout and NDI remain future adapters.

They are not implemented and must not be represented as working.

Any future native integration must document source/version/license and preserve a clean fallback when unavailable.

## Validation

Runtime changes require:

- repository policy;
- Godot 4.7.1 headless import;
- main-scene smoke test;
- tracked-file cleanliness after import;
- host validation when behavior depends on Windows/display/touch/runtime presentation.

CI: `.github/workflows/ci.yml`

Local check: `scripts/check.ps1`

Use telemetry as the first source of evidence after host tests.