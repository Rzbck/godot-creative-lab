# HANDOFF — DataC0re Creative Lab

Canonical restart point for a new human or AI session.

**Always resolve the current remote branch HEAD and exact-head CI before trusting recorded SHAs. Repository state is authoritative; chat history is secondary.**

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

## Product state

DC//LAB is a Godot creative-coding workstation with data-driven Gallery discovery, real thumbnails/hover previews, generated parameter inspector and persistence, PREVIEW / PROGRAM separation, persistent PROGRAM during navigation, TAKE LIVE, physical display output, PROGRAM input forwarding, linked live-state synchronization, async telemetry, user reviews/curation, and versioned creative research.

PROGRAM canvas is artwork-only: no index/title/tag/debug/project metadata unless intentionally part of the art.

## Current top runtime / chain

Entry scene:

`res://app/main/main_runtime.tscn`

Top runtime script:

`res://app/main/main_runtime_gallery_feedback_trash.gd`

Chain begins:

```text
main_runtime_gallery_feedback_trash.gd
    -> main_runtime_gallery_adaptive_filters.gd
        -> main_runtime_gallery_organizer.gd
            -> main_runtime_program_output.gd
                -> main_runtime_gallery_persistence.gd
                    -> main_runtime_live_output.gd
                    -> ...
```

Inspect actual Git chain before changing host architecture.

## Hard render-surface rule

Host test of 025 FARADAY QUASI on runtime `03917e676fce...` showed gray right/bottom space in maximized PREVIEW. Fresh telemetry proved the host and SubViewport were correctly **1520×852**; the sketch's `ShaderSurface` itself was fixed to 1280×720.

The fix is now architectural:

- shared component: `res://sketches/_shared/full_canvas_surface.gd`;
- any node named `ShaderSurface` must use that component and follow actual viewport size;
- converted 005, 021 and 025 existing shader surfaces;
- host has a runtime sizing fallback for named `ShaderSurface` controls;
- opening a sketch emits `sketch_surface_contract` telemetry with viewport size / coverage / pass;
- repository CI rejects `ShaderSurface` scenes that lack the shared component or restore fixed 1280×720 offsets.

Never reintroduce a fixed 1280×720 `ShaderSurface`. Logical design coordinates may remain 1280×720, but the physical render surface must cover the actual PREVIEW/PROGRAM viewport.

See `docs/SKETCH_CONTRACT.md`.

## Gallery discovery

Adaptive tag rail contract:

- `ALL` always visible;
- max 6 generated quick tags;
- universal tags hidden from filter UI;
- rare/rest tags inside collapsed `MORE`;
- selected rare tag promoted while active;
- search indexes every tag;
- primary group remains first `definition.json` tag;
- do not restore a permanent all-tags wall.

## User REVIEW system

Every open sketch gets a workstation-side `REVIEW` block after creative parameters.

1–5 axes:

- `VISUAL`
- `INTERACTION`
- `ORIGINALITY`
- `ALIVENESS`
- `CONTROLS`
- `PERFORMANCE`

Persistence:

`user://creative_lab_reviews.cfg`

Behavior:

- same selected score clicked again clears it;
- inspector shows aggregate average;
- rated Gallery cards show `R x.x`;
- `sketch_review_changed` telemetry publishes sanitized numeric ratings + average.

Future AI sessions must use these explicit ratings as first-class creative preference evidence when available. They are meant to gradually sharpen what DC//LAB creates and what existing sketches deserve refinement.

## Local Trash / retirement

Open-sketch inspector provides `MOVE TO TRASH`.

Persistence:

`user://creative_lab_curation.cfg`

Behavior:

- trashed sketch disappears from normal Gallery immediately;
- `TRASH n` appears only when non-empty;
- Trash drawer offers `RESTORE`;
- retention choices 7 / 14 / 30 days, default 30;
- expiration moves entry to local `retired` state;
- `PURGE` retires locally immediately.

Safety rule: runtime Trash/Purge **never deletes version-controlled `res://sketches/...` source files**. True source deletion is an explicit Git operation. Do not silently resurrect locally retired work during normal Gallery loads; local curation is intentional user state.

## Current creative body

Gallery source catalogue: 25 sketches.

Important history:

- 005 internal id/path stays `005_pressure_lattice`, visible work is REGISTER TYPE; original Pressure Lattice rejected.
- generalized glyph-contour pass `6c20a094...` across 006–010 rejected; do not restore as default representation.
- 011–015 collision-first increased technical diversity but were visually weak / only 3 controls.
- 016–020 added stronger organic coupling and 8–9 controls.
- 021–025 add physical/chemical causal mechanisms: Rosensweig, Liesegang, spinodal/Marangoni, granular jamming, Faraday resonance.

017/020 dense-field rendering was optimized to low-resolution ImageTexture; 020 also caches neighbour density.

## Creative research rules

Read first:

- `knowledge/cross-domain/TECHNIQUE_PALETTE.md`
- `knowledge/cross-domain/RANDOM_COLLISION_ENGINE.md`
- `knowledge/cross-domain/COLLISION_SOURCE_CATALOG.md`
- `knowledge/cross-domain/PHYSICAL_CHEMICAL_SYSTEMS_ATLAS.md`
- `knowledge/cross-domain/ORGANIC_COUPLING_AND_CONTROLS.md`
- `knowledge/cross-domain/REALTIME_PERFORMANCE_BUDGET.md`
- relevant design/creative-coding atlases.

Current method often uses:

`technical/phenomenon collision -> coupled prototype -> observe -> interpret -> art-direct -> mutate`

No technique is the default house style. Real-world references preserve causal relationships, not just surface aesthetics. Substantial labs normally expose 6–9 distinct controls when the mechanism supports it.

## Current validation

Runtime/feature commits:

- `6471a875...` — full-canvas contract + review/trash layer;
- CI #255 caught one invalid constant expression before host test;
- `e8c1a826...` fixed it;
- CI #256 passed policy, Godot 4.7.1 import, main-scene smoke and tracked-file cleanliness on that exact code head.

Resolve a new final exact-head CI after all documentation commits before declaring the task complete.

## Next host validation

1. Open 025 in the same maximized workstation layout: no gray right/bottom gap; artwork covers the full 1520×852 PREVIEW.
2. Resize/maximize and test 025, 021 and 005.
3. Test F11 presentation on a shader sketch.
4. Rate one or more sketches across several REVIEW axes; confirm `R x.x` in Gallery and persistence after reopen/relaunch.
5. Move a disposable sketch to Trash, confirm it disappears and `TRASH 1` appears; restore it.
6. Optionally change retention; do not source-delete via this UI test.
7. Continue artistic/performance test of 021–025.
8. Close normally.
9. Immediately inspect `telemetry/runtime`; verify tested HEAD/session, `sketch_surface_contract`, review and trash events before asking for logs.

## PROGRAM / LIVE OUT invariants

- navigation never stops PROGRAM;
- TAKE LIVE replaces PROGRAM;
- linked PREVIEW/PROGRAM share one generative state;
- detached PROGRAM continues from last synchronized state;
- physical output remains interactive;
- workstation stays usable.

## Mandatory AI completion protocol

After every material repo change, before final response:

1. finish intended feature-branch commits;
2. update `CURRENT_WORK.md`, this handoff, `project_state.json`, `NEXT_AI_PROMPT.md`, and `OPERATIONS.md` where durable state/workflow changed;
3. resolve final remote branch HEAD after all code/docs commits;
4. wait for and inspect CI for that exact SHA;
5. report exact short HEAD + CI;
6. if host validation is useful, automatically include canonical PowerShell from `OPERATIONS.md`;
7. after host test, telemetry-first.

## Rejected regressions

Do not restore root-window fullscreen as PROGRAM architecture, failed cross-window texture sampling, synchronous telemetry network work, independent linked simulations, card-covering overlays, permanent all-tags walls, fixed 1280×720 shader surfaces, fake Spout/NDI, Pressure Lattice, project metadata inside artwork, or glyph contours as a default technique.
