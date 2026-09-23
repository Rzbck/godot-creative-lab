# UI Architecture

No UI scene is implemented yet.

## Future screens

### Gallery

Responsibilities:

- discover projects;
- display cards/thumbnails;
- search;
- filtering;
- launch a selected creative work.

The Gallery must not run every heavy sketch in the background.

### Sketch

Responsibilities:

- host the active creative preview;
- expose Creative Lab controls;
- provide access to output/runtime controls.

The application's controls remain separate from the clean creative render.

### Settings

Planned categories:

- General;
- Display / Rendering;
- Outputs;
- Audio;
- Inputs;
- Advanced / Debug.

### About

Application information and third-party notices/licenses.

## Components

Expected reusable UI components:

- SketchCard;
- TopBar;
- SettingRow;
- Dialog;
- Notification.

Do not implement these before they are needed.

## Layout

Use Godot Control and Container systems.

Avoid normal UI layout based on hard-coded absolute coordinates.

Target eventual support for:

- resizable window;
- fullscreen;
- 1080p;
- high-DPI displays;
- multi-monitor operation.

## Theme

Creative Lab will use a central Godot Theme resource.

Avoid styling every node independently.

Future icons should come from a coherent icon family.

Supericons can be used during UI implementation to select and preview a consistent set.

No icons are selected during architecture phase.

## Input actions

Future semantic InputMap actions may include:

    app_back
    app_gallery
    app_settings

    toggle_fullscreen
    toggle_debug

    sketch_reload
    sketch_pause

    capture_frame

Physical keyboard/gamepad bindings must not be scattered through application logic.

## Focus

Use Godot native Control focus/navigation before considering custom navigation systems.
