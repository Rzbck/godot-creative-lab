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

PROGRAM canvas is artwork-only. Logical design coordinates are normally 1280×720, but render surfaces adapt to actual viewport.

Gallery currently contains **30 source sketches** (001–030).

## Current top runtime

`res://app/main/main_runtime_window_memory.gd`

Chain starts:

```text
main_runtime_window_memory.gd
    -> main_runtime_gallery_compact_review.gd
        -> main_runtime_gallery_feedback_trash.gd
            -> main_runtime_gallery_adaptive_filters.gd
                -> main_runtime_gallery_organizer.gd
                    -> main_runtime_program_output.gd
                        -> ...
```

Always inspect actual code before editing the chain.

## Workstation window memory — important

Host telemetry on runtime `9fa6d889...` proved the previous startup visibly showed a 1280×720 window first, then switched to fullscreen about 730 ms later.

That behavior is rejected.

New `main_runtime_window_memory.gd` persists state to:

`user://creative_lab_window_state.cfg`

Persisted fields:

- windowed / maximized / fullscreen mode;
- physical screen;
- native position/size;
- restore rect used by custom window controls.

Startup hides the root native Window in `_enter_tree()`, restores saved state before the regular `_ready()` UI chain, waits for layout settle, then reveals the app. First run defaults to fullscreen. F11 render presentation is separate and must never overwrite saved workstation window state.

Telemetry event: `workstation_window_state_restored`.

Status: **IMPLEMENTED_NOT_HOST_VALIDATED**. Do not claim the startup flash is solved until Windows host validation confirms it.

## REVIEW UI / curation

Permanent parameter sidebar remains:

`REVIEW <avg>/5  RATE  TRASH`

The old native transparent/off-center RATE `PopupPanel` is rejected. Revision 3 uses an in-app centered opaque modal with backdrop, close button, Escape and outside click/touch dismissal.

Reviews persist in `user://creative_lab_reviews.cfg`; rated cards show `R x.x`. Prefer consolidated telemetry event `creative_preference_snapshot` over reconstructing rating clicks.

Trash remains local/reversible and never deletes Git source.

## Current explicit preference evidence

Fresh telemetry session `session_5e0960d4c3e0c6a7.jsonl` contained **16 reviewed sketches**.

Axis averages:

- visual 2.25
- interaction 2.125
- originality 2.125
- aliveness 1.8125
- controls 2.0
- performance 3.0625

Strong complete vectors:

- 020 ECHO TISSUE: 4,4,4,4,4,5 — avg ~4.17.
- 012 CHEMICAL BLOCKS: 4,3,4,3,3,3 — avg ~3.33.
- 017 EDGE BLOOM: 3,3,3,3,2,3 — avg ~2.83.

Weak examples:

- 014 RIBBON MORPH: all 1 — avg 1.0.
- 016 PREDATOR VEIN: 1,1,1,2,1,3 — avg 1.5.
- 024 GRANULAR JAM: 1,2,1,1,2,3 — avg ~1.67.
- 022 LIESEGANG FRONT: 1,2,2,1,2,3 — avg ~1.83.

Interpretation: aliveness/controls are still the weakest axes. Favor real propagation, neighbour coupling, state memory and interaction that changes future evolution, but do not clone 020. Ratings are bounded probability evidence; 24% of adaptive draws remain preference-free.

## Adaptive batch 026–030

All five use machine-readable `creative_seed` + `creative_signature`; actual implemented signatures are now recorded in `knowledge/cross-domain/creative_draw_space.json`.

- **026 VOID TENSION** — constraint network + Voronoi territory field; stress propagation, fracture, repair/scars; touch cuts links; 8 params.
- **027 GLASS TIDE** — stateful SDF glass lenses + asynchronous wave fronts; touch splits/rejoins local topology; fullscreen shader without clock choreography; 8 params.
- **028 LUMEN MAZE** — light transported through deterministic graph channels; jams accumulate pressure and release bursts; touch places remembered obstacles; 9 params.
- **029 FIBER FELT** — constrained fiber field coupled to a local compaction mask; pressure drives loose→felted phase transition and memory; 8 params.
- **030 REACTOR SKIN** — reaction-diffusion drives a coarse deforming/fracturing membrane stress graph; touch injects chemistry + structural stress; 9 params.

These were selected from the adaptive draw engine using explicit ratings as bounded bias, then mutated only when necessary to preserve the mechanism in a suitable Godot representation.

## Temporal-quality rule

User explicitly rejects obvious cheap temporal loops / sine-like breathing/bobbing.

Read `knowledge/cross-domain/TEMPORAL_MOTION_QUALITY.md`.

Preferred:

`time -> state/force/memory/event -> coupling -> render`

Rejected by default:

`time -> sin/cos -> visible position/scale/alpha/warp`

For index 026+, direct clock trig requires `TEMPORAL_INTENT:`. Current 026–030 do not rely on generic direct-clock trigonometry.

Historical targeted refactors remain 021/022/024/025 as documented in CURRENT_WORK.

## Adaptive creative draw — important

Read:

- `knowledge/cross-domain/ADAPTIVE_CREATIVE_DRAW.md`
- `knowledge/cross-domain/creative_draw_space.json`
- `scripts/creative/draw_recipe.py`

Draw engine selects carrier, two representation families, two operator families, temporal model, interaction consequence, design constraint and render path. Historical/recent reuse is penalized. Explicit REVIEW ratings can gently bias features, but 24% of draws deliberately ignore preference bias.

For 026+, `definition.json` requires non-empty `creative_signature`. Record only implemented/kept signatures.

CI self-tests 180 deterministic draws for diversity collapse.

## Full-canvas / performance rules

A node named `ShaderSurface` must use `res://sketches/_shared/full_canvas_surface.gd`. CI rejects fixed 1280×720 surfaces.

Dense fields should use ImageTexture/fullscreen shader rather than thousands of Canvas primitives. Avoid duplicate expensive neighbourhood/contact computation in `_draw()`.

## Historical creative constraints

- 001 is technical foundation/reference.
- 005 internal id remains `005_pressure_lattice`, visible artwork remains **REGISTER TYPE**; never restore Pressure Lattice.
- generalized glyph-contour pass `6c20a094...` across 006–010 was host-rejected; never restore as default representation.
- 011–015 established collision-first diversity but were visually weak/under-parameterized.
- 016–020 improved organic coupling; 017/020 have dense-field ImageTexture performance refactors.
- 021–025 are physical/chemical mechanism labs.
- 026–030 are the first batch driven from the consolidated explicit rating profile + adaptive diversity engine.

## Next host validation

1. Launch app: it must not visibly show small window then grow; it should appear directly in saved state.
2. Close/reopen while fullscreen, maximized, and moved/resized windowed; verify mode/screen/rect persistence.
3. RATE modal remains centered/opaque.
4. Confirm Gallery has 30 cards.
5. Watch 026–030 idle 20–30 s before touching, then interact and remove hand; judge persistent consequences.
6. Rate 026–030 on all six axes.
7. Close normally; next AI inspects matching `telemetry/runtime` first, especially `workstation_window_state_restored` and updated `creative_preference_snapshot`.

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

Do not stop PROGRAM on navigation, create independent linked timelines, use synchronous telemetry Git work, resurrect failed cross-window texture sampling, fake Spout/NDI, restore Pressure Lattice, burn project metadata into artwork, make glyph contours the default representation, restore a permanent all-tags wall, restore fixed 1280×720 ShaderSurface nodes, restore the transparent/off-center native RATE popup, use naked global-clock sine/cosine wobble as generic behavior, or restore the visible small-window -> fullscreen startup jump.
