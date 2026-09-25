# HANDOFF — DataC0re Creative Lab

Canonical restart point for a new human or AI session.

**Always resolve current remote branch HEAD and exact-head CI before trusting recorded SHAs.** Repository state is authoritative; chat history is secondary.

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

DC//LAB is a Godot creative-coding workstation with data-driven Gallery discovery, real thumbnails, hover-only animated previews, generated parameter inspector/persistence, PREVIEW / PROGRAM separation, persistent PROGRAM while navigating, TAKE LIVE, physical display selection, PROGRAM touch/mouse forwarding, linked PREVIEW/PROGRAM state synchronization, async telemetry and versioned creative research.

Logical artwork space is `1280×720`.

PROGRAM canvas is artwork-only: no sketch title/index/tags/debug/project metadata unless genuinely part of the artwork.

## Historical creative constraints

001–010 remain available. `005_pressure_lattice` visibly remains **REGISTER TYPE**; original Pressure Lattice is rejected. Generalized contour pass `6c20a094...` across 006–010 was host-rejected; do not restore contour-everywhere.

011–015 improved underlying technique diversity but were visually weak, under-parameterized and not organically coupled enough.

016–020 improved again: 8–9 controls, actual neighbour/state coupling, more autonomous life. Host feedback on 2026-09-25 says this direction is **clearly better / starting to be good**, but still lacks real-world physical/chemical matter and some sketches appear performance-heavy.

## Performance finding / telemetry limitation

Telemetry-first inspection was done immediately after the newest host feedback.

Remote `telemetry/runtime` is stale for the 016–020 test. Latest remote telemetry commit is `82114646068521140f1727b7d323803f7de51e58` and its session still reports runtime `6dd4b307...` with 15 Gallery previews, i.e. the 011–015 era.

Therefore never claim exact FPS attribution for 016–020 from current remote telemetry.

The user observed some sketches falling below roughly 330 FPS on their host. Code audit found obvious rendering hotspots:

- 017 rendered up to ~2304 cell circles per render frame;
- 020 rendered up to ~2880 cells and recomputed neighbour stats during draw.

Both are now optimized:

- cell simulations still run at fixed cadence;
- dense fields render through one low-resolution `ImageTexture` draw;
- 020 caches density in simulation instead of rescanning neighbours in `_draw()`;
- sparse spores/agents remain direct geometry.

See `knowledge/cross-domain/REALTIME_PERFORMANCE_BUDGET.md`.

## New real-world knowledge bank

Read `knowledge/cross-domain/PHYSICAL_CHEMICAL_SYSTEMS_ATLAS.md`.

It adds mechanism cards for:

- Belousov–Zhabotinsky excitable chemistry;
- Liesegang precipitation/dissolution;
- spinodal/Cahn–Hilliard phase separation;
- Bénard–Marangoni surface-tension convection;
- Faraday parametric waves;
- Rosensweig ferrofluid instability;
- diffusion-limited aggregation;
- granular jamming / force chains;
- Rayleigh–Taylor, Kelvin–Helmholtz and Saffman–Taylor instabilities.

It also adds physical-condition drivers such as concentration, temperature, pressure, surface tension, viscosity, magnetic field, gravity, forcing frequency, supersaturation, friction, confinement and catalyst/inhibitor.

Rule: preserve at least one causal relationship/threshold from the real phenomenon; do not use science only as an aesthetic label.

## Current batch 021–025 — physical / chemical collision labs

Blind draw seed: `202609250742`.

- `021_rosensweig_field` / **ROSENSWEIG FIELD** — magnetic threshold -> coupled peak modes -> viscosity/hysteresis/relaxation; movable magnet interaction; 8 controls; single fullscreen shader pass.
- `022_liesegang_front` / **LIESEGANG FRONT** — reagent reservoirs -> diffusing front -> supersaturation -> precipitation bands -> depletion spacing -> dissolution; 8 controls; historical bands retain their own centres.
- `023_spinodal_marangoni` / **SPINODAL MARANGONI** — conserved-ish Cahn–Hilliard phase field + thermal quench + surface-tension advection; 9 controls; 56×32 simulation -> one texture draw.
- `024_granular_jam` / **GRANULAR JAM** — packed grains + friction/load + cached collision graph + force chains + creep + delayed avalanche; 9 controls; touch applies load rather than position.
- `025_faraday_quasi` / **FARADAY QUASI** — small CPU modal state + parametric resonance/mode competition -> fullscreen standing-wave shader; 8 controls; touch injects decaying local phase/impulse.

Runtime implementation commit: `50e7d9f9296768a09a56c7a8f7ac421a4d823389`.
CI #224 passed repository policy, Godot 4.7.1 import, main-scene smoke and tracked-file cleanliness for that runtime commit.

Resolve the **final docs HEAD** and its own CI before host testing; do not use the runtime commit's green run as proof for a newer docs HEAD.

## Durable creative rules

For substantial collision labs:

1. normally expose **6–9 meaningful independent controls** when the mechanism supports them;
2. at least half of controls should affect future evolution;
3. organic/cellular work requires real neighbour/subsystem coupling;
4. prefer multiple time scales: response + memory/repair/transport/fatigue;
5. raw does not excuse a weak default image;
6. interaction perturbs a living system and changes its future;
7. real-world cards must retain causal structure, not just surface resemblance;
8. performance architecture is part of the artwork: dense fields should use suitable texture/shader/batched representations instead of thousands of render-frame CanvasItem primitives.

## Knowledge priority

1. `knowledge/cross-domain/TECHNIQUE_PALETTE.md`
2. `knowledge/cross-domain/RANDOM_COLLISION_ENGINE.md`
3. `knowledge/cross-domain/COLLISION_SOURCE_CATALOG.md`
4. `knowledge/cross-domain/PHYSICAL_CHEMICAL_SYSTEMS_ATLAS.md`
5. `knowledge/cross-domain/ORGANIC_COUPLING_AND_CONTROLS.md`
6. `knowledge/cross-domain/REALTIME_PERFORMANCE_BUDGET.md`
7. relevant design/creative-coding atlases
8. `CROSS_DOMAIN_ATLAS.md` / `IDEA_ENGINE.md` when a mechanism deserves a final identity.

## Next host validation

Expected Gallery count: **25 sketches**.

1. Test 017 and 020 first for the performance regression/fix.
2. Watch 021–025 at default values for 20–30 seconds each.
3. Interact once, release and watch delayed consequences.
4. Explore the controls only after default-state observation.
5. Test strongest candidates in PROGRAM/touch.
6. Exit normally and immediately inspect fresh telemetry.
7. Exact FPS attribution requires telemetry whose runtime HEAD/session matches the tested build.

## PROGRAM / LIVE OUT architecture

Navigation is not transport. PROGRAM continues while browsing Gallery/Settings or opening another PREVIEW. TAKE LIVE replaces PROGRAM. Linked output follows synchronized source state; detached PROGRAM continues autonomously from the last synchronized state.

Inspect `res://app/main/main_runtime.tscn` and actual `extends` chain before changing host architecture.

## Mandatory AI completion protocol

After every material repository change, before final response: finish intended commits, update durable handoff/state, resolve the final remote HEAD after all code/docs commits, wait for CI on that exact SHA, report exact short SHA + CI, automatically provide canonical exact-CI PowerShell when host testing is relevant, and inspect telemetry first after the user test.

## Rejected regressions

Do not reintroduce root-window fullscreen as normal PROGRAM output, failed cross-window texture sampling, synchronous telemetry networking, independent linked simulations, Gallery overlays over cards, fake Spout/NDI, Pressure Lattice, project metadata inside artwork, or glyph contours as the default creative representation.

See `docs/handoff/CURRENT_WORK.md` for detailed current work and `docs/handoff/OPERATIONS.md` for the canonical CI-gated PowerShell.
