# ADR 0003 — Minimal global state

Status: ACCEPTED

## Decision

Prefer:

- normal node ownership;
- explicit references;
- signals.

Do not create Manager-style Autoloads by default.

A system becomes an Autoload only when its lifetime and responsibility are genuinely application-global.

Persistent Settings are a possible future candidate.
