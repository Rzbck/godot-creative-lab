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

## Architecture direction

Gallery
-> Sketch
-> central render target / SubViewport
-> display output
-> optional Spout adapter
-> optional NDI adapter

Sketches must remain usable without NDI or Spout installed.

## Current state

BOOTSTRAP ONLY.

No sketch is validated yet.

Godot 4.7.1 stable is HOST_VALIDATED on this machine.

Spout is planned but not installed.

NDI is planned but not installed.

No renderer choice has yet been locked.

## NEXT

1. Locate the installed Godot executable.
2. Confirm the exact Godot version.
3. Use stable Godot rather than a development snapshot.
4. Open this repository as a Godot project.
5. Build the smallest possible gallery shell.
6. Build sketch 001 while learning Nodes, Scenes, GDScript and _process(delta).
7. Only after the core render architecture is stable, integrate Spout.
8. Then integrate NDI.

## Validation status

HOST_VALIDATED:
- none yet.

REPO_VALIDATED:
- initial repository identity only.

IMPLEMENTED_NOT_VALIDATED:
- repository scaffold.

EXPERIMENTAL:
- Spout/NDI architecture until tested.

BLOCKER:
- installed Godot executable/version not yet located.


## project.godot editor policy

Godot 4.7.1 normalized `project.godot` on first editor launch.

Validated normalization:
- standard Godot configuration-file header;
- `config/features=PackedStringArray("4.7")`;
- existing display settings preserved.

Future sessions must use `scripts/preflight.ps1`.

A `project.godot`-only dirty state is `REVIEW_REQUIRED`, not an automatic blocker.
