# Architecture — DataC0re Creative Lab

## Status

Architecture only.

No Godot scene and no creative sketch have been implemented yet.

The user decides the first creative work before any sketch scene is created.

## Product model

Creative Lab is composed of two deliberately separate worlds:

1. the Creative Lab application;
2. the creative works hosted by it.

Application:

    app/

Creative works:

    sketches/

Reusable resources proven to be shared:

    shared/

Third-party Godot extensions:

    addons/

## Future application model

    Main
    |
    +-- Navigation / Screen Host
    |
    +-- Application UI
    |     |
    |     +-- Gallery
    |     +-- Sketch UI
    |     +-- Settings
    |     +-- About
    |
    +-- Sketch Player
    |     |
    |     +-- Active Sketch
    |     +-- Creative Render Target
    |
    +-- Output Hub
          |
          +-- Window
          +-- Spout
          +-- NDI
          +-- future outputs

This is a responsibility model, not an implemented SceneTree.

## Fundamental rules

### Feature-local ownership

A feature owns its resources.

A future creative work keeps its own:

- scripts;
- scenes;
- shaders;
- materials;
- textures;
- media;
- metadata;
- thumbnail.

Do not create a generic root assets dumping ground.

### Sketch isolation

A sketch must not directly control:

- Gallery;
- Settings;
- navigation;
- Spout lifecycle;
- NDI lifecycle;
- another sketch.

The application hosts creative works.

Creative works do not own the application.

### One creative render boundary

The clean creative image is separate from application UI.

Future model:

    Active Sketch
         |
         v
    Creative Render
         |
         +--> UI preview
         +--> clean window
         +--> Spout
         +--> NDI
         +--> capture/recording

Application chrome must never leak into professional outputs.

### Optional outputs

Spout and NDI are adapters.

Their absence must not prevent:

- opening the project;
- running Creative Lab;
- opening a sketch;
- rendering locally.

### Minimal global state

Normal scene ownership and signals are preferred.

Autoload is used only for genuinely application-global lifetime services.

Persistent settings are a possible future candidate.

No Autoload is implemented yet.

## Responsibilities

### app/main

Future composition root.

Connects high-level systems.

Must remain small.

### app/core

Non-visual application contracts and models.

Possible future concepts:

- SketchDefinition;
- sketch catalog;
- capability definitions;
- application constants.

### app/runtime

Execution systems:

- sketch hosting;
- render hosting;
- application inputs;
- outputs.

### app/settings

Persistent user preferences and versioned defaults.

### app/ui

Application UI only.

Contains:

- screens;
- components;
- Theme;
- application-owned icons/fonts/assets.

### sketches

Independent creative projects.

### shared

Resources that have demonstrated reuse.

Do not promote something into shared pre-emptively.

### addons

Third-party Godot plugins/extensions.

Each dependency must have documented source, version and license.

## Validation vocabulary

Keep distinct:

- architecture decided;
- implemented;
- runtime validated;
- user visually validated.
