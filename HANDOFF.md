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
Source catalogue: **001–050** before local curation.

## Current user-feedback evidence

Written RATE transport and startup republish are now verified, not merely expected.

Verified telemetry:
- session: `67a6e7499c4524cf`
- runtime HEAD: `ceecb6be59a9`
- written notes are readable at `creative_preference_snapshot.reviews.<sketch>.note`

Current reviewed-axis averages:
- visual ~2.06
- interaction ~1.72
- originality ~1.92
- aliveness ~1.64
- controls ~1.56
- performance ~2.42

Main weak axes are therefore **controls, aliveness, interaction**.

Bounded positive references:
- 020 ECHO TISSUE avg ~4.17;
- 012 CHEMICAL BLOCKS avg ~3.33;
- 038 ELECTRIC LACE avg ~2.67 with visual 4 / originality 4.

Do not clone any of them. Preserve only useful qualities such as readable causality, understandable sources, direct state manipulation and clear regime changes.

Latest written feedback that materially shaped the next batch:
- 041: too basic for the subject, weak felt physics, visual failure when pulled too far;
- 042: promising but under-interactive; parameters appear ineffective instead of producing genuinely different outcomes;
- 043: incomprehensible, not felt as real-time interactive, click response weak, visual rejection;
- 044: too pixelated, no reset, weak parameter effect;
- 045: strong visual/semantic rejection and lack of comprehensibility.

Durable creative rule: a parameter is useful when it changes **regime, composition, topology, temporal response or material behavior** in a clearly perceivable way. Interaction should be immediate enough to understand and stateful enough to keep mattering after release.

## Latest batch — 046–050

These five sketches were implemented directly from the full feedback corpus, not from a single high-rated reference.

### 046 INK SHEAR

Persistent vector ink filaments coupled to user-written eddies. Gesture energy/spin remains in the flow through decaying eddy memory. Controls separate viscosity, vorticity, filament count, pigment split, wet bleed, brush force/radius and memory so they can produce materially different flow/mark regimes.

### 047 MOIRE APERTURE

Full-resolution analytic moiré/interference field with directly draggable apertures. Density, layer angle, shear, lens power, aperture radius, contrast and registration/chroma variables are intended to change the interference family, not only intensity. No coarse solver texture is exposed.

### 048 ACTIVE NEMATIC

Hidden coupled director/flow solver drives a visible MultiMesh of **880 oriented filaments**. Pointer gesture writes orientation/spin into the active matter. Alignment/activity/defect-birth/flow-memory controls target different nematic regimes rather than cosmetic modulation.

### 049 TEMPER SKIN

Thermally reactive metal with conduction, cooling and oxide memory. Interaction is state-dependent: cold material heats; already-hot material is quenched/cooled. The visible result depends on thermal history rather than a stateless brush overlay.

### 050 FERRO TRACE

Visible MultiMesh field of **1100 iron filings** with 2–4 directly draggable magnetic poles and orientation hysteresis. It preserves the positive source legibility observed in 038 while changing the carrier, dynamics and surface completely.

Creative collision history in `knowledge/cross-domain/creative_draw_space.json` now includes 046–050.

## Validation state

Implementation HEAD before final documentation:
`96471494f10c8c292ab8b0c0c04ea6dcf2828034`

It passed **CI #340** completely:
- Repository policy — success
- temporal audit — success
- adaptive creative draw self-test — success
- Godot 4.7.1 import — success
- main-scene smoke — success
- tracked cleanliness — success

The validation loop caught and fixed two issues before delivery:
- 046 GDScript type-inference ambiguity;
- 047 attempt to redefine shader built-in `PI`.

The batch is therefore **repo/CI validated but NOT host-rated or artistically accepted yet**. Never treat CI green as proof that the sketches are beautiful, comprehensible, fun or good.

## Gallery / host contracts still active

- LIST remains a dense ~68 px row; real preview is a low-alpha background decoration, not a giant left thumbnail.
- `‹ PREV` / `NEXT ›` browse numeric source order, skip local trash, have no wrap, and use the normal PREVIEW open path.
- PREV/NEXT/Gallery navigation must never silently replace PROGRAM.
- adaptive quick tags remain bounded; never restore the permanent tag wall.
- Gallery supports INDEX ↑/↓, TITLE, FAMILY, GRID/LIST and adjustable GRID size.
- TRASH is exclusive and local-only.
- review notes persist in `user://creative_lab_reviews.cfg` and telemetry is first-class evidence.

## Rendering / creative-quality contracts

Read:
- `knowledge/cross-domain/VISUAL_FINISH_GATE.md`
- `knowledge/cross-domain/TEMPORAL_MOTION_QUALITY.md`
- `knowledge/cross-domain/ADAPTIVE_CREATIVE_DRAW.md`
- `knowledge/cross-domain/ORGANIC_COUPLING_AND_CONTROLS.md`
- `knowledge/cross-domain/creative_draw_space.json`

Pipeline:

`adaptive draw -> preference evidence -> prototype -> observe -> mutate -> art-direct -> visual-finish gate -> keep/reject`

Technical diversity is not artistic quality. Hidden coarse solvers are allowed; enlarged solver pixels are not final artwork. Avoid generic direct-clock wobble, visible phase-wrap/reset walls, shallow pointer overlays and parameters that merely change “amount”.

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
- do not invent review evidence.
- do not infer host FPS from stale telemetry.

## Required next host validation

1. Sync exact final HEAD and require exact-head CI before launch.
2. Confirm Gallery source count is **50**.
3. Review 046–050 sequentially with PREV/NEXT while ensuring PROGRAM stays untouched unless TAKE LIVE is pressed.
4. For each new sketch, watch defaults for ~20–30 s before touching controls; assess autonomous temporal life without generic clock motion.
5. Interact and release; require immediate readable response plus a persistent/delayed consequence.
6. Push every parameter through broad ranges; flag any parameter that seems ineffective or only changes intensity.
7. 046: opposing eddies should visibly steer/shear ink and persist through memory.
8. 047: aperture dragging plus density/angle/shear/lens extremes should create distinct interference regimes.
9. 048: visible response must remain filamentary/organic rather than revealing the solver grid; defects/flow/memory should be perceptible.
10. 049: verify heat vs quench depends on local state, and conduction/cooling/oxide-memory extremes are legible.
11. 050: drag poles, vary pole count/field parameters, and verify filings reorganize with hysteresis rather than stateless snapping.
12. Continue RATE numeric + WHY/NOTES normally; user should not repeat those notes in chat.
13. Close normally and inspect fresh `telemetry/runtime` first on the next turn. Verify session/runtime HEAD before attributing review or performance evidence.

## Mandatory AI completion protocol

After every material repository change: finish code -> push -> update durable docs/state -> resolve final remote HEAD **after all docs** -> wait/inspect CI for that exact SHA -> report exact short HEAD + exact CI -> automatically provide canonical PowerShell when host validation is useful -> after host test inspect telemetry first.
