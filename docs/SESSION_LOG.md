# Session Log

Keep only compact material history.

Template:

## YYYY-MM-DD — subject

HEAD before / after:
HOST_VALIDATED:
REPO_VALIDATED:
IMPLEMENTED_NOT_VALIDATED:
REJECTED / EXPERIMENTAL:
DECISIONS:
FILES / SYSTEMS:
NEXT TEST:
ROLLBACK / CHECKPOINT:

## 2026-09-23 — repository bootstrap

HEAD before / after: unborn repository -> initial bootstrap commit
HOST_VALIDATED: Godot 4.7.1 stable available from C:\Godot and callable as `godot`.
REPO_VALIDATED: local repository E:\_Project\GodotCreativeLab uses origin Rzbck/godot-creative-lab.
IMPLEMENTED_NOT_VALIDATED: initial project/documentation/directory scaffold.
REJECTED / EXPERIMENTAL: Spout and NDI remain planned integrations only.
DECISIONS: gallery of isolated sketches; central render path; optional output adapters.
FILES / SYSTEMS: repository scaffold and project documentation.
NEXT TEST: open project in Godot and create the first real scene.
ROLLBACK / CHECKPOINT: initial bootstrap commit.

## 2026-09-23/24 — workstation, PROGRAM output, telemetry, Gallery and first creative library

HEAD before / after: architecture scaffold -> active feature stack ending on `feat/creative-sketches-002-004-20260924` (resolve current HEAD from GitHub; baseline before handoff refresh was `eef780c`).

HOST_VALIDATED:
- custom workstation launches on Godot 4.7.1 / Vulkan Forward+ / RTX 5080;
- physical PROGRAM output can run on a selected display while workstation remains usable;
- touchscreen interaction on the PROGRAM display drives the live sketch;
- Gallery/other project navigation can occur while previous PROGRAM sketch keeps running;
- another preview can replace PROGRAM via TAKE LIVE;
- preview/output state synchronization fixed the prior independent-simulation mismatch;
- resize/fullscreen/output behaviors were repeatedly validated through online telemetry.

REPO_VALIDATED:
- CI repeatedly passes repository policy, Godot 4.7.1 headless import, runtime smoke test and tracked-file cleanliness for the accepted feature commits;
- Gallery discovers sketch definitions dynamically;
- Gallery real thumbnails/hover preview, persistence, PROGRAM transport and telemetry systems are committed;
- sketches 001-004 are committed;
- creative-coding and design/typography research libraries are committed under `knowledge/`.

IMPLEMENTED_NOT_VALIDATED:
- future changes after this session must re-check current branch CI rather than relying on this log;
- future Spout/NDI, timeline, A/B/C deck mixing and compositing are not implemented.

REJECTED / EXPERIMENTAL:
- workstation root-window fullscreen as normal live-output architecture;
- cross-native-window sampling of the workstation SubViewport texture on the validated host (gray output);
- synchronous/concurrent telemetry Git publication on the Godot main thread (caused UI hangs/lock timeouts);
- independent generative timelines between preview and PROGRAM;
- Gallery tooltip overlays that obscure visual cards.

DECISIONS:
- PREVIEW/EDITOR and PROGRAM are separate responsibilities;
- navigation is not PROGRAM transport;
- PROGRAM can detach and continue autonomously when editor navigates away;
- TAKE LIVE replaces PROGRAM from another preview;
- sketch parameter settings persist under `user://`;
- telemetry is sanitized, asynchronous and published to branch `telemetry/runtime`;
- external creative/design research is versioned as a knowledge library in the repo;
- no new sketch number is invented without user approval;
- `main` is not merged without explicit user approval.

FILES / SYSTEMS:
- `app/main/main_runtime.tscn` and layered runtime scripts;
- `sketches/001_signal_field` through `sketches/004_gommage_type`;
- `scripts/publish-telemetry*.ps1` and `.telemetry_runtime/` workflow;
- `knowledge/creative-coding/`;
- `knowledge/design/`;
- refreshed `AGENTS.md`, `HANDOFF.md`, `docs/ARCHITECTURE.md` and `docs/handoff/` continuation package.

NEXT TEST:
- depends on the user's next requested feature; preserve current Gallery/PROGRAM/touch/persistence/telemetry behavior and consult `knowledge/` before substantial new creative work.

ROLLBACK / CHECKPOINT:
- current feature branch + draft PR #7; resolve current remote HEAD from GitHub before work.

## 2026-09-24 — cross-domain atlas and concept-generation engine

HEAD before / after: `1705ad6` -> resolve current remote HEAD after documentation commits.

HOST_VALIDATED:
- not applicable; this pass changes research/documentation only.

REPO_VALIDATED:
- pending final CI check after the documentation sequence.

IMPLEMENTED_NOT_VALIDATED:
- `knowledge/cross-domain/` now contains a translation atlas, idea/mutation engine, specialized source catalog and machine-readable source index;
- entrypoint/handoff documents now instruct future AI sessions to use the cross-domain layer before substantial new creative work.

REJECTED / EXPERIMENTAL:
- treating the knowledge library as a simple list of visual inspirations;
- generating concepts by stacking familiar effects from one technical family;
- copying one source's surface appearance and calling it a new identity.

DECISIONS:
- research is decomposed into carriers, representations, operators, drivers, temporal models, design constraints and output languages;
- substantial new creative work should normally combine at least three domains and at least one genuine representation change;
- the first coherent combination should be mutated deliberately before implementation;
- persistent identity anchors and professional composition constraints remain part of generative work;
- interaction should alter the system's behavior/state rather than merely attach a radial pointer effect.

FILES / SYSTEMS:
- `knowledge/cross-domain/README.md`;
- `knowledge/cross-domain/CROSS_DOMAIN_ATLAS.md`;
- `knowledge/cross-domain/IDEA_ENGINE.md`;
- `knowledge/cross-domain/SOURCE_CATALOG.md`;
- `knowledge/cross-domain/sources.json`;
- knowledge/handoff/architecture entrypoints updated to include the new layer.

NEXT TEST:
- use the idea engine to design the next user-approved shader/sketch concept, then translate the winning concept into the existing Godot sketch + PREVIEW/PROGRAM contract.

ROLLBACK / CHECKPOINT:
- active feature branch `feat/creative-sketches-002-004-20260924`; do not merge `main` without user approval.