# HANDOFF — DataC0re Creative Lab

Canonical restart point for a new human or AI session.

**Always resolve the current GitHub branch HEAD and CI before trusting any recorded SHA.** The repository is the source of continuity; chat history is secondary.

Last material handoff refresh: **2026-09-24**.

## Repository / active work

- GitHub: `Rzbck/godot-creative-lab`
- Local workstation: `E:\_Project\GodotCreativeLab`
- Godot GUI: `C:\Godot\Godot_v4.7.1-stable_win64.exe`
- Godot console: `C:\Godot\Godot_v4.7.1-stable_win64_console.exe`
- Engine: Godot `4.7.1.stable.official.a13da4feb`
- Renderer validated on host: Vulkan / Forward+ / NVIDIA GeForce RTX 5080
- Active branch: `feat/creative-sketches-002-004-20260924`
- Draft PR: `#7`, base `feat/gallery-project-workflow-20260923`
- `main` must not be merged/changed without explicit user approval.

## Product state

DC//LAB is a functioning Godot creative-coding workstation with:

- Gallery discovery from sketch `definition.json` files;
- real rendered thumbnails and hover-only animated previews;
- automatic groups, tag filters and search;
- generated parameter inspector and per-sketch persistence;
- PREVIEW / PROGRAM separation;
- persistent physical PROGRAM output while the workstation remains usable;
- `TAKE LIVE` replacement workflow;
- mouse/touch forwarded from the PROGRAM screen;
- linked PREVIEW/PROGRAM live-state synchronization;
- sanitized asynchronous telemetry on `telemetry/runtime`;
- versioned creative-coding, design/typography and cross-domain knowledge libraries.

## Current sketches

### 001 — SIGNAL FIELD

Technical/regression patch for the sketch contract. Keep it as a foundation reference rather than forcing it into the artistic direction.

### 002 — LIQUID TYPE

Elastic typography. Gesture velocity now affects temporal energy, spacing, tangential response, smear and chromatic direction instead of behaving only like a radial pointer effect.

### 003 — CHROMA LENS

Typographic optical field. Safe margins remain explicit. Stable cell hierarchy, quantized lens states and editorial grid logic reinforce the composition.

### 004 — GOMMAGE TYPE

Erase/rebuild typography. Erosion marks store gesture direction so erase regions, dust and traces inherit authored motion before reconstruction.

### 005 — REGISTER TYPE

The original **PRESSURE LATTICE** concept was rejected by the user as visually weak and insufficiently rigorous. Do not restore it.

The accepted replacement direction is **REGISTER TYPE** while keeping the existing internal folder path `sketches/005_pressure_lattice/` for compatibility.

Concept chain:

`editorial hierarchy -> typographic metrics -> local compression/tracking behavior -> physical print misregistration -> damped recovery`

Core design rules:

- stable poster state at rest;
- 1280×720 logical design space with explicit safe rectangle;
- six-column editorial structure;
- asymmetric three-line hierarchy: `FORM`, `PRESS`, `TRACE`;
- limited paper/dark-ink + two registration-ink palette;
- typography is the dominant carrier, not shader texture;
- interaction only affects the typographic row actually touched;
- press creates local compression/pressure;
- drag velocity sets the registration direction and contributes energy;
- release returns through a damped spring state;
- shader provides paper grain, structural grid, local halftone/registration behavior and supports the typographic interaction rather than replacing it.

Implementation:

- scene: `res://sketches/005_pressure_lattice/runtime/pressure_lattice.tscn`;
- runtime: `pressure_lattice.gd`;
- shader: `pressure_lattice.gdshader`;
- custom row energy, anchor and gesture direction are included in live-sync state;
- artistic parameters: type scale, tracking, pressure, registration, recovery, print grain, grid presence and ink palette.

Gallery taxonomy was simplified for the artistic sketches. Avoid pseudo-technical tags such as `TYPE`, `RGB`, `SHADER`, `LIVE` as category noise. Current intent is human-readable concepts such as `TYPOGRAPHY + ELASTIC/OPTICAL/EROSION/PRINT + INTERACTIVE`.

The replacement is `REPO_VALIDATED` when its latest exact-head CI is green, but its tactile/visual quality still requires host review before `HOST_VALIDATED`.

## PROGRAM / LIVE OUT architecture — preserve

PREVIEW/EDITOR and PROGRAM are separate responsibilities.

Expected workflow:

1. Open a project in editor.
2. Send it to PROGRAM / LIVE OUT on a selected display.
3. Return to Gallery or Settings; PROGRAM keeps running.
4. Open another project in PREVIEW.
5. Press `TAKE LIVE`; PREVIEW replaces PROGRAM.

Navigation is not transport.

When editor and PROGRAM are linked to the same project, editor simulation is authoritative and PROGRAM follows its runtime state. When the user navigates away, PROGRAM detaches and continues from the last synchronized state.

The active runtime scene is `res://app/main/main_runtime.tscn`. Follow its actual script `extends` chain before changing Gallery/PROGRAM/window/telemetry behavior.

## Input / touch

The shared physical-touch PROGRAM path is HOST_VALIDATED. Touch/drag/mouse events are mapped into the same 1280×720 logical sketch space used by preview.

New sketch-specific interaction still requires a host pass. After a user runtime test, inspect `telemetry/runtime` before asking for copied logs.

## Gallery / persistence

Gallery is data-driven from `definition.json` metadata. First tag is the automatic primary group; all tags become filters. Keep taxonomy small and meaningful.

Sketch parameters persist under `user://creative_lab_sketch_settings.cfg`. Gallery thumbnails receive saved values so the visual library reflects configured versions.

## Telemetry

Local runtime telemetry: `res://.telemetry_runtime/`.

Sanitized online telemetry:

- branch: `telemetry/runtime`
- rolling latest: `latest.jsonl`
- historical sessions: `sessions/`

Publication is asynchronous/queued. Do not put Git/network work on the Godot main thread.

Telemetry has been used for window state, output geometry, render probes, resize issues, display selection, PROGRAM state, touch forwarding and live-sync debugging.

## Rejected architectural regressions

Do not casually reintroduce:

- workstation root-window fullscreen as the normal output path;
- secondary native window sampling the workstation SubViewport texture on the previously failing host path;
- synchronous/concurrent telemetry Git pushes on the UI thread;
- independent linked PREVIEW and PROGRAM simulations;
- Gallery overlays/tooltips that obscure preview cards;
- fake Spout/NDI support.

## Knowledge system

Use all three layers for substantial creative work:

- `knowledge/creative-coding/` — shaders, fields, simulation, feedback, particles, procedural/GPU techniques;
- `knowledge/design/` — typography, grids, hierarchy, margins, color, motion and review criteria;
- `knowledge/cross-domain/` — representation bridges and mutation/idea engine.

Before a new substantial artwork:

1. define the frozen-frame composition and identity invariants;
2. choose at least one genuine representation bridge;
3. combine multiple domains only when they affect each other structurally;
4. mutate the first coherent idea rather than implementing it immediately;
5. define interaction causality, recovery/idle behavior and safe-area rules;
6. choose the cheapest Godot-native representation that preserves the concept;
7. validate with `knowledge/design/DESIGN_REVIEW_CHECKLIST.md`.

Do not copy one reference's visual surface or stack unrelated effects.

## CI / validation

Workflow: `.github/workflows/ci.yml`

Required gates:

- repository policy;
- Godot 4.7.1 setup/version;
- headless import;
- main-scene smoke test;
- tracked-file cleanliness.

Local equivalent: `scripts/check.ps1`.

Do not call runtime/code work finished until CI for the exact current HEAD is green.

## Communication / operations

- concise French preferred;
- user should not need to write code manually;
- work directly on the active feature branch;
- never merge `main` without explicit approval;
- when host validation is needed, provide one compact PowerShell `& { ... }` block using `docs/handoff/OPERATIONS.md`;
- inspect online telemetry before asking the user for logs.

## CURRENT WORK / NEXT

1. Host-test the redesigned 005 REGISTER TYPE in Gallery, PREVIEW and PROGRAM/touch.
2. Evaluate frozen-frame composition, type hierarchy, edge behavior, press/drag/release causality and recovery.
3. After the host test, inspect `telemetry/runtime` and refine with evidence plus user visual feedback.
4. Keep 002–004 available for further design refinement, but preserve their individual identities.
5. Keep Gallery / PROGRAM / persistence / touch / telemetry stable.
6. Future A/B/C decks, mixer, timeline/cues, compositing, Spout and NDI remain separate explicit tasks.

For a fresh session, use `docs/handoff/NEXT_AI_PROMPT.md`.
