# Architecture — DataC0re Creative Lab

## Status

Godot 4.7.1 creative-coding workstation. Repository state plus matching runtime telemetry are authoritative when they disagree with chat history.

Source catalogue: **001–045**.
Entry scene: `res://app/main/main_runtime.tscn`.
Top runtime: `res://app/main/main_runtime_gallery_host_fixes.gd`.

## Product model

DC//LAB separates:
1. WORKSTATION / EDITOR — Gallery, Settings, PREVIEW, parameters, review/curation/navigation.
2. PROGRAM / LIVE OUT — persistent audience-facing output.
3. SKETCH — isolated state/parameters/interaction runtime.

Navigation is not transport. Gallery browsing, PREV/NEXT and opening another PREVIEW do not stop/replace PROGRAM. `TAKE LIVE` explicitly replaces PROGRAM.

## Runtime chain

Current upper chain:

```text
main_runtime_gallery_host_fixes.gd
  -> main_runtime_window_memory.gd
    -> main_runtime_gallery_compact_review.gd
      -> main_runtime_gallery_feedback_trash.gd
        -> main_runtime_gallery_adaptive_filters.gd
          -> main_runtime_gallery_organizer.gd
            -> main_runtime_program_output.gd
              -> main_runtime_gallery_persistence.gd
                -> main_runtime_live_output.gd
                  -> lower output/window/telemetry layers
```

Always inspect actual `extends` relationships before modifying host behavior.

## Gallery host layer revision 2

`main_runtime_gallery_host_fixes.gd` is intentionally a thin final layer for host-proven UX corrections.

### LIST

LIST is a dense file-browser presentation:
- row height: ~68 px;
- no separate large thumbnail;
- each card reuses its existing real SubViewport texture as a low-alpha decorative backdrop on the right side;
- compact index/title/engine/tags overlay;
- ReviewBadge remains above decoration;
- hover still animates the same underlying preview; idle remains frozen;
- GRID presentation is unchanged.

Do not regress LIST into large horizontal cards. The preview decorates the row; it does not determine row height.

### TRASH

TRASH is exclusive:
- normal Gallery scroll/cards/search/browser controls hide while Trash is open;
- restore/purge controls remain local curation only;
- source in Git is never deleted.

### Adjacent sketch navigation

ProjectToolbar contains `‹ PREV` and `NEXT ›`.
- source order is numeric index, independent of Gallery sort;
- `_catalog` already excludes locally removed sketches, so they are skipped;
- no wrap; edge buttons disable;
- switching calls normal `_open_sketch()` and therefore preserves PROGRAM semantics.

## Review / preference feedback

RATE remains a centered opaque in-app modal with six 1–5 axes plus free text **WHY / NOTES**.

Local persistence:
`user://creative_lab_reviews.cfg`

The review layer emits `creative_preference_snapshot` and schedules asynchronous `review_checkpoint` publication after rating/note changes. Host layer revision 2 also schedules a startup republish so durable local comments can be transmitted after publisher upgrades without re-entry.

### Telemetry sanitizer revision — written notes

Historical problem: the diagnostic publisher intentionally removed unapproved strings. Numeric reviews survived, `note_length` survived, but actual `note` text was stripped.

Current `scripts/publish-telemetry-diagnostics.ps1` contract:
- arbitrary strings still default to rejected;
- explicitly safe machine-readable identifiers/signature strings are allowed;
- `note` is the sole bounded free-text field;
- note max length = 2000 chars;
- disallowed C0 controls are removed;
- sanitized output must be non-empty before publication.

Written reviews are first-class creative evidence. After host testing, AI must inspect both numeric axes and note strings before repair/new generation. Never ask for chat duplication when telemetry already contains the review.

## Current telemetry evidence

Session `5cb124f1822c2ee4` proves review checkpoints publish non-empty JSONL. The old sanitizer version contains numeric preference snapshots and `sketch_review_note_changed.note_length`, but not note contents. Existing local comments should be republished by the next startup checkpoint through the new sanitizer; host validation must confirm actual `reviews.<id>.note` strings remotely.

## Stateful ShaderMaterial isolation

Gallery, PREVIEW and PROGRAM may instantiate the same PackedScene simultaneously. Mutable resources must not leak across instances.

Permanent contract:
- runtime sketch ShaderMaterial subresources use `resource_local_to_scene = true`;
- CI enforces this;
- immutable Shader code may be shared, mutable uniforms/textures may not;
- stateful CPU->GPU texture sketches use atomic/double-buffer patterns when appropriate.

## Dynamic mesh safety — 041

A physical constraint lattice can produce locally concave, inverted or degenerate cells. Renderer polygon triangulation must not be given arbitrary deforming quads.

041 now:
- retains 17×10 spring simulation;
- picks the shorter diagonal of each cell;
- draws explicit triangle primitives;
- skips near-zero-area triangles.

General rule: simulation topology and render tessellation are separate concerns. For dynamic deforming surfaces, provide explicit robust triangles or a mesh pipeline that controls indices.

## Gallery persistence / organization

Cards own real sketch instances in SubViewports. Idle thumbnails freeze, hover animates. Persisted parameters can be mirrored into hidden thumbnails, which is why mutable-resource isolation matters.

Browser behavior:
- INDEX ↑ default;
- INDEX ↓ / TITLE / FAMILY;
- GRID / LIST;
- GRID size adjustable;
- browser state: `user://creative_lab_gallery_view.cfg`;
- reflow reparents existing cards/SubViewports rather than recreating simulations;
- adaptive quick-tag rail stays bounded.

## Window / output

Saved workstation window state remains separate from F11 artwork presentation. Never toggle main `Window.visible` during startup. PROGRAM output remains persistent and interactive on the physical output surface.

## Full-canvas render contract

Logical design coordinates are usually 1280×720; actual PREVIEW/PROGRAM surfaces adapt to viewport size.

Nodes named `ShaderSurface` use shared `res://sketches/_shared/full_canvas_surface.gd`. CI rejects fixed 1280×720 ShaderSurface offsets.

Hidden low-resolution state is allowed. Final visible output must reconstruct suitable high-resolution form/material/detail; coarse solver pixels are not finished art.

## Creative / temporal contracts

Read:
- `knowledge/cross-domain/VISUAL_FINISH_GATE.md`
- `knowledge/cross-domain/TEMPORAL_MOTION_QUALITY.md`
- `knowledge/cross-domain/ADAPTIVE_CREATIVE_DRAW.md`

Pipeline:
`adaptive draw -> prototype -> observe -> mutate -> art-direct -> visual-finish gate -> keep/reject`

Preferred temporal chain:
`time -> force/state/memory/event -> coupled system -> render`

Reject generic direct clock wobble, visible phase wraps/global resets/respawn walls and superficial pointer effects. Physical periodic forcing is allowed only when the visible representation remains continuous.

## Preference evidence

Current recent remote ratings include:
- 036 ~1.83
- 037 ~2.33
- 038 ~2.67 (visual/originality 4; best recent signal but weak controls/interaction)
- 039 ~2.17
- 040 2.0
- 043 1.0
- 044 2.0
- 045 1.0

Written comments from the old sanitizer publication must not be invented. Once republished, those notes should directly inform repairs and bounded creative biases.

## Historical non-regressions

- 005 source path stays `005_pressure_lattice`, visible artwork remains **REGISTER TYPE**.
- generalized glyph-contour treatment is not a house style.
- no permanent full tag wall.
- mutable ShaderMaterial state stays local per scene.
- RATE stays opaque/centered/in-app.
- no main-window visibility toggles at startup.
- Spout/NDI are future adapters; never represent them as installed/working when they are not.
