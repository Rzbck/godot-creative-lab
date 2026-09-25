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
- logical artwork coordinate system usually `1280×720`, but render surfaces must adapt to actual viewport.
- PROGRAM is artwork-only: no title/index/tag/debug chrome unless artistically intentional.

## Host finding — fixed-size shader surfaces

On host test of **025 FARADAY QUASI**, maximized workstation PREVIEW showed the shader only in a 1280×720 region with gray host space to the right/bottom.

Telemetry for that exact session matched runtime head `03917e676fce...` and showed:

- workstation root: 1920×1080;
- project PREVIEW container: 1520×852;
- sketch `SubViewport`: 1520×852;
- viewport texture: 1520×852.

Therefore host sizing was correct. The defect was inside the sketch scene: `ShaderSurface` was a fixed 1280×720 `ColorRect`.

### Durable correction

Added:

`sketches/_shared/full_canvas_surface.gd`

A node named `ShaderSurface` is now a semantic full-canvas surface. It follows the actual `SubViewport` in thumbnail, resized/maximized PREVIEW, F11 and PROGRAM.

Converted existing named full-canvas surfaces in:

- 005 REGISTER TYPE;
- 021 ROSENSWEIG FIELD;
- 025 FARADAY QUASI.

The host also sizes named `ShaderSurface` nodes as a runtime fallback and emits `sketch_surface_contract` telemetry with viewport/surface coverage.

### CI guard

`scripts/ci/validate_repository.py` now fails if a runtime `.tscn` contains `ShaderSurface` but:

- does not reference `res://sketches/_shared/full_canvas_surface.gd`;
- contains legacy fixed `offset_right = 1280`;
- contains legacy fixed `offset_bottom = 720`;
- has no script assignment on the `ShaderSurface` block.

This is a hard non-regression rule. Do not reintroduce fixed-size shader surfaces.

## User creative review system

New top runtime layer:

`app/main/main_runtime_gallery_feedback_trash.gd`

It extends the adaptive-filter layer.

Every opened sketch now receives a `REVIEW` block in the workstation inspector, after its creative parameters.

Current 1–5 axes:

1. `VISUAL`
2. `INTERACTION`
3. `ORIGINALITY`
4. `ALIVENESS`
5. `CONTROLS`
6. `PERFORMANCE`

Behavior:

- scores persist in `user://creative_lab_reviews.cfg`;
- pressing the selected score again clears that criterion;
- active inspector shows aggregate average and rated-axis count;
- rated Gallery cards show compact `R x.x` badge;
- changes emit `sketch_review_changed` telemetry with numeric ratings + average.

Future AI sessions should inspect these explicit user ratings as first-class evidence when deciding what creative traits to repeat, improve, mutate or avoid. Do not infer ratings from unrelated conversation if the structured host data exists.

## Local Trash / deletion workflow

`MOVE TO TRASH` is available from each open sketch.

Local curation persists in:

`user://creative_lab_curation.cfg`

Behavior:

- moving to Trash immediately hides the sketch from normal Gallery catalogue;
- when non-empty, Gallery shows `TRASH n`;
- Trash drawer supports `RESTORE`;
- retention choices: 7 / 14 / 30 days, default 30;
- expired Trash entries become locally `retired`;
- `PURGE` retires locally immediately.

Safety boundary: the workstation never deletes version-controlled `res://sketches/...` source files. Local purge means “permanently removed from this workstation Gallery”, while actual source deletion remains an explicit Git operation. This keeps accidental deletion recoverable from repo history and works in read-only/exported builds.

Telemetry events include `sketch_trashed`, `sketch_restored`, `sketch_purged`, drawer state and retention changes.

## Gallery adaptive filters

The permanent tag wall is rejected.

Current contract:

- `ALL` always visible;
- at most six useful generated quick tags;
- universal tags omitted;
- remaining tags in collapsed `MORE`;
- selected rare tag promoted while active;
- search indexes all tags;
- first definition tag remains automatic primary group.

## Current creative body

Gallery source catalogue currently contains 25 sketches.

Historical constraints:

- 005 internal id remains `005_pressure_lattice` but visible artwork is REGISTER TYPE; never restore Pressure Lattice.
- generalized glyph-contour pass `6c20a094...` was host-rejected and must not become the default representation.
- 011–015 established collision-first diversity but were visually weak/under-parameterized.
- 016–020 improved organic coupling and expose 8–9 controls.
- 021–025 add physical/chemical causal mechanisms: Rosensweig, Liesegang, spinodal/Marangoni, granular jamming and Faraday resonance.

017 and 020 already received dense-field performance refactors to low-resolution `ImageTexture` rendering; 020 also caches neighbour density rather than rescanning in `_draw()`.

## Knowledge priority

For current creative work read:

1. `knowledge/cross-domain/TECHNIQUE_PALETTE.md`
2. `knowledge/cross-domain/RANDOM_COLLISION_ENGINE.md`
3. `knowledge/cross-domain/COLLISION_SOURCE_CATALOG.md`
4. `knowledge/cross-domain/PHYSICAL_CHEMICAL_SYSTEMS_ATLAS.md`
5. `knowledge/cross-domain/ORGANIC_COUPLING_AND_CONTROLS.md`
6. `knowledge/cross-domain/REALTIME_PERFORMANCE_BUDGET.md`
7. relevant design/creative-coding atlases
8. `CROSS_DOMAIN_ATLAS.md` / `IDEA_ENGINE.md` for art-direction promotion.

## Validation status

Runtime/code implementation commits:

- `6471a875...` — full-canvas contract + review/trash layer;
- `e8c1a826...` — fix GDScript constant parse issue.

CI #256 passed on exact code head `e8c1a826...`:

- Repository policy: success;
- Godot 4.7.1 import: success;
- main-scene smoke: success;
- tracked-file cleanliness: success.

Always resolve a new exact-head CI after the documentation commits in this session.

## Required next host test

1. Gallery source count should still be 25 before local trash actions.
2. Open 025 in the same maximized workstation layout that previously failed: artwork must cover the full 1520×852 PREVIEW, with no gray right/bottom gap.
3. Resize the workstation and test 025, 021 and 005; full-canvas shader surfaces must continue to cover PREVIEW.
4. Press F11 on a shader sketch and confirm the render remains full-canvas.
5. Rate at least one sketch across several REVIEW criteria; return to Gallery and confirm `R x.x`; reopen and confirm scores persist.
6. Move one disposable/noncritical sketch to Trash; confirm Gallery hides it and `TRASH 1` appears.
7. Restore it and confirm it returns.
8. Optionally test retention selector; do not source-delete anything from Git as part of this UI test.
9. Continue 021–025 artistic/performance evaluation.
10. Close normally so telemetry publishes.
11. On next response inspect fresh `telemetry/runtime` first; verify matching tested HEAD/session and inspect `sketch_surface_contract`, rating and trash events before requesting manual logs.

## Evaluation axes going forward

- **mechanism** — state coupling/emergence;
- **art direction** — default beauty/composition;
- **interaction** — meaningful influence and delayed consequence;
- **controls** — depth and distinct regimes;
- **performance architecture** — representation appropriate for realtime;
- **catalogue UX** — scalable discovery/curation;
- **explicit host preference** — structured REVIEW scores.

## Mandatory AI completion

After every material repository change: finish commits, update durable docs/state, resolve final remote HEAD, wait exact-head CI, report exact short SHA + CI, provide canonical CI-waiting PowerShell when host test is relevant, then telemetry-first after user test.

## Non-regressions

Do not stop PROGRAM on navigation, create independent linked timelines, block UI with telemetry Git work, resurrect failed cross-window texture sampling, fake Spout/NDI, restore Pressure Lattice, burn project metadata into artwork, make glyph contours the default representation, restore a permanent all-tags wall, or reintroduce fixed 1280×720 `ShaderSurface` nodes.
