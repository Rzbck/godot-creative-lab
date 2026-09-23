# Output Architecture

No output plugin is installed yet.

## Pipeline

Future conceptual pipeline:

    Sketch
      |
      v
    Creative Render
      |
      +--> Preview
      +--> Window
      +--> Spout
      +--> NDI
      +--> future Capture / Recorder

## Output Hub

The future Output Hub coordinates transports.

It does not implement artistic rendering.

## Window

Native local output and fallback.

Must work without any external extension.

## Spout

Optional Windows GPU texture sharing.

Before implementation verify:

- Godot version support;
- Forward+ / renderer requirements;
- extension source;
- pinned version;
- license;
- binary provenance;
- graceful fallback.

## NDI

Optional network video output.

Before implementation verify:

- Godot compatibility;
- native runtime requirements;
- SDK/runtime requirements;
- source;
- pinned version;
- license/redistribution conditions;
- graceful fallback.

## Rule

A creative sketch never directly imports or controls Spout/NDI.

Creative Lab controls transport.
