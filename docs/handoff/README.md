# Handoff system

This folder contains the continuation package for future human/AI sessions.

Read order:

1. repository root `AGENTS.md`
2. repository root `HANDOFF.md`
3. `CURRENT_WORK.md`
4. `OPERATIONS.md`
5. `project_state.json`
6. `NEXT_AI_PROMPT.md` when starting a fresh conversation
7. `../ARCHITECTURE.md` for implemented runtime responsibilities

Purpose:

- prevent project continuity from depending on one chat transcript;
- keep GitHub/runtime evidence as the source of truth;
- preserve the tested Git/CI/PowerShell/telemetry workflow;
- tell a fresh AI what behaviors must not regress;
- keep long-term creative/design research in `knowledge/` rather than model memory alone.

The recorded SHA values are snapshots only. Always resolve the active branch HEAD and CI from GitHub at session start.