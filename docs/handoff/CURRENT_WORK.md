# Current work — DC//LAB

Last refreshed: 2026-09-25.

## Active branch / PR

- branch: `feat/creative-sketches-002-004-20260924`
- draft PR: `#7`
- PR base: `feat/gallery-project-workflow-20260923`
- never merge/change `main` without explicit user approval
- always resolve final remote HEAD + exact-head CI after all material commits

## Stable product behavior to preserve

- Gallery real previews; only hovered card animates.
- Adaptive generated tag discovery + complete search.
- Per-sketch creative parameter persistence.
- PREVIEW / PROGRAM separation; navigation does not stop PROGRAM.
- `TAKE LIVE`, physical display selection and PROGRAM touch/mouse forwarding.
- Linked PREVIEW/PROGRAM state synchronization.
- Async sanitized telemetry on `telemetry/runtime`.
- logical artwork space usually `1280×720`, but render surfaces adapt to actual viewport.
- PROGRAM is artwork-only.
- local Trash never deletes Git source.

## Current top runtime

`app/main/main_runtime_gallery_compact_review.gd`

It extends `main_runtime_gallery_feedback_trash.gd`, then adaptive filters / organizer / PROGRAM layers.

## Explicit user-rating evidence

Fresh host telemetry from the previous runtime reported **16 reviewed sketches**. Some complete known score vectors:

- **020 ECHO TISSUE** — visual 4, interaction 4, originality 4, aliveness 4, controls 4, performance 5; average ~4.17.
- **022 LIESEGANG FRONT** — 1,2,2,1,2,3; average ~1.83; especially weak visual/aliveness.
- **025 FARADAY QUASI** — 3,2,2,1,2,3; average ~2.17; weak aliveness.
- **001 SIGNAL FIELD** — 3,2,2,1,3,3; average ~2.33.

These are explicit host ratings, not inferred taste. Do not turn them into a simplistic “copy 020” rule.

## Compact REVIEW revision

The six criteria no longer occupy permanent parameter-sidebar height.

The project inspector now shows one compact row:

`REVIEW  <avg>/5  RATE  TRASH`

`RATE` opens a popup with the existing six 1–5 axes. Persistence and Gallery `R x.x` badges remain intact.

New consolidated telemetry event:

`creative_preference_snapshot`

It emits at startup and after rating edits and contains all current reviewed sketches, rating vectors, averages, axis averages, title/tags and `creative_signature` when available. Future sessions should prefer this snapshot over reconstructing dozens of click events.

## Temporal-loop audit

User feedback: many historical sketches expose ugly predictable “loops” / sine-like bobbing. The issue is defined as **visible clock periodicity**, not programming loops in general.

New rules live in:

`knowledge/cross-domain/TEMPORAL_MOTION_QUALITY.md`

Preferred temporal chain:

`time -> state/force/memory/event -> coupled dynamics -> render`

Default rejection:

`time -> sin/cos -> visible position/scale/alpha/warp`

CI script:

`scripts/ci/audit_temporal_motion.py`

Current audit found **38 historical observations** across the <=025 corpus. Important concentrations include 002, 003, 004, 006, 009, 011, 013, 014, 015, 016, 017, 019 and previously 024. Some fixed-interval warnings are legitimate simulation/event cadences, so they are diagnostic, not blanket failures.

For 026+ direct clock trig requires `TEMPORAL_INTENT:` and a non-empty `creative_signature` is mandatory.

Do not blindly replace every historical oscillator with noise. Use ratings + visual identity to prioritize refactors.

## Current temporal fixes

### 021 ROSENSWEIG FIELD

Removed predictable Lissajous/orbiting auto magnet and shader clock wobble. Autonomous magnet now chooses deterministic-random targets with variable dwell and viscosity; visible dynamics come from source motion + hysteretic instability state.

### 022 LIESEGANG FRONT

Removed visible “front grows huge then snaps back to small” behavior. Reservoirs now consume reagent charge, exhaust, rest for variable durations and recharge; bands persist/dissolve independently. Internal radius restart happens while reservoir is visually depleted.

### 024 GRANULAR JAM

Removed clock-driven sinusoidal creep. Creep direction now comes from actual lateral velocity, confinement position, stress and stable per-grain material asymmetry. Avalanche slip patterns use real avalanche event index rather than global clock time.

### 025 FARADAY QUASI

Physical periodic forcing remains intentionally. Added `TEMPORAL_INTENT:`. Chirp no longer uses `sin(sketch_time)`; it moves between variable-duration state targets. Removed decorative clock-driven touch ripple; touch injects a local pressure impulse and modal state carries the evolution.

023 SPINODAL MARANGONI was already primarily state-driven and did not require a temporal rewrite.

## Adaptive creative draw

New system:

- `knowledge/cross-domain/creative_draw_space.json`
- `knowledge/cross-domain/ADAPTIVE_CREATIVE_DRAW.md`
- `scripts/creative/draw_recipe.py`

A draw selects carrier + two distant representation families + two distant operator families + temporal model + interaction + design constraint + render path.

Anti-repetition:

- historical frequency penalty;
- stronger previous / last-3 / last-5 penalties;
- minimum recent signature distance of 4 axes;
- forced oscillator base penalty;
- representation/operator pair families must differ.

Preference learning:

- optional explicit rating snapshot biases features only modestly (~±24% feature influence);
- **24% exploration share ignores preference bias entirely** and uses diversity constraints only;
- ratings are never permission to remove a technical family forever or clone the highest-rated sketch.

CI self-test currently validates 180 deterministic draws; first validated run produced **180 unique / 180**.

## Full-canvas contract

`ShaderSurface` must use `sketches/_shared/full_canvas_surface.gd`; CI rejects legacy fixed 1280×720 surfaces. Host `sketch_surface_contract` telemetry remains the dynamic coverage check.

## Knowledge priority

For next creative work read:

1. `knowledge/cross-domain/TEMPORAL_MOTION_QUALITY.md`
2. `knowledge/cross-domain/ADAPTIVE_CREATIVE_DRAW.md`
3. `knowledge/cross-domain/creative_draw_space.json`
4. `TECHNIQUE_PALETTE.md`
5. `RANDOM_COLLISION_ENGINE.md`
6. `COLLISION_SOURCE_CATALOG.md`
7. `PHYSICAL_CHEMICAL_SYSTEMS_ATLAS.md`
8. `ORGANIC_COUPLING_AND_CONTROLS.md`
9. `REALTIME_PERFORMANCE_BUDGET.md`
10. relevant design/creative-coding atlases.

## Required next host test

1. Verify parameter sidebar is compact: REVIEW average + RATE + TRASH only.
2. Open RATE popup, change/clear several scores, reopen and verify persistence; return Gallery and verify `R x.x`.
3. On a normal launch/close, allow telemetry publication; next AI must inspect `creative_preference_snapshot` first to recover all current ratings.
4. Watch 021 idle for ~60 s: no obvious Lissajous/orbiting loop.
5. Watch 022 through depletion/rest/recharge: no visible giant-front snap reset.
6. Watch 024 under load/release: creep/avalanche should feel state/stress-driven, not harmonic side-to-side motion.
7. Watch 025: periodic standing-wave behavior is conceptually valid, but decorative traveling touch ripple / metronomic chirp should be gone.
8. Continue rating artwork honestly; use low/high per-axis scores rather than only aggregate judgement.
9. Close normally, then inspect fresh `telemetry/runtime` and require matching tested HEAD/session before conclusions.

## Mandatory AI completion

After every material repository change: finish commits, update durable docs/state, resolve final remote HEAD, wait exact-head CI, report exact short SHA + CI, include canonical CI-waiting PowerShell when host validation is relevant, then telemetry-first after user test.

## Non-regressions

Do not stop PROGRAM on navigation, create independent linked timelines, block UI with telemetry Git work, restore failed cross-window texture sampling, fake Spout/NDI, restore Pressure Lattice, burn project metadata into artwork, make glyph contours the default representation, restore a permanent all-tags wall, reintroduce fixed 1280×720 ShaderSurface nodes, or use naked global-clock wobble as the default way to make a sketch feel alive.
