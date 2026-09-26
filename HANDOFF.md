# HANDOFF — DataC0re Creative Lab

Canonical restart point. Resolve the real remote branch HEAD and the CI for that exact SHA before trusting any recorded commit. Repository state plus matching host telemetry are authoritative when chat history disagrees.

Last material refresh: 2026-09-26.

## Repository

- GitHub: `Rzbck/godot-creative-lab`
- branch: `feat/creative-sketches-002-004-20260924`
- draft PR: #7, base `feat/gallery-project-workflow-20260923`
- Godot: 4.7.1 stable
- workstation root: `E:\_Project\GodotCreativeLab`
- GUI: `C:\Godot\Godot_v4.7.1-stable_win64.exe`
- never merge/change `main` without explicit user approval

## Stable product contract

PROGRAM persists while the workstation navigates Gallery/Settings/other PREVIEW. `TAKE LIVE` explicitly replaces PROGRAM. Physical PROGRAM touch/mouse is supported. Linked PREVIEW/PROGRAM share one state/timeline. Per-sketch parameters persist. Gallery uses real sketch thumbnails and only hovered previews animate. PROGRAM is artwork-only. Telemetry/network work stays asynchronous. Local Trash never deletes Git source.

Main scene: `res://app/main/main_runtime.tscn`.
Top runtime: `res://app/main/main_runtime_gallery_host_fixes.gd`.
Source catalogue: **001–045** before local curation.

## Latest host feedback — current priority

Host test on HEAD `a55c65c6...` produced four concrete findings:

1. **LIST revision 1 was rejected**: 132 px rows with a 260 px image at left were too large. User wants a real compact file-list row, with the live preview used as decorative background over part of the row.
2. User wants **PREVIOUS / NEXT sketch navigation directly in ProjectView**, avoiding ESC -> Gallery -> click for sequential review.
3. User entered many **written RATE reviews** and expects future AI sessions to use those automatically for repairs and future creative direction without asking them to repeat comments in chat.
4. **041 TENSION ORGAN** spammed `Invalid polygon data, triangulation failed` from `_draw()` because deformed four-point membrane cells can become concave/inverted/degenerate.

## Implemented host patch

Implementation sequence:

- `21d31984...` — Gallery host layer revision 2:
  - LIST height restored to **68 px**;
  - real SubViewport preview is a low-alpha backdrop on the right portion of each row;
  - compact index/title/engine/tags overlay stays readable;
  - `‹ PREV` / `NEXT ›` buttons are added to ProjectToolbar;
  - adjacency follows numeric source order of currently browsable/non-trashed sketches;
  - navigation uses normal `_open_sketch()` path, so PROGRAM persistence is preserved;
  - startup schedules a review checkpoint so existing local notes can be republished after sanitizer upgrades.
- `df9710ae...` — 041 rendering safety:
  - no four-point `draw_colored_polygon()` for deforming cells;
  - each cell is rendered as two explicit triangles;
  - shorter diagonal is chosen and near-zero-area triangles are skipped;
  - physical spring simulation is unchanged.
- `0c360c35...` — telemetry written-review transport:
  - diagnostic sanitizer explicitly permits `note` free text only;
  - max 2000 chars, C0 controls removed;
  - safe creative identifiers (`sketch_id`, title, tags, creative-signature fields, criteria, reason) are preserved;
  - publisher refuses a zero-byte sanitized file.

Code HEAD `0c360c35...` passed **CI #312 completely** before documentation: repository policy, temporal audit, adaptive draw self-test, Godot 4.7.1 import, main-scene smoke, tracked cleanliness.

## Written reviews are first-class evidence

This is now a durable workflow rule, not a chat convention.

After every meaningful host test, future AI must:

1. inspect `telemetry/runtime` first;
2. read the latest `creative_preference_snapshot`;
3. consume **both numeric axes and written `note` fields** before repairing existing sketches or generating the next batch;
4. use notes as direct evidence about *why* visual/interaction/aliveness/controls scores are low/high;
5. update durable project state when a recurring preference, rejection or quality rule is supported by repeated feedback;
6. never make the user paste the same review into chat when it already exists in telemetry.

Written reviews guide diagnosis/art direction but are not clone instructions. Numeric/qualitative evidence remains bounded; preserve exploration.

### Important telemetry history

The current session `5cb124f1822c2ee4` **did publish non-empty checkpoints**. Earlier connector output that looked empty was misleading; raw `latest.jsonl` was ~160 KB.

Old sanitizer behavior preserved ratings and `note_length`, but stripped the actual `note` string. Therefore the comments entered during that host session are known to exist locally, but their content cannot yet be read remotely from the old publication. Do not invent them.

Because reviews are persisted in `user://creative_lab_reviews.cfg`, host layer revision 2 schedules a startup preference checkpoint. On first launch of the corrected version, the existing notes should be republished through the new sanitizer **without retyping**. Next AI must verify that `creative_preference_snapshot.reviews.<id>.note` is actually present remotely before claiming success.

## Current preference evidence

Latest remotely visible numeric evidence from the current host session includes:

- 036 POLAR STRESS avg ~1.83
- 037 DENDRITE BLOOM avg ~2.33
- 038 ELECTRIC LACE avg ~2.67; visual 4, originality 4 — strongest recent signal, but controls/interaction still weak
- 039 SOAP CONSTELLATION avg ~2.17
- 040 SCHLIEREN VEIL avg 2.0
- 043 SLIT MEMORY avg 1.0
- 044 EXCITABLE GLASS avg 2.0
- 045 RIFT VOLUME avg 1.0

Do not infer 041/042 ratings or any missing text note content until telemetry actually contains them.

## Gallery browser contract

Tags/search remain semantic metadata. Browsing is file-manager-like:

- default flat INDEX ↑;
- INDEX ↓, TITLE A–Z, FAMILY;
- GRID / LIST;
- GRID size slider;
- browser state persists in `user://creative_lab_gallery_view.cfg`;
- sorting/reflow reuses existing cards/SubViewports rather than rebuilding simulations;
- **LIST must remain dense (~68 px) and visual via background preview, never large horizontal cards**;
- TRASH is an exclusive browser mode: normal Gallery cards/search/browser controls hide while Trash is open.

Adaptive quick tags stay bounded; never restore a permanent wall of every tag.

## Project navigation contract

ProjectToolbar now exposes `‹ PREV` and `NEXT ›` for sequential review.

- order is numeric source index, independent of Gallery sort;
- locally removed sketches are skipped because `_catalog` is already curated;
- buttons disable at boundaries, no wrap;
- switching PREVIEW must never stop or silently replace PROGRAM;
- TAKE LIVE semantics remain unchanged.

## 041 rendering contract

Constraint meshes can fold/invert. Do not feed arbitrary deforming quads into polygon triangulation.

For 041, and as a pattern for future dynamic meshes:

- tessellate explicitly into triangles;
- skip degenerate triangles;
- keep simulation topology separate from render triangulation;
- renderer errors are product failures even if the artwork still appears on screen.

## Creative-quality contract

Read:
- `knowledge/cross-domain/VISUAL_FINISH_GATE.md`
- `knowledge/cross-domain/TEMPORAL_MOTION_QUALITY.md`
- `knowledge/cross-domain/ADAPTIVE_CREATIVE_DRAW.md`

Pipeline:

`adaptive draw -> prototype -> observe -> mutate -> art-direct -> visual-finish gate -> keep/reject`

Technical diversity is not artistic quality. Frozen frame, material logic, several useful detail scales, stateful interaction and temporal continuity matter. Hidden coarse solvers may drive dynamics; enlarged solver pixels are not finished art. Avoid generic direct-clock wobble, visible phase wrap/reset and shallow pointer overlays.

## Historical non-regressions

- 001 stays technical foundation/reference.
- 005 source path remains `005_pressure_lattice`, visible artwork **REGISTER TYPE**; never restore Pressure Lattice visual concept.
- generalized glyph-contour treatment across 006–010 was rejected; contours are optional infrastructure, not house style.
- do not stop PROGRAM on navigation.
- do not create independent linked timelines.
- `ShaderSurface` must stay full-canvas via shared sizing component.
- every mutable sketch `ShaderMaterial` remains `resource_local_to_scene = true`.
- RATE remains opaque/centered/in-app.
- no main-window visibility toggles at startup.
- no fake Spout/NDI support.
- do not invent missing reviews or claim text was read when sanitizer removed it.

## Required next host validation

1. Sync exact final HEAD and require exact-head CI before launch.
2. Gallery LIST: rows stay ~68 px; preview decorates background/right side without consuming row height.
3. Open several sketches and use PREV/NEXT repeatedly; order must be numeric and PROGRAM must remain untouched unless TAKE LIVE is used.
4. Stress 041 with direct node grabs and extreme parameter changes; terminal must show **zero** triangulation errors.
5. Do not retype old reviews. Wait for startup review checkpoint, then inspect `telemetry/runtime` and confirm existing written `note` content is present in `creative_preference_snapshot`.
6. Continue normal RATE notes; confirm new comments appear remotely without chat copy/paste.
7. Telemetry-first on the next turn before any new creative batch.

## Mandatory AI completion protocol

After every material repository change: finish code -> push -> update durable docs/state -> resolve final remote HEAD **after all docs** -> wait/inspect CI for that exact SHA -> report exact short HEAD + exact CI -> automatically provide canonical PowerShell when host validation is useful -> after host test inspect telemetry first.
