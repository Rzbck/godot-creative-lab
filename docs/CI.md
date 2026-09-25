# Continuous Integration

## Purpose

GitHub Actions is the remote validation layer for Creative Lab. Local development remains fast while repetitive repository/runtime regressions are automated.

## Current checks

### Repository policy

Cross-platform Python validator:

`scripts/ci/validate_repository.py`

Checks include:

- required repository files;
- forbidden generated/local paths;
- large tracked files;
- project-owned path naming policy;
- expected Godot project identity/version family;
- no obvious sketch index/title burn-in in runtime drawing code;
- **full-canvas shader-surface contract**.

### Full-canvas shader-surface gate

A runtime scene node named `ShaderSurface` is treated as a full artwork surface.

CI requires it to reference:

`res://sketches/_shared/full_canvas_surface.gd`

and rejects legacy fixed surface sizing such as:

```text
offset_right = 1280
offset_bottom = 720
```

This rule exists because the logical design coordinate system may be 1280×720 while PREVIEW/PROGRAM surfaces can be larger or differently sized. A sketch must never expose unrendered host gray simply because its own ColorRect stayed fixed-size.

The host additionally emits runtime `sketch_surface_contract` telemetry; CI is the static prevention layer, telemetry/host testing is the dynamic evidence layer.

### Godot headless

CI installs pinned Godot `4.7.1` and runs headless import plus main-scene smoke testing.

The job also fails if Godot modifies tracked repository files during import.

## Local equivalent

Run:

`.\scripts\check.ps1`

This performs repository preflight/policy, exact Godot version validation, headless import, smoke validation and post-import Git cleanliness.

## GitHub workflow

`.github/workflows/ci.yml`

Runs for pull-request work and the repository's configured workflow triggers.

## Version policy

Do not use unpinned `latest` Godot in CI. CI must match the validated development engine until an explicit upgrade is host/repo validated.

## CI philosophy

A rule should move into static CI when the repository can determine it reliably from source structure, as with fixed `ShaderSurface` sizing. Visual quality itself still requires host/render evidence and should not be replaced by brittle screenshot heuristics without a demonstrated need.

Do not weaken a repository policy gate merely to make a new sketch pass. Fix the violating representation or intentionally revise the contract with documented evidence.
