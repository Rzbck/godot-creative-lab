# UI Architecture

No UI scene is implemented yet.

## Design-system rule

All Creative Lab application UI consumes the central design system documented in `docs/DESIGN_SYSTEM.md`.

Screens must not become independent styling islands.

The delivery layer is Godot's cascading `Theme` system, with Theme Type Variations for repeated visual roles and reusable components for repeated structure/behavior.

Avoid reusable visual values as per-node Theme Overrides.

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

Create a component when behavior, structure or an established repeated pattern justifies it. Do not build a speculative component library before real UI exists.

## Layout

Use Godot `Control` and `Container` systems.

Avoid normal UI layout based on hard-coded absolute coordinates.

Target eventual support for:

- resizable window;
- fullscreen;
- 1080p;
- high-DPI displays;
- multi-monitor operation.

## Theme

The project will eventually configure one project-wide application Theme.

The theme owns shared control appearance, typography, StyleBoxes and Theme Type Variations.

Visual roles are semantic, for example `PrimaryButton`, `GhostButton`, `HeadingLabel` or `CardPanel`.

A skin/theme swap must not require editing Gallery, Settings and other screens individually.

## Icons

Icons are centrally owned by the design system and referenced by semantic role.

Use one coherent icon family unless a specific product requirement justifies an exception.

The connected Supericons tool can be used during icon-selection work to search and preview a consistent set.

No icon family is selected during architecture phase.

## Typography

Font family, fallback chain, type scale and common text roles are centralized in the design system.

Individual screens do not define their own application-wide font sizes.

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

Use Godot native `Control` focus/navigation before considering custom navigation systems.

Focus appearance is part of the design system and must remain clearly visible.
