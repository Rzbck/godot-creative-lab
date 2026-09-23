# Project Structure

## Target

    app/
    ├── main/
    ├── core/
    ├── runtime/
    │   ├── sketch_player/
    │   ├── inputs/
    │   └── outputs/
    │       ├── window/
    │       ├── spout/
    │       └── ndi/
    ├── settings/
    └── ui/
        ├── screens/
        │   ├── gallery/
        │   ├── sketch/
        │   ├── settings/
        │   └── about/
        ├── components/
        │   ├── sketch_card/
        │   ├── top_bar/
        │   ├── setting_row/
        │   ├── dialogs/
        │   └── notifications/
        └── design_system/
            ├── tokens/
            ├── theme/
            │   └── generated/
            ├── components/
            ├── icons/
            └── fonts/

    sketches/

    shared/
    ├── shaders/
    ├── materials/
    ├── components/
    └── utilities/

    addons/
    scripts/
    docs/

## Naming

Use snake_case for Godot project paths.

Examples:

    gallery_screen.tscn
    sketch_definition.gd
    creative_lab_theme.tres

Future creative work directories use stable numeric prefixes:

    001_name
    002_name
    003_name

The numeric prefix provides stable identity/order.

The artistic title remains metadata.

## Ownership

`app/` owns Creative Lab itself.

`sketches/` owns creative works.

Sketch-specific content stays inside its sketch.

Application UI resources stay under `app/ui/`.

The application design system lives under `app/ui/design_system/` and is the single source of reusable UI styling decisions.

Only real reuse belongs under `shared/`.
