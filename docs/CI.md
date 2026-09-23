# Continuous Integration

## Purpose

GitHub Actions is the remote validation layer for Creative Lab.

Local development should remain fast, while repetitive validation is automated.

## Current checks

### Repository policy

Cross-platform Python validator:

    scripts/ci/validate_repository.py

Checks currently include:

- required repository files;
- forbidden generated/local paths;
- very large tracked files;
- basic project-owned path naming policy;
- expected Godot project identity/version family.

### Godot headless

CI installs the pinned Godot version:

    4.7.1

Then runs:

    godot --headless --path . --import

The job fails if Godot modifies tracked repository files.

## Local equivalent

Run:

    .\scripts\check.ps1

This performs:

1. repository preflight;
2. repository policy validation;
3. exact Godot version validation;
4. headless import;
5. post-import Git cleanliness validation.

## GitHub workflow

    .github/workflows/ci.yml

Runs on:

- pull requests;
- pushes to main;
- manual workflow dispatch.

## Version policy

Do not use an unpinned "latest" Godot version in CI.

CI should match the project's validated development engine until an explicit upgrade is validated.

## Future CI stages

Add only when relevant:

- GDScript checks/tests;
- application smoke tests;
- export validation;
- Windows build;
- Linux build;
- artifact publication;
- tagged releases;
- web export / GitHub Pages;
- plugin-specific validation.

Do not perform expensive builds on every commit without a demonstrated need.
