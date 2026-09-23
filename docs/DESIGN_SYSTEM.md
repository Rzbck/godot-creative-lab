# Design System — DataC0re Creative Lab

## Status

Architecture only.

No visual skin, font family, icon family, component scene or final color palette is selected yet.

The goal is to make the whole application reskinnable from a small number of centralized sources instead of editing individual screens.

## Research basis

Godot's UI is built around `Control` nodes and layout `Container` nodes. Its `Theme` system cascades through the UI tree and can be configured project-wide.

Godot also supports Theme Type Variations so reusable visual roles can extend built-in control types without duplicating per-node overrides.

Relevant Godot documentation:

- https://docs.godotengine.org/en/4.7/tutorials/ui/index.html
- https://docs.godotengine.org/en/4.7/tutorials/ui/gui_skinning.html
- https://docs.godotengine.org/en/4.7/tutorials/ui/gui_theme_type_variations.html
- https://docs.godotengine.org/en/4.7/tutorials/ui/gui_using_theme_editor.html

A possible authoring tool is ThemeGen:

- https://github.com/Inspiaaa/ThemeGen
- current researched release: `v1.4.0`
- license: MIT
- upstream README targets Godot 4.x and provides programmatic theme generation plus live preview

ThemeGen is a candidate only. It must not be installed until it is validated against this project's pinned Godot 4.7.1 workflow.

## Core rule

Application screens and components consume the design system.

They do not define their own visual language.

Avoid scattered node-level Theme Overrides for reusable styles.

A one-off override is allowed only when the value is genuinely local and cannot reasonably be expressed through a token, Theme item, Theme Type Variation or reusable component.

## Source-of-truth layers

Future target:

    Design tokens
         |
         v
    Theme authoring source
         |
         v
    Generated / canonical Godot Theme
         |
         +--> Theme Type Variations
         |
         +--> reusable UI components
         |
         +--> Gallery / Settings / Sketch UI / About

The runtime artifact remains a normal Godot `Theme` resource.

The project-wide application theme should eventually be configured through Godot Project Settings so normal controls inherit it automatically.

## Directory model

    app/ui/design_system/
    ├── tokens/
    ├── theme/
    │   └── generated/
    ├── components/
    ├── icons/
    └── fonts/

### tokens

Semantic design values and scales.

### theme

Theme authoring source and the canonical/generated Godot Theme resource.

### components

Reusable UI building blocks whose behavior/layout is stable enough to share.

### icons

Application icon assets plus a central icon registry/semantic mapping.

### fonts

Application-owned font resources and fallback configuration.

## Token categories

Values are intentionally not chosen yet. The first visual direction will define them.

### Color

Use semantic names rather than screen-specific names.

Examples:

    background_canvas
    background_surface
    background_elevated

    text_primary
    text_secondary
    text_muted
    text_on_accent

    accent_primary
    accent_hover
    accent_pressed

    border_default
    border_subtle
    border_focus

    state_success
    state_warning
    state_danger

    overlay_scrim

A screen must not invent `gallery_blue`, `settings_gray`, etc. when the meaning is actually global.

### Typography

Centralize at least:

    font_family_ui
    font_family_mono

    text_display
    text_title
    text_heading
    text_body
    text_body_small
    text_caption

Each role eventually defines size, weight and line-height policy.

Changing the application type scale must not require opening individual scenes.

### Spacing

Use one spacing scale for margins, gaps and component padding.

Example semantic scale:

    space_1
    space_2
    space_3
    space_4
    space_5
    space_6
    space_8
    space_10

Exact pixel values are intentionally deferred.

### Radius

    radius_none
    radius_small
    radius_medium
    radius_large
    radius_pill

### Borders

    border_width_default
    border_width_focus

### Sizing

    control_height_small
    control_height_medium
    control_height_large

    icon_size_small
    icon_size_medium
    icon_size_large

Application layout constants that prove to be global can also live here.

### Motion

    motion_fast
    motion_normal
    motion_slow

    easing_standard
    easing_emphasized

Motion remains optional and must support a future reduced-motion mode where relevant.

### Density

Keep room for density variants such as:

- compact;
- comfortable.

Do not hardwire every component to a single control height if a global density system becomes useful.

## Godot Theme policy

Use the Godot Theme system as the visual delivery layer.

Prefer:

1. project-wide Theme defaults;
2. built-in Theme types;
3. Theme Type Variations;
4. reusable component scenes/scripts only when behavior or structure is also reusable;
5. local overrides only as a last resort.

## Planned Theme Type Variations

Names are architectural examples, not implemented types.

### Buttons

    PrimaryButton
    SecondaryButton
    GhostButton
    DangerButton
    IconButton
    ToolbarButton

### Labels

    DisplayLabel
    TitleLabel
    HeadingLabel
    BodyLabel
    CaptionLabel
    MutedLabel

### Containers / panels

    SurfacePanel
    ElevatedPanel
    CardPanel
    ToolbarPanel

### Inputs

    StandardLineEdit
    SearchLineEdit

Do not create a variation merely because one node looks slightly different. Variations represent repeated visual roles.

## Component policy

A component exists when at least one of these is true:

- it has reusable behavior;
- it has reusable structure;
- it combines several controls into one stable product pattern;
- it is used in multiple screens.

Likely future components include:

- SketchCard;
- TopBar;
- SettingRow;
- Dialog;
- Notification;
- SearchField;
- SectionHeader.

Components still inherit colors, fonts, spacing and control styling from the design system.

## Icon system

Icons must use one coherent family unless a specific product requirement justifies an exception.

The connected Supericons tool can be used to search and preview a consistent set when icon selection begins.

Application code should eventually request icons by semantic role, for example:

    settings
    search
    back
    fullscreen
    close
    play
    pause
    reload
    output
    audio
    midi
    camera

Screens should not scatter raw SVG paths throughout scripts.

## Font system

Font choice is centralized.

Requirements before shipping a font:

- license compatible with public redistribution;
- readable at UI sizes;
- appropriate glyph coverage;
- fallback strategy documented.

Do not duplicate font files per screen or component.

## Skins / theme variants

The architecture must allow swapping the application skin without rewriting UI scenes.

Possible future variants:

- default dark;
- light;
- high-contrast;
- project/show-specific skin.

A skin can change visual tokens and Theme resources while preserving semantic component roles.

## Accessibility hooks

The design system should make future accessibility changes global rather than screen-specific.

Plan for:

- text scaling;
- keyboard focus visibility;
- sufficient contrast;
- reduced motion where applicable;
- high-contrast theme variant.

No accessibility values are locked during this architecture phase.

## Anti-patterns

Avoid:

- arbitrary colors directly inside screen scripts;
- arbitrary font sizes per Label;
- repeated StyleBox definitions in many scenes;
- hundreds of Theme Overrides;
- icon SVG paths scattered through business logic;
- screen-specific spacing systems;
- duplicated fonts;
- a component library that is built speculatively before real UI exists.

## Tooling decision still open

Two valid implementation paths remain:

### Native-only

Use Godot Theme resources and Theme editor directly, with project-owned token/helper code where needed.

### ThemeGen-assisted

Use ThemeGen as an authoring/generation tool, producing normal Godot Theme resources.

Before choosing ThemeGen we must verify:

- compatibility with Godot 4.7.1;
- headless/CI behavior;
- deterministic generated output;
- no unwanted editor-only runtime dependency;
- exact vendoring/update policy.

The design-system architecture does not depend on ThemeGen being selected.
