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
- workstation now opens in native fullscreen by default; F11 remains sketch presentation, not app startup mode.

## Current top runtime

`app/main/main_runtime_gallery_compact_review.gd`

It extends `main_runtime_gallery_feedback_trash.gd`, then adaptive filters / organizer / PROGRAM layers.

## Latest host feedback and fix

User host-tested REVIEW v2 and explicitly rejected the RATE popup because it was transparent, ugly and not centered.

The old native `PopupPanel` implementation is rejected and must not return.

Revision 3 now uses an in-app modal:

- full-window dim backdrop;
- opaque `PanelContainer` card with design-system raised surface + border;
- true geometric centering through `CenterContainer`;
- width 430 logical UI px;
- title includes current sketch;
- six 1–5 rows;
- × close button;
- Escape closes modal first;
- outside mouse/touch closes modal;
- score persistence and Gallery badge unchanged.

New telemetry event: `review_modal_changed`.

## Startup fullscreen

The same top runtime now requests `DisplayServer.WINDOW_MODE_FULLSCREEN` after base `_ready()` has already remembered the normal 1280×720-ish restore rectangle.

Intent:

- app/workstation opens fullscreen with all workstation chrome visible;
- this is distinct from F11 render presentation;
- custom restore control can still return to remembered windowed rect;
- F11 should restore the prior fullscreen workstation mode after presentation exit.

Headless CI explicitly skips the startup mode request via `DisplayServer.get_name() == "headless"`.

New telemetry event: `workstation_startup_fullscreen` with requested/actual mode, match flag and window size.

## Telemetry evidence for this host feedback

Telemetry was inspected first, but remote telemetry was stale:

- `telemetry/runtime/latest.jsonl` empty;
- telemetry branch HEAD `dd9194667593...` dated 2026-09-25 07:09:55Z;
- therefore it does not represent the latest RATE host test.

Do not claim telemetry validated the popup bug. The visual failure comes from direct user feedback. After next test, inspect telemetry again and require tested-head/session match.

## Explicit user-rating evidence

Previously known complete vectors:

- 020 ECHO TISSUE — 4,4,4,4,4,5; average ~4.17.
- 022 LIESEGANG FRONT — 1,2,2,1,2,3; average ~1.83.
- 025 FARADAY QUASI — 3,2,2,1,2,3; average ~2.17.
- 001 SIGNAL FIELD — 3,2,2,1,3,3; average ~2.33.
- last known reviewed count: 16.

`creative_preference_snapshot` remains the preferred consolidated source after host telemetry advances.

## Temporal-loop audit

User rejects visible cheap clock periodicity. Preferred:

`time -> state/force/memory/event -> coupled dynamics -> render`

Reject by default:

`time -> sin/cos -> visible position/scale/alpha/warp`.

Rules: `knowledge/cross-domain/TEMPORAL_MOTION_QUALITY.md`.

CI script: `scripts/ci/audit_temporal_motion.py`.

Historical audit found 38 observations across <=025. For 026+, direct clock trig requires `TEMPORAL_INTENT:`; `creative_signature` also mandatory.

Current targeted fixes remain:

- 021 ROSENSWEIG: no analytic orbit/Lissajous auto motion.
- 022 LIESEGANG: no visible front snap-reset.
- 024 GRANULAR JAM: state-driven creep + event-indexed avalanche.
- 025 FARADAY: intentional physical forcing only; stateful chirp; no decorative touch-clock ripple.

## Adaptive creative draw

Files:

- `knowledge/cross-domain/creative_draw_space.json`
- `knowledge/cross-domain/ADAPTIVE_CREATIVE_DRAW.md`
- `scripts/creative/draw_recipe.py`

Anti-repetition remains historical/recent weighting + signature distance. REVIEW bias is bounded and 24% exploration ignores preferences. CI self-test: 180 unique / 180 on first validated run.

## Full-canvas contract

`ShaderSurface` must use `sketches/_shared/full_canvas_surface.gd`; CI rejects legacy fixed 1280×720 surfaces. Host `sketch_surface_contract` telemetry remains the dynamic coverage check.

## Required next host test

1. Launch: verify full workstation opens fullscreen immediately.
2. Restore to windowed and re-expand; verify no broken geometry.
3. Open any sketch and click RATE.
4. Verify RATE card is opaque, visually consistent and dead-center.
5. Restore/resize app and reopen RATE; it must stay centered.
6. Test ×, Escape, outside click/touch.
7. Change/clear a score, reopen, return Gallery and verify badge.
8. F11 active sketch then Esc; workstation should return to previous fullscreen mode.
9. Close normally, then inspect fresh `telemetry/runtime` first and require matching tested HEAD/session.

## Mandatory AI completion

After every material repository change: finish commits, update durable docs/state, resolve final remote HEAD, wait exact-head CI, report exact short SHA + CI, include canonical CI-waiting PowerShell when host validation is relevant, then telemetry-first after user test.

## Non-regressions

Do not stop PROGRAM on navigation, create independent linked timelines, block UI with telemetry Git work, restore failed cross-window texture sampling, fake Spout/NDI, restore Pressure Lattice, burn project metadata into artwork, make glyph contours the default representation, restore a permanent all-tags wall, reintroduce fixed 1280×720 ShaderSurface nodes, restore native transparent RATE popup, or use naked global-clock wobble as default aliveness.
