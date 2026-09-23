# ADR 0004 — Treat project.godot as editor-managed configuration

Status: ACCEPTED

## Context

Godot may legitimately rewrite `project.godot` when the editor opens or when Project Settings change.

The first editor launch normalized the standard header and added:

    config/features=PackedStringArray("4.7")

A generic "dirty worktree = stop" rule therefore creates false blockers.

## Decision

`project.godot` remains tracked in Git and is an important source of truth.

However, when it is the only modified file after launching Godot:

1. do not automatically restore it;
2. do not automatically stage it;
3. inspect the exact diff;
4. distinguish editor normalization from meaningful configuration changes;
5. record intentional changes in Git.

Arbitrary changes in `project.godot` are never automatically trusted.

## Editing policy

Prefer Godot Project Settings / editor UI for ordinary engine settings.

Direct text edits are reserved for deliberate, reviewed automation or settings that are clearer to manage reproducibly as text.

## Preflight

Use:

    .\scripts\preflight.ps1

Classification:

- CLEAN: safe baseline;
- PROJECT_GODOT_ONLY: inspect diff before proceeding;
- DIRTY_WORKTREE: reconcile before unrelated work.

## Reason

This preserves both safety and normal Godot editor behavior without discarding meaningful project configuration.
