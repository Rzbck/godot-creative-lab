# HANDOFF — DataC0re Creative Lab

Canonical restart point for a new human or AI session.

Always resolve the real remote branch HEAD and exact-head CI before trusting recorded SHAs. Repository state + matching runtime telemetry beat chat history.

Last material refresh: 2026-09-25.

## Repository / active work

- GitHub: `Rzbck/godot-creative-lab`
- local workstation: `E:\_Project\GodotCreativeLab`
- Godot GUI: `C:\Godot\Godot_v4.7.1-stable_win64.exe`
- Godot console: `C:\Godot\Godot_v4.7.1-stable_win64_console.exe`
- active branch: `feat/creative-sketches-002-004-20260924`
- draft PR: `#7`
- PR base: `feat/gallery-project-workflow-20260923`
- never merge/change `main` without explicit user approval

## Product state to preserve

DC//LAB is a Godot creative-coding workstation with data-driven Gallery discovery, real thumbnails, hover previews, generated parameter inspector/persistence, compact REVIEW/Trash curation, PREVIEW / PROGRAM separation, persistent PROGRAM while navigating, `TAKE LIVE`, physical display selection, PROGRAM touch/mouse forwarding, linked state synchronization, async telemetry and versioned creative research.

PROGRAM canvas is artwork-only. Logical design coordinates are normally 1280×720, but render surfaces must adapt to actual viewport.

The workstation now requests native fullscreen at startup. This is **not** F11 presentation: the complete workstation UI stays visible. F11 remains the render-presentation mode for an active sketch and should restore the prior workstation fullscreen mode on exit. The normal-window rectangle is remembered before startup fullscreen so the custom restore button can still return to windowed mode.

## Current top runtime

`res://app/main/main_runtime_gallery_compact_review.gd`

Chain starts:

```text
main_runtime_gallery_compact_review.gd
    -> main_runtime_gallery_feedback_trash.gd
        -> main_runtime_gallery_adaptive_filters.gd
            -> main_runtime_gallery_organizer.gd
                -> main_runtime_program_output.gd
                    -> ...
```

Always inspect actual code before editing the chain.

## REVIEW UI — revision 3

The previous native `PopupPanel` RATE UI was host-rejected: transparent/ugly and visibly off-center.

Do not restore that implementation.

Permanent parameter sidebar remains compact:

`REVIEW <avg>/5  RATE  TRASH`

`RATE` now opens an **in-app modal**, not a native popup:

- full-window darkened backdrop;
- opaque raised-surface card using the workstation design system;
- centered by `CenterContainer`, so resize/fullscreen cannot displace it;
- title `RATE / <SKETCH>`;
- six score rows, 1–5;
- explicit close button;
- Escape closes the modal before any Gallery navigation;
- click/touch outside the card closes it;
- score persistence and Gallery `R x.x` badges remain unchanged.

Review state persists in `user://creative_lab_reviews.cfg`.

`creative_preference_snapshot` still publishes the entire current explicit rating state at startup and after edits. Future AI should prefer it over reconstructing fragmented rating events.

Known explicit rating evidence before this revision:

- 020 ECHO TISSUE ~4.17/5 (4,4,4,4,4,5)
- 022 LIESEGANG FRONT ~1.83/5 (1,2,2,1,2,3)
- 025 FARADAY QUASI ~2.17/5 (3,2,2,1,2,3)
- 001 SIGNAL FIELD ~2.33/5 (3,2,2,1,3,3)
- host had 16 reviewed sketches total

Ratings are evidence / bounded probability bias, never a command to clone the highest-rated work.

Trash remains local/reversible and never deletes Git source.

## Telemetry status after latest host feedback

The user reported the RATE visual problem after testing, so telemetry was inspected first.

Remote evidence was **not fresh enough** for that test:

- `telemetry/runtime/latest.jsonl` was empty;
- remote telemetry branch still ended at `dd919466...` / 2026-09-25 07:09:55Z;
- that is older than the review-v2 code/head the user was testing.

Therefore the modal visual criticism comes directly from explicit host feedback, not from falsely attributed telemetry evidence.

After the next host test, inspect telemetry first again and verify the branch advances to the tested HEAD/session. New telemetry events include `review_modal_changed` and `workstation_startup_fullscreen`.

## Temporal-quality rule — important

User explicitly rejected obvious cheap temporal loops / sine-like breathing/bobbing. Treat this as a durable creative constraint.

Read `knowledge/cross-domain/TEMPORAL_MOTION_QUALITY.md`.

Preferred:

`time -> state/force/memory/event -> coupling -> render`

Rejected by default:

`time -> sin/cos -> visible position/scale/alpha/warp`

Periodic forcing is allowed only when it is truly the mechanism. For index 026+, direct `sketch_time` / `u_time` / shader `TIME` trigonometry requires nearby `TEMPORAL_INTENT:` justification.

`scripts/ci/audit_temporal_motion.py` found 38 historical observations in <=025. Some fixed-interval warnings are legitimate simulation/event cadence; do not blindly replace all with noise.

Current targeted temporal refactors remain:

- 021 ROSENSWEIG FIELD: variable target/dwell + hysteretic state, no Lissajous/orbit clock choreography.
- 022 LIESEGANG FRONT: reagent exhaustion/rest/recharge, no visible giant-front snap reset.
- 024 GRANULAR JAM: stress/velocity/confinement/material-driven creep + event-indexed avalanche variation.
- 025 FARADAY QUASI: valid physical forcing retained, stateful chirp, decorative clock touch ripple removed.

## Adaptive creative draw — important

Read:

- `knowledge/cross-domain/ADAPTIVE_CREATIVE_DRAW.md`
- `knowledge/cross-domain/creative_draw_space.json`
- `scripts/creative/draw_recipe.py`

Future exploration should start from this diversity-aware draw engine. It selects carrier, two representation families, two operator families, temporal model, interaction consequence, design constraint and render path.

Historical/recent reuse is penalized. Explicit REVIEW ratings can gently bias features, but 24% of draws deliberately ignore preference bias and remain exploration-first.

For index 026+, `definition.json` requires non-empty `creative_signature`. Record only implemented/kept signatures.

CI self-tests 180 deterministic draws; first validated result was 180 unique / 180.

## Full-canvas render rule

A scene node named `ShaderSurface` must use `res://sketches/_shared/full_canvas_surface.gd`. CI rejects legacy fixed 1280×720 surfaces. Host emits `sketch_surface_contract` telemetry.

## Historical creative constraints

- 001 is technical foundation/reference.
- 005 internal id remains `005_pressure_lattice`, visible artwork remains **REGISTER TYPE**; never restore Pressure Lattice.
- generalized glyph-contour pass `6c20a094...` across 006–010 was host-rejected; do not restore as default representation.
- 011–015 established collision-first diversity but were visually weak/under-parameterized.
- 016–020 improved organic coupling; 017/020 have dense-field ImageTexture performance refactors.
- 021–025 are physical/chemical mechanism labs.

## Next host validation

1. Launch app and verify workstation opens directly in native fullscreen with all app chrome visible.
2. Use the custom restore/maximize control once; confirm a normal window can still be restored and fullscreen/expanded behavior remains coherent.
3. Open a sketch and press RATE.
4. Verify backdrop is dark, card is fully opaque and **exactly centered** at startup fullscreen size.
5. Resize/restore then reopen RATE; card must remain centered.
6. Change/clear scores, close via ×, Escape and outside click/touch; verify persistence + Gallery `R x.x`.
7. F11 an active sketch, exit with Esc, and verify workstation returns to its previous fullscreen state.
8. Close normally so telemetry can publish; next AI inspects `creative_preference_snapshot`, `review_modal_changed`, `workstation_startup_fullscreen` and tested HEAD/session first.
9. Continue temporal visual checks on 021/022/024/025 as previously documented.

## PROGRAM / LIVE OUT architecture

Navigation is not transport. PROGRAM continues across Gallery/Settings/other PREVIEW. `TAKE LIVE` replaces it. Linked output follows source state; detached PROGRAM continues autonomously. Physical PROGRAM touch/mouse remains supported.

## Mandatory completion protocol

After every material repository change:

1. finish feature-branch commits;
2. update CURRENT_WORK/HANDOFF/project_state/NEXT_AI_PROMPT and OPERATIONS when relevant;
3. resolve final remote HEAD after docs;
4. wait for exact-head CI;
5. report exact short SHA + CI;
6. automatically include canonical PowerShell from OPERATIONS when host validation is useful;
7. telemetry-first after test.

## Rejected regressions

Do not stop PROGRAM on navigation, create independent linked timelines, use synchronous telemetry Git work, resurrect failed cross-window texture sampling, fake Spout/NDI, restore Pressure Lattice, burn project metadata into artwork, make glyph contours the default representation, restore a permanent all-tags wall, restore fixed 1280×720 ShaderSurface nodes, restore the transparent/off-center native RATE popup, or use naked global-clock sine/cosine wobble as a generic substitute for behavior.
