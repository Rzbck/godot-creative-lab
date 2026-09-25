# HANDOFF — DataC0re Creative Lab

Canonical restart point for a new human or AI session.

**Always resolve the current remote branch HEAD and exact-head CI before trusting recorded SHAs. Repository state + matching runtime telemetry beat chat history.**

Last material refresh: **2026-09-25**.

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

## Gallery / review / curation

Adaptive filter contract remains:

- `ALL` always visible;
- max six generated useful quick tags;
- universal tags omitted;
- rare/rest tags in collapsed `MORE`;
- search indexes every tag;
- first `definition.json` tag remains primary group.

Review UI is now compact. Permanent parameter sidebar contains one row:

`REVIEW <avg>/5  RATE  TRASH`

`RATE` opens the six axes (visual, interaction, originality, aliveness, controls, performance). Scores persist in `user://creative_lab_reviews.cfg`; cards retain `R x.x` badges.

`creative_preference_snapshot` now publishes the **entire current explicit rating state** at startup and after edits. Future AI should read this snapshot before reconstructing fragmented rating clicks.

Known explicit host evidence before this revision:

- 020 ECHO TISSUE ~4.17/5 (4,4,4,4,4,5) — strongest known complete vector;
- 022 LIESEGANG FRONT ~1.83/5 (1,2,2,1,2,3);
- 025 FARADAY QUASI ~2.17/5 (3,2,2,1,2,3);
- 001 SIGNAL FIELD ~2.33/5 (3,2,2,1,3,3);
- host had 16 reviewed sketches total.

Do not convert this into a ranking/clone system. Use per-axis evidence as a bounded probability signal.

Trash stays local/reversible: 7/14/30-day retention, RESTORE, local PURGE/retirement. It never deletes Git source.

## Temporal-quality rule — important

User explicitly rejected obvious cheap temporal loops / sine-like breathing/bobbing. Treat this as a durable creative constraint.

Read:

`knowledge/cross-domain/TEMPORAL_MOTION_QUALITY.md`

Core distinction:

`time -> state/force/memory/event -> coupling -> render` is preferred.

`time -> sin/cos -> visible position/scale/alpha/warp` is rejected by default.

Periodic forcing is allowed when it is truly the mechanism. For index 026+, direct `sketch_time` / `u_time` / shader `TIME` trigonometry requires a nearby `TEMPORAL_INTENT:` explanation.

`scripts/ci/audit_temporal_motion.py` currently reports historical findings as warnings. The first full audit found 38 observations across <=025. Some are legitimate fixed simulation cadences, so do not treat every warning as a defect.

Targeted current-batch changes:

- 021: no Lissajous/orbiting auto magnet or shader clock wobble; variable target/dwell + hysteretic state.
- 022: no visible front snap-reset; reagent exhaustion/rest/recharge generations.
- 024: no sinusoidal global-time creep; material-state creep + avalanche event-index randomness.
- 025: physical periodic forcing retained intentionally; chirp target is stateful/variable; decorative clock touch ripple removed.
- 023 was already primarily state-driven.

Historical direct-clock observations remain a measured backlog; prioritize with ratings/identity instead of blindly replacing all motion with noise.

## Adaptive creative draw — important

Read:

- `knowledge/cross-domain/ADAPTIVE_CREATIVE_DRAW.md`
- `knowledge/cross-domain/creative_draw_space.json`
- `scripts/creative/draw_recipe.py`

Future work should start from the draw engine when exploring new sketch technology. It selects carrier, two distant representation families, two distant operator families, temporal model, interaction consequence, design constraint and render path.

Anti-repetition weighting penalizes historical/recent reuse and requires meaningful distance from recent signatures.

Explicit REVIEW ratings may gently bias recorded features (~bounded ±24%), but **24% exploration share ignores preference bias**. This preserves discovery instead of converging into a single house style.

For index 026+, `definition.json` must include non-empty `creative_signature`. Record the signature only for implemented/kept work.

CI runs a deterministic 180-draw self-test. First validated result: 180 unique / 180.

## Full-canvas render rule

A scene node named `ShaderSurface` must use `res://sketches/_shared/full_canvas_surface.gd`. CI rejects legacy fixed 1280×720 surfaces. Host emits `sketch_surface_contract` coverage telemetry.

This was added after 025 received a correct 1520×852 PREVIEW but its old fixed ColorRect exposed gray space.

## Historical creative constraints

- 001 is technical foundation/reference.
- 005 internal id remains `005_pressure_lattice`, visible artwork remains **REGISTER TYPE**; never restore rejected Pressure Lattice.
- generalized glyph-contour pass `6c20a094...` across 006–010 was host-rejected; do not restore it as default representation.
- 011–015 established collision-first diversity but were visually weak/under-parameterized.
- 016–020 improved organic coupling; 017/020 have dense-field ImageTexture performance refactors.
- 021–025 are physical/chemical mechanism labs.

## Knowledge priority

For current/new creative work read:

1. `TEMPORAL_MOTION_QUALITY.md`
2. `ADAPTIVE_CREATIVE_DRAW.md`
3. `creative_draw_space.json`
4. `TECHNIQUE_PALETTE.md`
5. `RANDOM_COLLISION_ENGINE.md`
6. `COLLISION_SOURCE_CATALOG.md`
7. `PHYSICAL_CHEMICAL_SYSTEMS_ATLAS.md`
8. `ORGANIC_COUPLING_AND_CONTROLS.md`
9. `REALTIME_PERFORMANCE_BUDGET.md`
10. relevant design/creative-coding atlases and IDEA_ENGINE/CROSS_DOMAIN_ATLAS.

## Next host validation

1. Confirm sidebar REVIEW is compact; RATE popup opens without consuming permanent parameter height.
2. Edit/clear scores, reopen and verify persistence + Gallery badge.
3. Allow normal telemetry publication; next AI reads `creative_preference_snapshot` first.
4. Watch 021 ~60s idle: no obvious analytic orbit/Lissajous loop.
5. Watch 022 through exhaustion/recharge: no visible front snap reset.
6. Watch 024 under load/release: creep/avalanche feels stress/event-driven, not harmonic.
7. Watch 025: standing-wave periodicity is valid, but decorative traveling touch ripple/metronomic chirp is gone.
8. Close normally and inspect fresh matching `telemetry/runtime` before asking for logs.

## PROGRAM / LIVE OUT architecture

Navigation is not transport. PROGRAM continues across Gallery/Settings/other PREVIEW. `TAKE LIVE` replaces it. Linked output follows source state; detached PROGRAM continues autonomously. Physical PROGRAM touch/mouse remains supported.

## Telemetry-first debugging

After every host runtime test:

1. inspect `telemetry/runtime`;
2. read `latest.jsonl` + relevant session;
3. verify tested HEAD/session;
4. prefer consolidated rating snapshot and runtime events over manual reconstruction;
5. ask for logs/screenshots only when telemetry lacks evidence.

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

Do not stop PROGRAM on navigation, create independent linked timelines, use synchronous telemetry Git work, resurrect failed cross-window texture sampling, fake Spout/NDI, restore Pressure Lattice, burn project metadata into artwork, make glyph contours the default representation, restore a permanent all-tags wall, restore fixed 1280×720 ShaderSurface nodes, or use naked global-clock sine/cosine wobble as a generic substitute for behavior.
