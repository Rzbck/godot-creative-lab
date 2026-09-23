# ADR 0002 — Feature-local resources

Status: ACCEPTED

## Decision

Resources stay near the feature that owns them.

Application UI assets live under `app/ui/`.

Sketch-specific assets live inside the sketch.

`shared/` receives a resource only after actual reuse exists.

## Consequences

- clearer ownership;
- easier deletion/movement of projects;
- fewer cross-project dependencies;
- no generic asset dumping ground.
