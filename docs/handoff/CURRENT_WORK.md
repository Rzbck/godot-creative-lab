# Current work — DC//LAB

Last refreshed: 2026-09-26.

## Active branch / PR

- branch: `feat/creative-sketches-002-004-20260924`
- draft PR: #7
- base: `feat/gallery-project-workflow-20260923`
- never merge/change `main` without explicit user approval
- resolve final remote HEAD after all docs commits, then require CI on that exact SHA

## Stable product behavior

Preserve real Gallery thumbnails/hover animation, parameter persistence, PREVIEW/PROGRAM separation, persistent PROGRAM across navigation, TAKE LIVE, physical output input, linked state sync, artwork-only PROGRAM output and async telemetry.

Current top runtime: `app/main/main_runtime_window_memory.gd`.
Source catalogue: **001–040** before local curation.

## Latest host feedback — 2026-09-26

The user tested 036–040 and reported:

- **037 DENDRITE BLOOM:** obvious pixel stair-stepping and stale/black-frame flashes whenever interacting or changing parameters.
- **038 ELECTRIC LACE:** positive concept signal (`vraiment sympa`), but interaction was too weak/indirect; charges should be grabbed directly by clicking on them.
- **040 SCHLIEREN VEIL:** same stale-frame / old-frame glitch on click and parameter changes as 037.
- RATE needs a free-text explanation field so low/high axis scores have a reason.
- Gallery needs file-browser controls: deterministic sort, GRID/LIST modes and adjustable card size.

The attached 037 host capture visibly showed coarse cell boundaries, so the complaint is grounded in the rendered output rather than only subjective description.

## Telemetry recovered from this test

Telemetry-first was performed.

- final `session_close_request` publication was empty again;
- the last non-empty intermediate checkpoint recovered numeric ratings for 031–035:
  - 031 FOLD CHAMBER: avg **2.0**;
  - 032 LUMEN SWARM: avg **1.5**;
  - 033 OBSIDIAN CATHEDRAL: avg **1.0**;
  - 034 PHOSPHOR SAND: avg **~2.17**;
  - 035 DUNE CHOIR: avg **1.0**.
- new 036–040 scores were not present in the recoverable remote checkpoint. Do **not** invent them.

## Root cause — stale shader frames

The key architectural bug was shared mutable `ShaderMaterial` resources.

The Gallery keeps a hidden real sketch instance for each thumbnail. Parameter persistence also mirrors parameter changes into that hidden instance. Shader scenes used a non-local `ShaderMaterial`, so Gallery thumbnail, active PREVIEW and PROGRAM instances could share uniforms/textures. A hidden thumbnail could therefore overwrite `u_state` on the active artwork with an old texture.

Implementation commit `e20e1751ed2dae70899f56fcf5217b3d84e75910` fixes this globally:

- all current sketch `ShaderMaterial` subresources now set `resource_local_to_scene = true`;
- repository CI rejects any future runtime sketch ShaderMaterial missing this flag;
- 037 and 040 use double-buffered `ImageTexture` uploads and atomically switch the shader sampler after updating the inactive texture;
- interaction marks state dirty and publishes the next complete state without waiting for an unrelated later simulation tick;
- 037 and 040 shaders reconstruct coarse hidden state with weighted multi-tap sampling before lighting/gradients, reducing visible cell stair-stepping without multiplying live-sync state size.

CI #299 passed the implementation commit fully: repository policy, Godot 4.7.1 import, main-scene smoke and tracked cleanliness.

## 038 ELECTRIC LACE interaction revision

038 keeps the visual/technical concept. Interaction changed only:

- click must land within a real charge hit radius;
- drag directly positions that charge instead of weakly moving a target spring;
- empty-space clicks no longer grab an arbitrary nearest charge;
- release keeps a small inertial velocity;
- a subtle grab ring appears only while manipulating the charge.

## REVIEW revision 4

RATE remains an opaque centered in-app modal but now includes **WHY / NOTES**.

- free-text note stored in `user://creative_lab_reviews.cfg` beside the six numeric axes;
- note included in `creative_preference_snapshot` telemetry;
- `SAVE REVIEW` persists explicitly; closing the modal also saves pending text;
- note capped at 2000 characters;
- ratings/notes schedule a telemetry checkpoint ~0.8 s after the last edit, so feedback reaches the remote branch without depending on app shutdown.

## Gallery browser revision 2

Gallery keeps semantic tags/search but adds file-browser behavior:

- default flat sort: **INDEX ↑**;
- other sorts: INDEX ↓, TITLE A–Z, FAMILY;
- FAMILY restores semantic grouped sections;
- GRID / LIST presentation toggle;
- adjustable grid card/preview size;
- browser state persists to `user://creative_lab_gallery_view.cfg`;
- sorting/reflow reparents existing cards and keeps their real SubViewport instances alive instead of recreating simulations.

## Window / telemetry revision 4

Startup still never toggles main-window visibility. Revision 4 changes shutdown:

- close writes non-autopublished `session_close_flush` telemetry;
- flushes and explicitly calls `FileAccess.close()`;
- releases the handle;
- then starts the single hidden final publisher with reason `session_close_request`;
- this removes the previous automatic-close-publisher vs dedicated-final-publisher race.

Host validation must prove the final remote session is non-empty.

## Creative quality / temporal rules

`knowledge/cross-domain/VISUAL_FINISH_GATE.md` remains mandatory from 036 onward.

- technical diversity is not visual quality;
- frozen frame must already work as an image;
- several useful detail scales;
- hidden low-res solver may drive state, never be exposed directly as enlarged final art;
- no generic `time -> sin/cos -> visible wobble`;
- no visible phase wrap/reset/respawn wall;
- interaction enters state/material/topology, not a generic pointer overlay.

## Next host validation

1. Sync exact final HEAD and wait exact-head CI before launch.
2. Open 037; drag/click and scrub several parameters continuously. No black/stale-frame flashes; cell stair-stepping should be substantially reduced.
3. Open 040; repeat click/drag and parameter scrubbing. No old-frame flash/glitch.
4. Open 038; click directly on charges, drag them, release; empty-space click should not grab one.
5. Open RATE; write a WHY / NOTES comment, save, wait briefly, then continue testing.
6. Gallery: verify default 001→040 ordering, INDEX ↓, TITLE, FAMILY, GRID/LIST and size slider; restart and confirm browser state persists.
7. Close normally. Next AI inspects `telemetry/runtime` first and requires a fresh non-empty review checkpoint/final session before trusting 036–040 ratings.

## Mandatory completion

After material changes: code -> durable docs/state -> exact final remote HEAD -> exact-head CI -> report SHA/result -> canonical PowerShell when host testing is useful -> telemetry-first after host test.
