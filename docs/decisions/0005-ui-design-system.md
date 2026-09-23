# ADR 0005 — Central UI design system

Status: ACCEPTED

## Context

Creative Lab will contain multiple screens and reusable controls. Styling each node or screen independently would make later visual redesigns expensive and inconsistent.

Godot provides a cascading Theme system and Theme Type Variations intended for reusable control styling.

## Decision

All application UI will consume a central design system built around:

- semantic design tokens;
- one project-wide Godot Theme delivery layer;
- Theme Type Variations for repeated visual roles;
- reusable components for repeated structure/behavior;
- centralized icon and font ownership.

Reusable visual values must not be scattered as local Theme Overrides across screens.

## Consequences

Positive:

- global skin changes are cheap;
- typography can be changed centrally;
- icon family can be replaced centrally;
- color and spacing consistency improves;
- dark/light/high-contrast variants remain possible;
- future Gallery and Settings screens share one visual language.

Cost:

- design-system conventions must be established before large-scale UI implementation;
- arbitrary local overrides require more discipline.

## Tooling

The runtime contract is a normal Godot Theme.

ThemeGen `v1.4.0` is a researched MIT-licensed candidate for programmatic theme authoring and live preview, but is not yet adopted. A separate compatibility spike must validate it against Godot 4.7.1 and CI before installation.

## Non-decision

No palette, font, icon family, radius scale or final visual style is selected by this ADR.
