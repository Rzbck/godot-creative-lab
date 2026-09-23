# Sketch Contract

No creative work is implemented yet.

The exact contract must remain small until the first real creative project gives us concrete requirements.

## Intended ownership

Example only:

    sketches/
    └── 001_example/
        ├── sketch.tscn
        ├── sketch.gd
        ├── sketch_info.tres
        ├── thumbnail.webp
        ├── shaders/
        ├── materials/
        └── assets/

Not every sketch must contain every directory.

## Expected metadata concepts

A future SketchDefinition may eventually describe:

- stable id;
- title;
- description;
- tags;
- scene reference;
- thumbnail;
- preferred resolution;
- preferred frame rate;
- capabilities.

Possible capabilities:

- 2D;
- 3D;
- audio;
- microphone;
- camera;
- MIDI;
- OSC;
- compute/GPU.

Do not lock this Resource schema before the first real sketch.

## Isolation

One heavy interactive sketch is active by default.

Gallery thumbnails do not require every creative project to execute.

## Boundary

A sketch renders creative content.

It does not own:

- application navigation;
- settings UI;
- Gallery;
- Spout;
- NDI.

Transport/output concerns belong to Creative Lab.
