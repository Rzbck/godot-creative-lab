# Current work — DC//LAB

Last refreshed: 2026-09-26.

## Active branch / PR

- branch: `feat/creative-sketches-002-004-20260924`
- draft PR: #7
- base: `feat/gallery-project-workflow-20260923`
- never merge/change `main` without explicit user approval
- source catalogue: **001–045**
- top runtime: `app/main/main_runtime_gallery_host_fixes.gd`

## Latest host test

The user tested HEAD `a55c65c6...` and reported:

- LIST revision 1 is too large; rows must stay compact and use preview imagery as background decoration rather than a large left thumbnail.
- ProjectView needs direct previous/next sketch browsing.
- written RATE feedback has been entered extensively and must become automatic evidence for future repairs/creative generation.
- 041 TENSION ORGAN repeatedly emitted `Invalid polygon data, triangulation failed` from `_draw()`.

Terminal also showed successful asynchronous `review_checkpoint` publisher processes.

## Telemetry-first findings

Raw GitHub telemetry proves the current session is non-empty. Session: `5cb124f1822c2ee4`.

The old sanitizer preserved:
- numeric `sketch_review_changed` events;
- `creative_preference_snapshot` ratings;
- `sketch_review_note_changed.note_length`.

But it **removed the actual written `note` string**. Therefore the user did not need to paste the notes because the app stored them locally, but the current remote copy cannot yet reveal their contents. Never claim otherwise.

Latest visible numeric evidence includes:
- 036 ~1.83
- 037 ~2.33
- 038 ~2.67 (visual 4 / originality 4; strongest recent signal)
- 039 ~2.17
- 040 2.0
- 043 1.0
- 044 2.0
- 045 1.0

Do not invent missing 041/042 values or text comments.

## Implementation completed before docs

### Gallery host layer revision 2 — `21d31984...`

- LIST row height = **68 px**.
- real SubViewport preview is reused as a low-alpha right-side background layer.
- compact index/title/engine/tags remain overlaid.
- existing ReviewBadge remains above the decoration.
- PREV/NEXT buttons are inserted after `< GALLERY` in ProjectToolbar.
- adjacency uses numeric source order, skips locally removed sketches, disables at edges, no wrap.
- `_open_sketch()` remains the switching path, preserving PROGRAM semantics.
- startup schedules `review_checkpoint_startup_republish` so saved user notes can be republished automatically.

### 041 safe tessellation — `df9710ae...`

The failure was not random: deforming spring cells can become concave, inverted or near-degenerate, while `draw_colored_polygon([p0,p1,p2,p3])` asks the renderer to triangulate them.

Fix:
- remove dynamic quad polygon triangulation;
- choose the shorter diagonal per cell;
- draw two explicit triangle primitives;
- skip triangles below a small area threshold;
- leave physical spring simulation unchanged.

### Written-review telemetry — `0c360c35...`

`publish-telemetry-diagnostics.ps1` now:
- allows only one bounded free-text field: `note`;
- caps it at 2000 chars;
- strips disallowed control characters;
- preserves safe creative identifiers/tags/signature strings;
- rejects zero-byte sanitized output.

Because notes are persisted in `user://creative_lab_reviews.cfg`, the next startup checkpoint should republish existing comments without retyping them.

## Validation

Implementation HEAD `0c360c358e4b08fc456ba158fd35d6f62e18a253` passed **CI #312** completely before documentation:
- Repository policy — success
- temporal audit — success
- adaptive creative draw self-test — success
- Godot 4.7.1 import — success
- main scene smoke — success
- tracked cleanliness — success

Host validation is still required for dynamic 041 stress, compact list appearance, PREV/NEXT UX and actual remote note contents.

## Durable feedback rule

Written RATE comments are first-class creative evidence. After every host test, before generating or repairing sketches, future AI must inspect the latest remote preference snapshot and read **numeric ratings plus text notes**. The user should not need to repeat an existing RATE comment in chat.

Use the comments for:
- direct bug/interaction repairs;
- understanding why a score is low/high;
- extracting recurring visual/interaction preferences;
- bounded bias in future creative recipes;
- updating durable creative rules when feedback repeats.

Do not turn one positive review into a cloning rule; keep exploration active.

## Existing contracts to preserve

- PROGRAM persists across navigation; TAKE LIVE explicitly replaces it.
- physical PROGRAM touch/mouse works.
- linked PREVIEW/PROGRAM share one timeline/state.
- per-sketch params persist.
- real Gallery thumbnails; idle frozen, hover live.
- TRASH is exclusive and local only; never delete Git source.
- Gallery supports INDEX ↑/↓, TITLE, FAMILY, GRID/LIST and grid size.
- LIST must stay dense; preview is decorative background, not large thumbnail.
- ShaderMaterial mutable state is local to scene instances.
- full-canvas shader surface rule remains enforced.
- RATE remains centered/opaque/in-app.
- no fake Spout/NDI.

## Next host validation

1. Sync exact final HEAD and wait exact CI.
2. Verify LIST density/background preview at several window sizes.
3. Open e.g. 037 -> 038 -> 039 using NEXT, then PREV; PROGRAM must not change unless TAKE LIVE is pressed.
4. Stress 041 by dragging central nodes and changing tension/elasticity/damping; terminal must remain free of triangulation errors.
5. On startup, allow automatic review checkpoint to publish; next AI inspects `telemetry/runtime` and confirms real `note` strings appear in `creative_preference_snapshot`.
6. Continue normal written RATE feedback; never require chat duplication.

## Mandatory completion

Material change -> code/push -> durable docs/state -> exact final remote HEAD -> exact-head CI -> report SHA/result -> canonical PowerShell when host test is useful -> telemetry-first after test.
