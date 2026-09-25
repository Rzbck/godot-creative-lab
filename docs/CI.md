# Continuous Integration

## Purpose

GitHub Actions is the remote validation layer for DC//LAB. It checks repository structure, temporal-quality failure modes, adaptive creative-draw diversity and the pinned Godot runtime.

## Repository policy

`scripts/ci/validate_repository.py` checks:

- required repository files;
- forbidden generated/local paths;
- large tracked files;
- project-owned naming policy;
- expected Godot identity/version;
- no obvious sketch index/title burn-in;
- full-canvas `ShaderSurface` contract.

A node named `ShaderSurface` must reference `res://sketches/_shared/full_canvas_surface.gd`; legacy fixed `offset_right = 1280` / `offset_bottom = 720` are rejected.

## Temporal-motion audit

`scripts/ci/audit_temporal_motion.py`

The audit reports direct clock trigonometry (`sin/cos` driven by `sketch_time`, `u_time` or shader `TIME`) and heuristic fixed-interval state branches.

Historical sketches <=025 are reported as observations so the existing catalogue can be refined with host/rating evidence instead of being blindly rewritten.

For index 026+:

- direct clock trigonometry fails CI unless the runtime file contains `TEMPORAL_INTENT:` explaining the conceptual/physical oscillator;
- `definition.json` must include a non-empty `creative_signature`.

The audit does not claim that a fixed simulation cadence is artistically bad. It surfaces patterns for review; only the narrow direct-clock/new-signature rules are hard gates.

## Adaptive creative-draw self-test

`scripts/creative/draw_recipe.py --self-test --seed 20260925`

CI draws 180 deterministic synthetic recipes and verifies:

- representation pairs come from different technical families;
- operator pairs come from different families;
- each draw stays sufficiently distant from recent implemented signatures;
- signature diversity does not collapse;
- forced oscillators do not dominate;
- one render path does not dominate the sample.

This validates the **selection system**, not the artistic quality of generated work. Host review and explicit ratings remain necessary.

## Godot headless

CI pins Godot `4.7.1`, then performs:

- version verification;
- headless import;
- main-scene smoke test;
- tracked-file cleanliness check after Godot.

## Local equivalent

`scripts/check.ps1` remains the standard local repository/Godot check. GitHub CI additionally runs the temporal audit and adaptive draw self-test.

## Workflow

`.github/workflows/ci.yml`

Runs for pull-request work and configured push/manual triggers.

## Philosophy

Move a rule into CI when source structure can determine it reliably: fixed shader surfaces, missing creative provenance, unexplained direct-clock animation, or diversity-engine invariants.

Do **not** replace visual judgment with brittle screenshot scoring. Explicit host REVIEW data, telemetry and visual inspection are the artistic evidence layer.

Never weaken a CI gate merely to make a new sketch pass; fix the representation or intentionally revise the documented contract with evidence.
