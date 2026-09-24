# Operations playbook — DC//LAB

This file exists so a fresh AI session can continue the project without reconstructing the operational workflow from chat history.

## Workstation values

```text
Repository: Rzbck/godot-creative-lab
Local root: E:\_Project\GodotCreativeLab
Godot GUI: C:\Godot\Godot_v4.7.1-stable_win64.exe
Godot console: C:\Godot\Godot_v4.7.1-stable_win64_console.exe
Godot version: 4.7.1 stable
Current active feature branch: feat/creative-sketches-002-004-20260924
Draft PR: #7
```

Always resolve current remote HEAD before editing or telling the user which SHA to expect.

## Standard sync + run block

Use this form after a repo change requiring host validation. Keep it compact and wrapped in a single PowerShell script block.

```powershell
& {
    $ErrorActionPreference = "Stop"
    $PSNativeCommandUseErrorActionPreference = $true

    $Root     = "E:\_Project\GodotCreativeLab"
    $Branch   = "feat/creative-sketches-002-004-20260924"
    $GodotExe = "C:\Godot\Godot_v4.7.1-stable_win64.exe"

    Get-CimInstance Win32_Process |
        Where-Object {
            $_.Name -like "Godot*.exe" -and
            $_.CommandLine -like "*GodotCreativeLab*"
        } |
        ForEach-Object {
            Stop-Process -Id $_.ProcessId -Force
        }

    Set-Location $Root

    git fetch origin $Branch
    git switch $Branch
    git pull --ff-only origin $Branch

    Write-Host "`nHEAD :" (git rev-parse --short HEAD) -ForegroundColor Green

    Start-Process `
        -FilePath $GodotExe `
        -ArgumentList "--path", $Root
}
```

Do not ask the user to manually edit files or enter long sequences of Git commands when the GitHub connector can perform the repo work directly.

## CI

Repository workflow:

`.github/workflows/ci.yml`

Local equivalent:

`scripts/check.ps1`

For runtime/code changes, wait for and inspect the CI jobs. Expected checks include:

- Repository policy
- Godot 4.7.1 headless setup/import
- main-scene smoke test
- tracked-file cleanliness after import

Do not claim success from parser confidence alone.

## Telemetry workflow

### Runtime local path

`res://.telemetry_runtime/`

Ignored by ordinary Git.

### Public sanitized branch

`telemetry/runtime`

Important files:

- `latest.jsonl`
- `sessions/session_<sanitized-id>.jsonl`

Telemetry publication is asynchronous/queued. Console messages such as `CREATIVE_LAB_TELEMETRY_PUBLISH_START pid=...` mean a publisher started; they are not proof that the remote branch changed.

### Debugging procedure after a user test

1. Read `telemetry/runtime/latest.jsonl` from GitHub.
2. Verify the telemetry branch commit actually advanced for the session.
3. If `latest.jsonl` is stale/empty while console showed an active publisher, inspect telemetry branch history/session snapshots before asking the user for anything.
4. Analyze exact event chronology before changing window/output/layout code.
5. Only ask the user for screenshots/log text when the remote telemetry genuinely lacks the needed evidence.

### What telemetry should help answer

- root window mode/position/size/screen;
- native PROGRAM output screen/size/state;
- layout geometry/minimum-size overflow;
- SubViewport size/update mode/texture assignment;
- render probes (numeric metrics only, no raw image publication);
- preview vs PROGRAM synchronization state/counts;
- touch/mouse input received by PROGRAM and coordinate mapping;
- Gallery/resize/output transitions;
- telemetry publisher state.

## PROGRAM / LIVE OUT host test

The most important regression test is:

1. Open 004.
2. Send 004 to LIVE OUT on the desired physical display.
3. Touch/drag the physical output and confirm the artwork responds.
4. Return to Gallery: PROGRAM must continue.
5. Open 002 in PREVIEW: 004 must still run on PROGRAM.
6. Change 002 parameters in PREVIEW.
7. Press `TAKE LIVE`: 002 replaces 004 on PROGRAM.
8. Continue using the workstation UI while PROGRAM remains active.

Navigation must not stop PROGRAM.

## Gallery regression test

- Cards show real render thumbnails.
- Only hovered card animates.
- No giant tooltip overlay obscures the card.
- Search filters title/id/index/tags/engine/description.
- Tags are generated from metadata.
- Primary groups are automatic from the first tag.
- Groups with no results disappear.
- Resize keeps the layout clean.

## Persistence regression test

1. Open a sketch.
2. Change multiple exposed parameters.
3. Close the application normally.
4. Relaunch.
5. Reopen that sketch.
6. Values should restore from `user://creative_lab_sketch_settings.cfg`.
7. Gallery thumbnail should reflect persisted parameters.

## Git safety

Allowed normal workflow: direct commits to the active feature branch through the GitHub connector.

Not allowed without explicit user approval:

- merging to `main`;
- force-pushing;
- destructive reset/clean;
- rewriting unrelated published history.

Never use blind `git add -A` in user-facing instructions.

## Communication

User language is French and often phonetic/fast. Respond to intent rather than correcting spelling.

The user values:

- concrete progress;
- direct repo actions;
- exact commit/branch when relevant;
- CI verification;
- minimal manual steps;
- telemetry-first diagnosis;
- no generic filler.
