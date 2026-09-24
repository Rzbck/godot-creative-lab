# Current work — DC//LAB

Last refreshed: 2026-09-24.

This file is intentionally short. It records what a new AI should treat as the active product state and what not to break.

## Active branch / PR

- branch: `feat/creative-sketches-002-004-20260924`
- draft PR: `#7`
- PR base: `feat/gallery-project-workflow-20260923`
- resolve current HEAD from GitHub at session start
- do not merge to `main` without explicit user approval

## Stable product areas to preserve

- Gallery with real previews, hover animation, automatic groups, tag filters and search.
- Per-sketch parameter persistence across sessions.
- PREVIEW vs PROGRAM separation.
- Persistent PROGRAM output while user browses Gallery/Settings/other projects.
- `TAKE LIVE` to replace current PROGRAM from another preview.
- Physical output display selection.
- Touch/mouse interaction on PROGRAM output.
- Linked preview/PROGRAM runtime-state synchronization.
- Sanitized asynchronous telemetry on `telemetry/runtime`.
- Responsive workstation layout.

## Current creative content

- `001_signal_field` — technical foundation/test patch.
- `002_liquid_type` — accepted Gallery sketch; may be visually refined later.
- `003_chroma_lens` — accepted; grid density/margins recently corrected.
- `004_gommage_type` — accepted; tactile PROGRAM interaction validated.

No 005 has been approved. Do not invent one.

## Knowledge system

Use these before proposing substantial new creative directions:

- `knowledge/creative-coding/`
- `knowledge/design/`

The design library includes typography, graphic design, realtime-design translation and review criteria. The purpose is to combine professional design principles with realtime GPU/generative techniques rather than produce generic effect demos.

## Longer-term direction — not an automatic task

The PROGRAM architecture is deliberately compatible with future live-performance features such as:

- A/B/C decks;
- crossfade/mix;
- timeline/cues;
- compositing/layers;
- transitions;
- recording/capture;
- future Spout/NDI adapters.

These are directions, not permission to implement them unprompted.

## Known non-goals / rejected regressions

Do not:

- put sketch/debug titles into PROGRAM output unless text is the artwork;
- stop PROGRAM just because the editor navigates away;
- create a second independent generative timeline for linked output;
- move/resize the workstation itself as the normal live-output mechanism;
- make Git/telemetry publication synchronous on the Godot main thread;
- sample the editor SubViewport texture into another native Window on the previously failing host path;
- reintroduce card tooltips that visually cover Gallery previews;
- pretend Spout/NDI exists.

## Next-session checklist

At the start of a new task:

1. Resolve branch HEAD and CI.
2. Read online telemetry if the task follows a host test.
3. Read the exact involved runtime layer/sketch.
4. Check `knowledge/` if the task is creative/design research.
5. Implement on the feature branch.
6. Verify CI.
7. Give the user the standard PowerShell sync/run block only if a host test is needed.
8. Update `HANDOFF.md` / this file only when durable state or NEXT actually changes.
