# Prompt for the next AI session

Copy/paste the block below into a new AI conversation that has access to the GitHub repository.

---

You are taking over the ongoing project **DC//LAB / Godot Creative Lab**.

Repository:
`Rzbck/godot-creative-lab`

Do **not** rely on previous-chat memory. Reconstruct current state from repository/GitHub evidence.

## Mandatory startup procedure

1. Resolve the current remote HEAD of branch `feat/creative-sketches-002-004-20260924` and inspect draft PR #7.
2. Read, in this order:
   - `AGENTS.md`
   - `HANDOFF.md`
   - `docs/handoff/CURRENT_WORK.md`
   - `docs/handoff/OPERATIONS.md`
   - `docs/handoff/project_state.json`
   - `docs/ARCHITECTURE.md`
3. Inspect `app/main/main_runtime.tscn` and follow the actual `extends` chain before changing Gallery/PROGRAM/window/telemetry behavior.
4. Inspect the exact sketch/runtime files involved in the user's next request.
5. For creative/design work, read the relevant material under:
   - `knowledge/creative-coding/`
   - `knowledge/design/`
   - `knowledge/cross-domain/`
6. For substantial realtime artwork specifically read/use:
   - `knowledge/design/DESIGN_REVIEW_CHECKLIST.md`
   - `knowledge/design/STRUCTURAL_TYPOGRAPHY.md` when type anatomy/letter deformation matters
   - `knowledge/cross-domain/CROSS_DOMAIN_ATLAS.md`
   - `knowledge/cross-domain/IDEA_ENGINE.md`
   - `knowledge/cross-domain/LIVING_SYSTEMS.md`
7. Resolve current CI before assuming branch health.
8. If the user's message follows a runtime test, inspect `telemetry/runtime` before requesting copied logs. Verify telemetry runtime Git head matches the tested branch version; stale telemetry is not evidence for a newer test.

## Operating rules

- Work directly through GitHub on the active feature branch.
- User should not have to write code manually.
- Never merge or modify `main` without explicit user approval.
- Do not force-push/reset as routine recovery.
- After runtime/code changes verify repository policy + Godot 4.7.1 import + smoke test + tracked-file cleanliness for exact HEAD.
- For host validation give one concise copy/paste PowerShell `& { ... }` block using `docs/handoff/OPERATIONS.md`.
- Respond in concise French; answer intent rather than correcting spelling.
- Prefer concrete implementation/progress over generic explanation.

## Product behaviors that must not regress

- Workstation remains usable while PROGRAM/LIVE OUT runs on selected physical display.
- Navigation does not stop PROGRAM.
- Another PREVIEW replaces PROGRAM only via `TAKE LIVE`.
- PROGRAM touch/mouse controls the live sketch.
- Linked PREVIEW/PROGRAM share one generative state/timeline.
- Per-sketch parameters persist.
- Gallery uses real rendered thumbnails and hover-only animation.
- Gallery groups/search/tag filters come from `definition.json`.
- Telemetry publication remains asynchronous.

## Artwork rules that must not regress

- **The full PROGRAM canvas is the artwork.** Sketch title, index/number, tags, debug/project metadata and fake curatorial captions belong in Gallery/editor UI, not inside final artwork.
- Do not draw an inset poster/card frame by default; framing must be conceptually necessary.
- A realtime work should normally have meaningful autonomous behavior before user input.
- Avoid the default `click -> effect on / release -> effect off` pattern. Interaction should perturb internal state and allow propagation, memory, repair, coupling or regime change when appropriate.
- If the concept claims internal typographic deformation, use a representation deep enough to reach glyph anatomy (vector contours, sampled points, SDF/MSDF, etc.), not merely whole-glyph position/scale.
- Default values must already produce a coherent piece. Sliders should bias system behavior rather than rescue weak visuals.

## Shared structural typography support

The repo now contains:

- `sketches/_shared/glyph_contour_tools.gd`
- contour helpers in `sketches/_shared/design_sketch_base.gd`

These use Godot `TextServer.font_get_glyph_contours()` to access/sample real font outlines for structural deformation experiments.

## Current content / direction

Existing sketches now run 001–010.

- 001 Signal Field — technical/regression patch.
- 002 Liquid Type.
- 003 Chroma Lens.
- 004 Gommage Type.
- 005 internal id/path `005_pressure_lattice`, visible **REGISTER TYPE**. Original Pressure Lattice concept was rejected; do not restore it.
- 006 **BREATH SCORE** — autonomous contour breathing + local touch pressure.
- 007 **REDACTION FIELD** — autonomous per-character censorship; glyph contours collapse into censorship material; local touch editing + memory.
- 008 **PALIMPSEST** — autonomous sediment/archive strata; gesture-depth excavation and contour-layer memory.
- 009 **CHORUS DRIFT** — coupled oscillator population; autonomous voice emergence; interaction perturbs one row/neighbours; contour-level voice deformation.
- 010 **FAULT REGISTER** — autonomous small faults + user scars; per-contour-point fault-plane fracture inside glyphs.

The current creative direction is explicitly trying to escape shallow “interactive poster + slider” work and move toward studio-grade living systems, structural typography, meaningful temporal depth and richer interaction dramaturgy.

## Host-test method for the structural/autonomous pass

Do not begin by adjusting sliders.

For 006–010:

1. watch each untouched for ~30 seconds;
2. verify no title/index/project metadata is rendered into artwork;
3. judge autonomous behavior vs decorative looping;
4. make one slow gesture, stop touching, observe persistence/propagation/repair;
5. make one fast/long gesture and compare consequences;
6. inspect whether letter structures deform internally where intended;
7. test selected pieces in PROGRAM/touch;
8. then inspect fresh matching-head telemetry + visual feedback.

## First response behavior

After repository scan, briefly state:
- branch + short HEAD;
- PR/CI state;
- implemented product capabilities;
- stale/conflicting docs if any;
- exact task understood.

Then work. Do not ask the user to re-explain documented history.

---
