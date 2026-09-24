# HANDOFF — DataC0re Creative Lab

Canonical restart point for a new human or AI session.

**Always resolve current GitHub branch HEAD and CI before trusting recorded SHAs.** Repository state is authoritative; chat history is secondary.

Last material refresh: **2026-09-24**.

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

DC//LAB is a working Godot creative-coding workstation with:

- data-driven Gallery discovery from sketch `definition.json` files;
- real rendered thumbnails and hover-only animated previews;
- groups, tags and search;
- generated parameter inspector and per-sketch persistence;
- PREVIEW / PROGRAM separation;
- persistent PROGRAM while browsing elsewhere;
- `TAKE LIVE` replacement workflow;
- physical display selection;
- PROGRAM mouse/touch forwarding;
- linked PREVIEW/PROGRAM state synchronization;
- asynchronous sanitized telemetry on `telemetry/runtime`;
- versioned creative/design/cross-domain knowledge.

The logical design space is normally `1280×720`.

## Artwork / interface boundary

PROGRAM canvas is artwork-only.

Do not burn into the artwork:

- sketch title;
- sketch index/number;
- tags/category;
- debug metadata;
- project metadata;
- explanatory pseudo-curatorial captions that belong to the editor/Gallery.

Text is valid when it is genuinely part of the artwork.

## Current sketches

- `001_signal_field` — technical/regression reference.
- `002_liquid_type` — elastic typography with gesture-velocity memory.
- `003_chroma_lens` — typographic optical system with safe margins and quantized hierarchy.
- `004_gommage_type` — directional erosion/dust memory and reconstruction.
- `005_pressure_lattice` — internal path retained; visible artwork is **REGISTER TYPE**. Original **PRESSURE LATTICE** visual concept was rejected and must not be restored.
- `006_breath_score` — **BREATH SCORE**.
- `007_redaction_field` — **REDACTION FIELD**.
- `008_palimpsest` — **PALIMPSEST**.
- `009_chorus_drift` — **CHORUS DRIFT**.
- `010_fault_register` — **FAULT REGISTER**.

### Important correction for 006–010

A later pass (`6c20a094...`) attempted to make all five more autonomous and structural by applying glyph-contour deformation broadly.

That pass was **host-rejected** and must not be restored as the default direction.

Failures observed by the user:

- several glyph-contour renderings appeared inverted / visually wrong;
- contours were used as the answer to nearly every piece;
- the five works became technically/aesthetically more similar instead of more diverse;
- one feedback point (`work more deeply with letter structure`) was over-applied and replaced the wider creative problem;
- the result was worse than the previous host-tested version.

The rollback beginning at `3a437fe...` restores the earlier 006–010 behavior while keeping project title/number/presentation chrome out of the canvas through thin wrappers where needed.

The shared glyph-contour helper may remain in the codebase as **one optional technique**. Do not infer that DC//LAB should use contours by default.

## Creative research system

Use all three roots:

- `knowledge/creative-coding/`
- `knowledge/design/`
- `knowledge/cross-domain/`

### Mandatory current read order for substantial creative work

1. `knowledge/cross-domain/TECHNIQUE_PALETTE.md`
2. `knowledge/cross-domain/CROSS_DOMAIN_ATLAS.md`
3. `knowledge/cross-domain/IDEA_ENGINE.md`
4. relevant technical/design atlases
5. `knowledge/design/DESIGN_REVIEW_CHECKLIST.md`

`LIVING_SYSTEMS.md` and `STRUCTURAL_TYPOGRAPHY.md` are specialist bricks, not universal requirements.

## Technique-selection rule

Do not choose the renderer/technique first.

Start from:

1. artistic intention;
2. carrier/material;
3. desired behavior;
4. interaction consequence;
5. temporal model;
6. composition/design system.

Then compare at least **three plausible technical chains** before implementation.

Available families include, among others:

- direct/variable typography and layout systems;
- whole-glyph and per-glyph transforms;
- vector contours / sampled points;
- raster masks and morphology;
- SDF/MSDF;
- fragment shaders / UV systems;
- temporal feedback buffers;
- particle and agent systems;
- vector fields / advection;
- physical constraints / springs;
- cellular automata / reaction-diffusion / diffusion systems;
- procedural geometry / meshes / instancing;
- graph/grid/topology systems;
- data/semantic state machines;
- audio/multitouch/external drivers.

The concept chooses the representation. The most recently added technique does not.

### Diversity rule for a series

When building several artworks:

- no more than two should share the same primary representation;
- no more than two should share the same primary temporal model;
- interaction consequences should materially differ;
- palette/text changes alone do not count as diversity;
- if five works could be made by changing text/colors/cursor mapping in one renderer, the series has failed.

## PROGRAM / LIVE OUT architecture

Expected workflow:

1. Open project in editor/PREVIEW.
2. Send to PROGRAM / LIVE OUT.
3. Browse elsewhere while PROGRAM keeps running.
4. Open another project in PREVIEW.
5. `TAKE LIVE` replaces PROGRAM.

Navigation is not transport.

When linked, editor simulation is authoritative and PROGRAM follows synchronized state. When navigating away, PROGRAM detaches and continues from its last synchronized state.

Inspect `res://app/main/main_runtime.tscn` and the actual `extends` chain before touching Gallery/PROGRAM/window/telemetry behavior.

## Touch / telemetry

PROGRAM mouse/touch mapping into the shared design space is established infrastructure.

After any host runtime test:

1. inspect branch `telemetry/runtime` first;
2. read `latest.jsonl` and relevant session data;
3. do not ask the user for copied logs until telemetry has been checked.

If telemetry does not correspond to the tested HEAD/session, say so rather than inferring results.

## Rejected regressions

Do not casually reintroduce:

- root-window fullscreen as the normal output mechanism;
- the previously failed secondary-window texture sampling path;
- synchronous telemetry Git/network work on the UI thread;
- independent linked PREVIEW and PROGRAM simulations;
- Gallery overlays that cover preview cards;
- fake Spout/NDI support;
- Pressure Lattice;
- project metadata burned into artwork;
- glyph contours as the default creative solution.

## CI / validation

Workflow: `.github/workflows/ci.yml`

Required gates for runtime/code changes:

- repository policy;
- Godot 4.7.1 setup/version;
- headless import;
- main-scene smoke test;
- tracked-file cleanliness.

Do not call runtime work complete until CI for the exact current HEAD is green.

## Immediate creative next step

Do **not** immediately generate another batch of five pieces.

First perform a serious creative/technical gap analysis of sketches 001–010:

- primary representation;
- temporal model;
- interaction consequence;
- typography/design system;
- shader/simulation/material mechanism;
- autonomous behavior;
- visual strengths/failures;
- overrepresented technique families;
- missing technique families.

Then research the missing families and expand the knowledge library before the next major art direction.

See `docs/handoff/CURRENT_WORK.md` for the newest concise state and `docs/handoff/NEXT_AI_PROMPT.md` for the fresh-session bootstrap.