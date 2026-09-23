# HANDOFF — DataC0re Creative Lab

Canonical restart point for a new human or AI session.

Always re-check Git branch, HEAD and status before trusting this snapshot.

## Product

Godot creative-coding laboratory built around a gallery of independent real-time sketches.

Target capabilities include:
- 2D / 3D generative visuals;
- shaders;
- particles;
- feedback;
- audio reactivity;
- MIDI / OSC;
- cameras / video;
- procedural systems;
- Spout output;
- NDI output.

## Repository

GitHub:
Rzbck/godot-creative-lab

Local target:
E:\_Project\GodotCreativeLab

Default published branch:
main

Active architecture branch:
`chore/architecture-foundation-20260923`

## HOST_VALIDATED

- Godot `4.7.1.stable.official.a13da4feb`.
- Godot command available through the user PATH.
- Vulkan / Forward+ launches successfully on NVIDIA GeForce RTX 5080.
- Local repository policy validation passes.
- Local Godot headless import passes.

## Architecture direction

    Gallery
      -> Sketch Player
      -> central creative render boundary
      -> local preview/window
      -> optional Spout adapter
      -> optional NDI adapter

Sketches must remain usable without NDI or Spout installed.

## Accepted architecture decisions

- application code under `app/`;
- creative works under `sketches/`;
- feature-local resource ownership;
- genuinely reusable resources only under `shared/`;
- central clean creative render boundary;
- Window / Spout / NDI treated as output adapters;
- minimal Autoload/global state policy;
- future persistent settings stored under `user://`;
- central application UI design system;
- project-wide Godot Theme as the visual delivery layer;
- semantic tokens, Theme Type Variations and centralized icons/fonts.

Architecture references:

- `docs/ARCHITECTURE.md`
- `docs/PROJECT_STRUCTURE.md`
- `docs/UI_ARCHITECTURE.md`
- `docs/DESIGN_SYSTEM.md`
- `docs/SKETCH_CONTRACT.md`
- `docs/OUTPUT_ARCHITECTURE.md`
- `docs/SETTINGS_ARCHITECTURE.md`
- `docs/decisions/`

## UI design-system state

Architecture only.

No palette, font family, icon family, component scene or skin is selected yet.

ThemeGen `v1.4.0` has been researched as an MIT-licensed Godot 4.x programmatic theme-authoring candidate. It is not installed or adopted until a Godot 4.7.1 + CI compatibility spike passes.

The connected Supericons tool is available for coherent icon selection when UI visual implementation begins.

## project.godot editor policy

Godot 4.7.1 normalized `project.godot` on first editor launch.

Validated normalization:
- standard Godot configuration-file header;
- `config/features=PackedStringArray("4.7")`;
- existing display settings preserved.

Future sessions must use `scripts/preflight.ps1`.

A `project.godot`-only dirty state is `REVIEW_REQUIRED`, not an automatic blocker.

## Automation foundation

Local validation entry point:

`scripts/check.ps1`

GitHub workflow:

`.github/workflows/ci.yml`

Current CI targets:

- repository policy;
- Godot 4.7.1 headless import;
- tracked-file cleanliness after Godot import.

Dependabot is configured for GitHub Actions updates.

No export/build/release pipeline exists yet.

## Current intentional state

- no `.tscn`;
- no Gallery implementation;
- no Settings implementation;
- no sketch implementation;
- no Spout;
- no NDI;
- no Autoload;
- no icon assets;
- no font assets;
- no Theme resource yet.

## Validation vocabulary

HOST_VALIDATED:
- Godot 4.7.1 runtime/editor and local headless import.

REPO_VALIDATED:
- repository architecture and local CI policy.

IMPLEMENTED_NOT_VALIDATED:
- GitHub Actions remote CI until first PR run completes.

EXPERIMENTAL:
- ThemeGen candidate until compatibility spike.

BLOCKER:
- none for architecture work.

## NEXT

1. Open/refresh the architecture PR and let GitHub Actions validate the remote branch.
2. Keep architecture scene-free.
3. Decide the first implementation target before creating any `.tscn`.
4. Before UI implementation, validate the design-system authoring path (native Godot Theme vs ThemeGen-assisted).
