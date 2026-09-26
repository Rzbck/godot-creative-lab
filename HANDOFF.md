# HANDOFF — DataC0re Creative Lab

Canonical restart point. Resolve the real remote branch HEAD and exact-head CI before trusting any recorded SHA. Repository state + matching host telemetry beat chat history.

Last material refresh: 2026-09-26.

## Repository

- GitHub: `Rzbck/godot-creative-lab`
- local root: `E:\_Project\GodotCreativeLab`
- Godot GUI: `C:\Godot\Godot_v4.7.1-stable_win64.exe`
- Godot console: `C:\Godot\Godot_v4.7.1-stable_win64_console.exe`
- active branch: `feat/creative-sketches-002-004-20260924`
- draft PR: #7, base `feat/gallery-project-workflow-20260923`
- never merge/change `main` without explicit user approval

## Stable product contract

PROGRAM persists across Gallery/Settings/other PREVIEW. `TAKE LIVE` explicitly replaces PROGRAM. Physical PROGRAM touch/mouse is supported. Linked PREVIEW/PROGRAM share one state/timeline. Per-sketch params persist. Gallery uses real thumbnails and only the hovered preview animates. PROGRAM is artwork-only. Telemetry stays async/non-blocking. Local Trash never deletes Git source.

Top runtime: `res://app/main/main_runtime_window_memory.gd`.
Source catalogue: **001–040** before local curation.

## Latest host feedback — current priority

On the 036–040 host test:

- **037 DENDRITE BLOOM** showed coarse pixel/cell stair-stepping and flashed stale/black frames on interaction and parameter scrubbing.
- **038 ELECTRIC LACE** received the first clear positive signal (`vraiment sympa`), but its pointer control was too indirect; visible charges should be directly draggable.
- **040 SCHLIEREN VEIL** showed the same stale-frame glitch on click and parameter changes.
- RATE needs written feedback explaining why visual/interaction/aliveness/etc. are low/high.
- Gallery needs Finder/Explorer-style browsing: deterministic sort, GRID/LIST and adjustable thumbnail/card size.

Do not erase the 038 concept while improving interaction.

## Stateful shader root cause and permanent fix

The Gallery keeps a real hidden sketch instance for each thumbnail and mirrors saved parameter changes into it. Shader scenes previously used shared mutable `ShaderMaterial` subresources. Gallery thumbnail, active PREVIEW and PROGRAM could therefore share uniforms/textures; a hidden thumbnail could overwrite an active `u_state` with an old texture.

Implementation reference: `e20e1751ed2dae70899f56fcf5217b3d84e75910`, CI #299 fully green before docs.

Permanent rules now implemented:

- every sketch `ShaderMaterial` sets `resource_local_to_scene = true`;
- repository CI fails future runtime `.tscn` files whose ShaderMaterial omits that isolation;
- PREVIEW / PROGRAM / Gallery thumbnail must never share mutable shader uniforms/state textures;
- 037 and 040 additionally use two `ImageTexture` buffers: update the inactive texture, then switch the sampler to the completed texture;
- state-changing pointer input marks the render state dirty immediately;
- 037/040 final shaders smooth/reconstruct the hidden coarse field with weighted multi-tap samples before gradients/material lighting, reducing visible solver stair-stepping without exploding live-sync payload size.

## 038 direct manipulation

ELECTRIC LACE now:

- grabs only when the pointer lands within a visible charge hit radius;
- follows the pointer directly while held;
- does nothing on empty-space click;
- keeps a small inertial velocity on release;
- shows only a subtle active grab ring.

## REVIEW revision 4

Compact sidebar remains `REVIEW <avg> RATE TRASH`. RATE remains opaque, centered and in-app.

New written feedback:

- `WHY / NOTES` multi-line field;
- stored beside numeric axes in `user://creative_lab_reviews.cfg`;
- max 2000 characters;
- included in `creative_preference_snapshot`;
- `SAVE REVIEW` persists explicitly; closing modal also saves pending text;
- rating/note edits schedule a remote telemetry checkpoint about 0.8 s after the last edit, so useful review evidence no longer depends on application shutdown.

## Gallery browser revision 2

Tags/search remain metadata filters, but browsing is no longer dictated by group order.

- default flat view: **INDEX ↑** (`001 -> 040`);
- sort options: INDEX ↓, TITLE A–Z, FAMILY;
- FAMILY restores semantic tag-group sections;
- GRID / LIST modes;
- adjustable card/preview size in GRID;
- state persisted in `user://creative_lab_gallery_view.cfg`;
- sorting/reflow reparents existing card/SubViewport nodes instead of recreating simulations.

Adaptive tag rail remains bounded; do not restore a permanent wall of every tag.

## Window / telemetry revision 4

Startup still never toggles visibility of the main Godot Window. Saved mode/screen/geometry is applied in `_enter_tree()`. Logical Maximize remains borderless WINDOWED usable-screen geometry with a 2 px bottom guard. F11 stays separate artwork presentation.

The latest host final `session_close_request` publication was again empty. Last non-empty intermediate telemetry recovered 031–035 ratings:

- 031 FOLD CHAMBER avg 2.0
- 032 LUMEN SWARM avg 1.5
- 033 OBSIDIAN CATHEDRAL avg 1.0
- 034 PHOSPHOR SAND avg ~2.17
- 035 DUNE CHOIR avg 1.0

New 036–040 ratings are not remotely recoverable yet. Never invent them.

Shutdown revision 4 now uses one final path:

`session_close_flush -> flush -> FileAccess.close() -> release handle -> hidden final publisher(reason=session_close_request) -> quit`

This removes the previous auto-publisher vs dedicated-final-publisher race. Review checkpoints provide a second path for feedback durability.

## Creative evidence / quality bar

Earlier recovered ratings:

- 026 VOID TENSION = all 1
- 027 GLASS TIDE = visual 2, all others 1
- 028 LUMEN MAZE = all 1
- 029 FIBER FELT = all 1
- 030 REACTOR SKIN = all 1

026–035 are strong evidence that technical diversity is not artistic quality. Preserve the adaptive draw as a collision generator, not an art director.

Read `knowledge/cross-domain/VISUAL_FINISH_GATE.md`. Required pipeline:

`adaptive draw -> prototype -> observe -> mutate -> art-direct -> visual-finish gate -> keep/reject`

For 036+ CI requires `visual_finish` metadata: composition, material model, final render, >=3 detail scales and stateful interaction. Frozen frame, material logic and multiple useful scales matter. Hidden coarse state is allowed; enlarged coarse solver pixels are not finished artwork.

## Temporal-quality contract

Preferred:

`time -> force/state/memory/event -> coupled system -> render`

Reject cheap direct clock wobble, visible phase wrap, global reset, respawn wall and synchronized restart. FARADAY QUASI remains the canonical warning that physically periodic state can still create a visible rendering cut.

## Historical non-regressions

- 001 remains technical foundation/reference.
- 005 internal path remains `005_pressure_lattice`, visible artwork **REGISTER TYPE**; never restore Pressure Lattice.
- generalized glyph-contour treatment across 006–010 was rejected; never make contours the house representation.
- do not stop PROGRAM on navigation.
- do not create independent linked timelines.
- `ShaderSurface` must remain full-canvas via shared sizing component.
- ShaderMaterial mutable state must remain local per scene instance.
- do not restore transparent/off-centre native RATE popup.
- do not toggle main-window visibility during startup.
- do not fake Spout/NDI.

## Required next host validation

1. Sync exact final HEAD and require its exact CI before launch.
2. 037: scrub several parameters and click/drag repeatedly; no black/stale-frame flash, reduced block stair-stepping.
3. 040: same stress test; no old-frame flash.
4. 038: direct charge drag must feel immediate; empty-space click grabs nothing.
5. RATE: enter a WHY / NOTES comment, save it, then continue testing long enough for checkpoint publication.
6. Gallery: default 001→040, INDEX ↓, TITLE, FAMILY, GRID/LIST, size slider; restart and verify browser state persists.
7. Close normally.
8. Next AI inspects `telemetry/runtime` first and requires a fresh non-empty review checkpoint/final session before trusting new scores.

## Mandatory completion protocol

After every material repository change: finish code, update durable docs/state, resolve final remote HEAD **after all docs**, wait exact-head CI, report exact short SHA + exact CI, automatically include canonical PowerShell when host validation is useful, then telemetry-first after host testing.
