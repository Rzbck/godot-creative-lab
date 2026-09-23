# Settings Architecture

No Settings implementation or Autoload exists yet.

## Project configuration

Versioned in:

    project.godot

Examples:

- renderer;
- startup defaults;
- project identity;
- InputMap defaults;
- engine configuration.

`project.godot` follows ADR 0004.

## User preferences

Future user preferences belong under:

    user://

Expected file:

    user://settings.cfg

Likely storage mechanism:

    ConfigFile

Possible preferences:

- window/fullscreen state;
- monitor;
- VSync;
- target FPS;
- creative render resolution;
- debug UI;
- Spout enabled/name;
- NDI enabled/name;
- audio/input preferences.

## Defaults

Application defaults remain versioned.

User preferences override those defaults.

Invalid or missing user values must safely fall back to defaults.

## Autoload policy

Persistent settings may eventually become an Autoload because the service has application-wide lifetime.

That decision is not implemented yet.
