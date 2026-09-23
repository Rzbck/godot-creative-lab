# AGENTS.md — DataC0re Creative Lab

This repository is a Godot-based creative-coding laboratory.

Its goals are:
- learn Godot progressively through real creative-coding experiments;
- keep every experiment accessible from a central gallery;
- isolate sketches so experiments cannot silently break each other;
- provide reusable real-time outputs such as Window, Spout and NDI;
- remain understandable and maintainable across human and AI sessions.

This file contains permanent working rules.
Current operational state belongs in HANDOFF.md.

## Bootstrap for every substantial session

Before modifying the project:

1. Verify the real repository path.
2. Verify active branch, HEAD and CLEAN/DIRTY state.
3. Read AGENTS.md.
4. Read HANDOFF.md.
5. Read only the architecture, decision or active exec-plan documents relevant to the task.
6. Inspect the actual scene/script/shader involved before proposing changes.

Never reconstruct current project state only from an old chat.

## Evidence vocabulary

Keep these states distinct:

- HOST_VALIDATED: observed on the user's real machine/runtime.
- REPO_VALIDATED: durable repository state verified in Git.
- IMPLEMENTED_NOT_VALIDATED: implemented but not yet validated as required.
- EXPERIMENTAL: prototype or hypothesis.
- BLOCKER: prevents the next safe step.
- NEXT: agreed next operation.

Existing code is not automatically validated behavior.

## Git discipline

main is the published baseline.

For non-trivial work:
- use a dedicated branch;
- if several tasks run concurrently: one task = one branch = one worktree;
- verify path, branch, HEAD and status before writing;
- never force-push as routine recovery;
- never use destructive reset/clean without explicit need;
- never overwrite unrelated concurrent work;
- do not use blind git add -A;
- do not push or merge without explicit user approval.

Human validation decides promotion to main.

## PowerShell

The user pastes commands directly into PowerShell 7.

Interactive command blocks must therefore be complete copy/paste blocks wrapped as:

    & {
        ...
    }

Avoid constructs split across separate pastes that can leave PowerShell at the >> continuation prompt.

For substantial reusable automation, create a versioned .ps1 under scripts/ instead.

## Godot architecture

Each creative sketch must remain isolated.

Target flow:

Gallery
  -> selected Sketch
  -> central render target / SubViewport
  -> Window
  -> optional Spout
  -> optional NDI

Sketches must not directly depend on Spout or NDI.

Outputs are adapters around the central render path.

If an optional output extension is missing, the gallery and sketches must still work.

Shared systems belong under shared/.
Sketch-specific code and assets belong inside that sketch whenever practical.

## Creative coding principles

Prefer small experiments that teach one concept clearly.

Do not hide Godot fundamentals behind excessive framework code.

When introducing a Godot concept, explain:
- what the node/resource/script is;
- why it exists;
- how data flows through it;
- what is Godot-specific versus general creative-coding logic.

## Output dependencies

Spout and NDI are optional integrations.

Before adding a native extension:
- verify supported Godot version;
- verify supported renderer/platform;
- document upstream source and license;
- pin the version used;
- confirm a clean fallback when unavailable.

Do not commit arbitrary downloaded binaries without documenting their origin and licensing.

## Sources of truth

- Git HEAD + active files = what exists.
- Runtime result = what actually ran.
- HANDOFF.md = compact current state.
- docs/ARCHITECTURE.md = durable architecture.
- docs/decisions/ = durable decisions.
- docs/exec-plans/active/ = bounded ongoing work.
- docs/SESSION_LOG.md = compact material session history.

If these disagree, investigate instead of silently reconciling them.

## Handoff maintenance

Update HANDOFF.md after material changes:
- meaningful validation;
- rejection of an approach;
- architectural decision;
- new blocker;
- release/promotion;
- genuine change of NEXT.

Do not store conversation transcripts.

Keep durable decisions, evidence, commit references and next actions.

## Godot project configuration

`project.godot` is tracked and important, but the Godot editor may legitimately rewrite it.

Before treating a dirty worktree as a blocker:

1. run `scripts/preflight.ps1`;
2. if only `project.godot` changed, inspect its exact diff;
3. distinguish editor normalization from intentional Project Settings changes;
4. never automatically restore, stage, or accept arbitrary `project.godot` changes.

Prefer the Godot editor / Project Settings UI for ordinary engine configuration.

Use `.gitattributes` as the repository source of truth for line-ending policy.

## Automated validation

Prefer repeatable repository scripts and CI over repeatedly asking the user to perform equivalent manual checks.

Local standard check:

    scripts/check.ps1

GitHub CI:

    .github/workflows/ci.yml

For PowerShell 7 automation that invokes native commands such as Git or Godot, enable:

    $PSNativeCommandUseErrorActionPreference = $true

A failing native process must not be silently treated as success.

Godot CI must remain pinned to the validated project engine version until an explicit engine upgrade is validated.

Do not add expensive build/export matrices before the project actually needs them.
