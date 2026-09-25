# HANDOFF — DataC0re Creative Lab

Canonical restart point. Resolve real remote branch HEAD + exact-head CI first; matching repo state/telemetry beat chat history.

Last material refresh: 2026-09-25.

## Repository

- GitHub: `Rzbck/godot-creative-lab`
- local root: `E:\_Project\GodotCreativeLab`
- Godot GUI: `C:\Godot\Godot_v4.7.1-stable_win64.exe`
- console: `C:\Godot\Godot_v4.7.1-stable_win64_console.exe`
- branch: `feat/creative-sketches-002-004-20260924`
- draft PR #7, base `feat/gallery-project-workflow-20260923`
- never merge/change `main` without explicit user approval

## Stable product contract

PROGRAM persists across Gallery/Settings/other PREVIEW; `TAKE LIVE` replaces it. Physical PROGRAM touch/mouse remains supported. Linked PREVIEW/PROGRAM share one generative state. Per-sketch parameters persist. Gallery uses real thumbnails and only hovered previews animate. PROGRAM is artwork-only. Telemetry publishing must never block the Godot UI.

Current top runtime: `res://app/main/main_runtime_window_memory.gd`.
Gallery source count: **35** (001–035).

## Latest host verdict — important

The host explicitly rejected **026–030 as globally visually weak** despite their technical diversity. Treat that batch as creatively rejected, not as evidence that adaptive generation succeeded.

The host requires future pieces to be beautiful at large output resolution, detailed, composed and materially convincing rather than small technical demos.

Durable quality rule: `knowledge/cross-domain/VISUAL_FINISH_GATE.md`.

Required creative pipeline is now:

`adaptive draw -> prototype -> mutate -> art-direct -> visual-finish gate -> keep/reject`

The draw engine is a collision generator, not an art director.

## Telemetry facts from latest failed pass

Telemetry-first was performed.

Current remote telemetry HEAD `309bf4e93aa62ce01e472dfdb817f684c05cd1bd` contains an **empty** `latest.jsonl` and empty latest session after close. Therefore the numeric ratings the host entered for 026–030 are currently unrecoverable remotely. Do not invent them.

The previous non-empty telemetry commit `1dc917da35c61c1c7e112684c139dc9d14d528a5` matches tested app head `dba702d0...` and proves the window bug:

- restored/startup state: native `windowed`, `[1600,0]`, `[1920,1078]`;
- custom Maximize invoked around 8.8 s;
- result became native `fullscreen`, `[1920,1080]`;
- user toggled again ~650 ms later.

Direct qualitative host rejection of 026–030 remains valid evidence even though the numeric ratings were lost.

## Window-state revision 2

The previous custom Maximize used native maximize and Windows/Godot reclassified the borderless monitor-sized client as fullscreen. That path is rejected.

`main_runtime_window_memory.gd` revision 2 now:

- persists logical window state to `user://creative_lab_window_state.cfg`;
- restores before the first visible frame;
- implements workstation `maximized` as borderless **WINDOWED** usable-screen geometry with a 2 px bottom guard;
- tracks `_workstation_expanded` so the normal restore rect is not overwritten;
- migrates revision-1 saved fullscreen from the old Maximize path to the stable expanded state;
- keeps F11 artwork presentation separate;
- flushes and starts a final telemetry publisher process before quit instead of relying only on a deferred close publish.

Status: **REPO_VALIDATED, HOST_VALIDATION_REQUIRED**. Fresh host telemetry must prove stable Maximize/Restore and a non-empty close publication.

## FARADAY QUASI — root cause and correction

The old visible cut was mathematically real:

- controller wrapped forcing phase at `2π`;
- shader multiplied that wrapped phase by fractional coefficients (`0.94`, `1.06`, `0.91`);
- transformed phases were discontinuous at the wrap;
- click also injected a direct local shader height bump, making the cut easier to see.

Current 025:

- forcing phase is internal physical pump state only;
- visual modal phases are unwrapped/continuous;
- shader no longer receives wrapped forcing phase;
- touch modifies modal energy/detuning rather than drawing a click-local bump;
- shader was rebuilt with continuous harmonics, finite-difference normals and richer material shading.

Status: **REPO_VALIDATED, HOST_VALIDATION_REQUIRED**. Test idle 30 s plus repeated press/drag/release.

## High-fidelity batch 031–035

All include `creative_seed` + implemented `creative_signature`; signatures are recorded in `creative_draw_space.json`.

- **031 FOLD CHAMBER** — 150-point Delaunay relief, spring constraints, per-facet normals/material, pressure-driven refolding; vector-resolution final render.
- **032 LUMEN SWARM** — up to 900 MultiMesh light streaks with halo/core layers, spatial advection and inertial touch-movable source; no synchronized population reset.
- **033 OBSIDIAN CATHEDRAL** — full-resolution SDF raymarch architecture, AO, facets, roughness/specular, spectral grazing light and persistent touch fractures; no shader TIME.
- **034 PHOSPHOR SAND** — 128×72 memory solver is hidden state only; final full-resolution material reconstructs relief, gradients, micro-grain, particles and spectral grazing response.
- **035 DUNE CHOIR** — damped 2D wave PDE rendered as dense antialiased perspective vector topography with longitudinal seams and curvature-derived peak glints.

Code batch commit `3ff965f...` passed CI #287: policy, temporal audit, adaptive draw self-test, Godot 4.7.1 import, main-scene smoke and tracked-file cleanliness. Subsequent documentation/history commits require their own final exact-head CI before completion.

## Visual finish gate — permanent

Read `knowledge/cross-domain/VISUAL_FINISH_GATE.md` for substantial creative work.

Hard requirements:

- frozen frame must already work as an image;
- deliberate composition/negative space and persistent identity anchors;
- multiple useful detail scales;
- final PROGRAM image must not expose an enlarged coarse solver texture;
- hidden low-res simulation is allowed only when final rendering reconstructs high-resolution geometry/material/detail;
- material/light should support the claimed carrier;
- no visible phase wrap, reset, respawn wall or synchronized restart;
- interaction must enter state/material logic rather than overlay a generic cursor effect.

## Existing creative constraints

- 001 remains technical foundation/reference.
- 005 internal id remains `005_pressure_lattice`, visible artwork **REGISTER TYPE**; never restore Pressure Lattice.
- generalized glyph-contour pass across 006–010 was host-rejected; never make it the house representation.
- 026–030 remain in source/history for evidence but are creatively rejected by host.
- explicit ratings remain bounded evidence; 24% adaptive draws stay preference-free.
- user rejects generic visible clock wobble. `TEMPORAL_MOTION_QUALITY.md` still applies.

## REVIEW / Gallery

RATE remains the opaque centered in-app modal; never restore the transparent native popup. Reviews persist in `user://creative_lab_reviews.cfg`, Gallery cards show rating badges, local Trash remains reversible and never deletes Git source.

## Required next host validation

1. Launch and test custom Maximize/Restore repeatedly; workstation must remain stable and not become native fullscreen.
2. Close/reopen once expanded and once moved/resized windowed; saved logical state must restore coherently.
3. FARADAY QUASI: idle 30 s, then repeated click/hold/drag/release; no global cut/click seam.
4. Open 031–035 large. Judge frozen frame first, then 20–30 s idle, then interaction/recovery and parameter extremes.
5. RATE 031–035 normally.
6. Close normally; next AI inspects `telemetry/runtime` first and requires a fresh **non-empty** matching session before trusting ratings.

## Mandatory completion

After material changes: commit/push branch work, update durable docs/state, resolve final remote HEAD, wait exact-head CI, report exact short SHA + CI, provide canonical PowerShell when host validation is useful, then telemetry-first after user test.

## Rejected regressions

Do not stop PROGRAM on navigation, create independent linked timelines, block UI with telemetry Git work, resurrect failed cross-window texture sampling, fake Spout/NDI, restore Pressure Lattice, restore the generalized glyph-contour house style, restore permanent all-tags UI, restore fixed 1280×720 ShaderSurface nodes, restore native transparent RATE popup, use naked global-clock wobble as generic aliveness, or expose a visibly coarse solver as final artwork.
