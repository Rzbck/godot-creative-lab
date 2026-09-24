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

- `knowledge/creative-coding/` — technical vocabulary: shaders, simulation, fields, feedback, particles, GPU/generative methods.
- `knowledge/design/` — typography, graphic design, hierarchy, grids, color, composition, realtime-design translation and review criteria.
- `knowledge/cross-domain/` — translation atlas + idea engine for converting material between domains and deliberately mutating combinations into original visual identities.

For a new creative direction, do not merely pick one shader technique and one visual reference. Identify carriers/representations/operators, build at least one genuine cross-domain bridge, then use `CROSS_DOMAIN_ATLAS.md` and `IDEA_ENGINE.md` to mutate the first coherent combination before implementation.

The goal is professional generative systems with their own identity rather than generic effect demos or source imitation.

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
4. Check `knowledge/creative-coding/`, `knowledge/design/` and `knowledge/cross-domain/` if the task is creative/design research.
5. For a new artwork, generate and mutate a concept before implementation rather than copying a single reference/effect.
6. Implement on the feature branch.
7. Verify CI.
8. Give the user the standard PowerShell sync/run block only if a host test is needed.
9. Update `HANDOFF.md` / this file only when durable state or NEXT actually changes.
