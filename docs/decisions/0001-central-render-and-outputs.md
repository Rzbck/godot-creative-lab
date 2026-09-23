# ADR 0001 — Central creative render and optional outputs

Status: ACCEPTED

## Decision

Creative content will eventually pass through one application-controlled render boundary.

Professional transports consume that render.

Sketches do not implement individual output transports.

## Why

This separates:

- artwork;
- application UI;
- output transport.

It also allows one creative render to feed multiple destinations.

## Not decided yet

The exact SceneTree implementation is intentionally deferred.

SubViewport / ViewportTexture are likely tools, but the architectural contract comes first.
