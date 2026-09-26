# Current work — DC//LAB

Last refreshed: 2026-09-26.

## Active branch / PR

- branch: `feat/creative-sketches-002-004-20260924`
- draft PR: #7
- base: `feat/gallery-project-workflow-20260923`
- never merge/change `main` without explicit user approval
- source catalogue: **001–050**
- top runtime: `app/main/main_runtime_gallery_host_fixes.gd`

## Feedback evidence consumed before 046–050

The latest usable preference telemetry is no longer numeric-only. Session `67a6e7499c4524cf` / runtime HEAD `ceecb6be59a9` verified that startup republish works and that real written `note` strings are present under `creative_preference_snapshot.reviews.<sketch>.note`.

Current axis averages over the available reviewed set:
- visual ~2.06
- interaction ~1.72
- originality ~1.92
- aliveness ~1.64
- controls ~1.56
- performance ~2.42

The weakest recurring axes are therefore **controls, aliveness and interaction**.

Strong bounded references:
- 020 ECHO TISSUE: avg ~4.17 across the six axes;
- 012 CHEMICAL BLOCKS: avg ~3.33;
- 038 ELECTRIC LACE: avg ~2.67, with visual 4 / originality 4.

Written feedback that directly shaped the new batch:
- 041 TENSION ORGAN: too basic for the subject, physics not strongly felt, visual bugs when pulled too far;
- 042 MYCELIUM RELAY: promising, but missing interaction; parameters feel ineffective instead of creating a genuinely different result;
- 043 SLIT MEMORY: incomprehensible, not real-time interactive, clicks have no felt response, visually rejected;
- 044 EXCITABLE GLASS: too pixelated, no reset, parameters do too little;
- 045 RIFT VOLUME: strongly rejected visually and semantically; result is not understandable.

Durable interpretation: parameters are only useful when they create **visible regime/composition changes**. Interaction must be immediate enough to understand, stateful enough to matter after release, and coupled to the material/system rather than being a superficial pointer overlay. Hidden coarse simulation is acceptable; visibly enlarged solver pixels are not finished artwork.

## New feedback-driven batch 046–050

This batch deliberately avoids copying ECHO TISSUE or ELECTRIC LACE. It reuses only their positive qualities: readable causality, strong direct manipulation and meaningful state change.

### 046 INK SHEAR

- persistent vector ink filaments, not an enlarged fluid grid;
- user gesture writes persistent eddies into the flow;
- viscosity, vorticity, filament count, pigment split, wet bleed, brush force/radius and eddy memory alter different aspects of the resulting regime;
- interaction survives release through decaying vortex memory.

### 047 MOIRE APERTURE

- full-resolution analytic interference field;
- draggable apertures/anchors locally lens and shear the registration structure;
- line density, layer angle, shear, lens power, aperture radius and contrast change the family of interference rather than merely changing an amount;
- no visible coarse simulation texture.

### 048 ACTIVE NEMATIC

- hidden coupled director/flow solver;
- visible artwork is a MultiMesh field of **880 oriented filaments**, not solver cells;
- direct gesture writes orientation/spin into the field;
- alignment, activity, defect birth and flow memory are intended to create genuinely different active-matter regimes.

### 049 TEMPER SKIN

- thermally reactive metal skin with local heat, conduction, cooling and oxide memory;
- state-dependent interaction: a cold region is heated, while interacting with an already-hot region quenches/cools it;
- parameters control thermal lifetime, coupling and retained material memory rather than cosmetic brightness alone.

### 050 FERRO TRACE

- **1100 MultiMesh iron filings** oriented by a magnetic field;
- 2–4 directly draggable poles/sources;
- orientation hysteresis gives the field temporal memory instead of instant stateless following;
- preserves the positive source legibility of 038 without copying its electric-lace surface.

`knowledge/cross-domain/creative_draw_space.json` now records 046–050 in creative history so future draws can avoid accidental collisions.

## Validation already completed

Implementation HEAD `96471494f10c8c292ab8b0c0c04ea6dcf2828034` passed **CI #340** completely before the durable-doc bundle:
- Repository policy — success
- temporal audit — success
- adaptive creative draw self-test — success
- Godot 4.7.1 import — success
- main scene smoke — success
- tracked cleanliness — success

The first smoke attempt correctly caught two implementation issues before host delivery:
- 046 GDScript type inference ambiguity;
- 047 shader redefinition of built-in `PI`.

Both were fixed before CI #340 went green.

Important: **046–050 are repo/CI validated, not yet host-rated or artistically accepted.** Do not infer visual success from technical diversity or CI success.

## Existing host/product contracts to preserve

- PROGRAM persists across navigation; TAKE LIVE explicitly replaces it.
- physical PROGRAM touch/mouse works.
- linked PREVIEW/PROGRAM share one timeline/state.
- per-sketch params persist.
- real Gallery thumbnails; idle frozen, hover live.
- adaptive tag rail stays bounded; never restore the permanent all-tags wall.
- TRASH is exclusive and local only; never delete Git source.
- Gallery supports INDEX ↑/↓, TITLE, FAMILY, GRID/LIST and grid size.
- LIST stays dense (~68 px); preview is decorative background, not a large left thumbnail.
- PREV/NEXT switches PREVIEW by numeric source order and must not replace PROGRAM.
- ShaderMaterial mutable state is local to scene instances.
- full-canvas shader surface rule remains enforced.
- RATE remains centered/opaque/in-app.
- written RATE comments are first-class evidence and must be consumed automatically.
- no fake Spout/NDI.

## Next host validation

After exact final HEAD CI is green:

1. Confirm Gallery now shows **50 source sketches**.
2. Recheck LIST compactness and PREV/NEXT/PROGRAM persistence while reviewing 046–050.
3. Watch each 046–050 at defaults for ~20–30 seconds before touching controls; judge whether it has autonomous life without generic clock wobble.
4. Interact, release, and verify the gesture has an immediate readable response plus a persistent/delayed consequence.
5. Move every parameter through a large range. A parameter that appears to do nothing or only changes intensity is a failure signal.
6. 046: write several opposite eddies and verify ink actually shears/retains the intervention.
7. 047: drag apertures and push density/angle/shear/lens to clearly different interference regimes.
8. 048: disturb the nematic field and verify the filament field—not pixels—shows defects, flow and memory.
9. 049: heat cold metal, then act on an already-hot area and verify state-dependent quench/cooling; test conduction/cooling/oxide-memory extremes.
10. 050: drag magnetic poles and verify filings rotate/reorganize with hysteresis; vary pole count/field-related controls and look for genuinely different field organizations.
11. Continue RATE numeric + written feedback normally; do not duplicate those notes in chat.
12. Close normally so telemetry publishes; next AI must inspect fresh `telemetry/runtime` first and verify the tested runtime HEAD/session before attributing scores or performance.

## Mandatory completion

Material change -> code/push -> durable docs/state -> exact final remote HEAD -> exact-head CI -> report SHA/result -> canonical PowerShell when host test is useful -> telemetry-first after test.
