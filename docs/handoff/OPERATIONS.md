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

## Canonical sync + wait for exact CI + run block

After any repository change that needs or benefits from host validation, the AI should provide this workflow **automatically** in its final response. The user should not have to ask for it.

The block:

1. fetches/synchronizes the active branch;
2. confirms local HEAD equals `origin/<branch>`;
3. waits for the GitHub Actions workflow named `CI` for that **exact SHA**;
4. aborts if CI fails/cancels/times out;
5. only after CI is green, closes running Godot processes for this project and launches Godot.

It prefers GitHub CLI (`gh`) when installed/authenticated. If `gh` is unavailable, it falls back to the public GitHub Actions REST API; `GITHUB_TOKEN` is used automatically when present but is not required for a public repository.

```powershell
& {
    $ErrorActionPreference = "Stop"
    $PSNativeCommandUseErrorActionPreference = $true

    $Root     = "E:\_Project\GodotCreativeLab"
    $Branch   = "feat/creative-sketches-002-004-20260924"
    $Repo     = "Rzbck/godot-creative-lab"
    $GodotExe = "C:\Godot\Godot_v4.7.1-stable_win64.exe"
    $Timeout  = [TimeSpan]::FromMinutes(30)

    Set-Location $Root

    git fetch origin $Branch
    git switch $Branch
    git pull --ff-only origin $Branch

    $Head       = (git rev-parse HEAD).Trim()
    $RemoteHead = (git rev-parse "origin/$Branch").Trim()
    if ($Head -ne $RemoteHead) {
        throw "HEAD local ($Head) != origin/$Branch ($RemoteHead)"
    }

    Write-Host "`nHEAD :" ($Head.Substring(0, 8)) -ForegroundColor Green
    Write-Host "CI   : attente du workflow CI pour ce SHA exact..." -ForegroundColor Cyan

    $Deadline = (Get-Date) + $Timeout
    $Gh = Get-Command gh -ErrorAction SilentlyContinue

    if ($Gh) {
        $Run = $null
        while (-not $Run) {
            if ((Get-Date) -gt $Deadline) {
                throw "Timeout: aucun run CI trouvé pour $Head"
            }

            $Raw = & gh run list `
                --repo $Repo `
                --commit $Head `
                --workflow ".github/workflows/ci.yml" `
                --limit 10 `
                --json databaseId,status,conclusion,headSha,url 2>$null

            if ($LASTEXITCODE -ne 0) {
                throw "gh run list a échoué. Vérifie l'authentification GitHub CLI."
            }

            if ($Raw) {
                $Runs = @($Raw | ConvertFrom-Json)
                $Run = $Runs |
                    Where-Object { $_.headSha -eq $Head } |
                    Sort-Object databaseId -Descending |
                    Select-Object -First 1
            }

            if (-not $Run) {
                Start-Sleep -Seconds 5
            }
        }

        Write-Host "Run  :" $Run.url -ForegroundColor DarkGray
        & gh run watch $Run.databaseId --repo $Repo --exit-status
        if ($LASTEXITCODE -ne 0) {
            throw "CI en échec pour $Head — Godot ne sera pas lancé."
        }
    }
    else {
        $Headers = @{
            "Accept"     = "application/vnd.github+json"
            "User-Agent" = "DC-LAB-CI-Waiter"
        }
        if ($env:GITHUB_TOKEN) {
            $Headers["Authorization"] = "Bearer $($env:GITHUB_TOKEN)"
        }

        $Run = $null
        while ($true) {
            if ((Get-Date) -gt $Deadline) {
                throw "Timeout CI pour $Head"
            }

            $Uri = "https://api.github.com/repos/$Repo/actions/runs?head_sha=$Head&per_page=20"
            $Response = Invoke-RestMethod -Uri $Uri -Headers $Headers -Method Get
            $Run = $Response.workflow_runs |
                Where-Object { $_.name -eq "CI" -and $_.head_sha -eq $Head } |
                Sort-Object id -Descending |
                Select-Object -First 1

            if (-not $Run) {
                Write-Host "CI   : run pas encore créé..." -ForegroundColor DarkGray
                Start-Sleep -Seconds 15
                continue
            }

            Write-Host ("CI   : {0} / {1}" -f $Run.status, $Run.conclusion) -ForegroundColor Cyan

            if ($Run.status -eq "completed") {
                if ($Run.conclusion -ne "success") {
                    throw "CI $($Run.conclusion) pour $Head — Godot ne sera pas lancé."
                }
                break
            }

            Start-Sleep -Seconds 15
        }
    }

    Write-Host "CI   : GREEN" -ForegroundColor Green

    Get-CimInstance Win32_Process |
        Where-Object {
            $_.Name -like "Godot*.exe" -and
            $_.CommandLine -like "*GodotCreativeLab*"
        } |
        ForEach-Object {
            Stop-Process -Id $_.ProcessId -Force
        }

    Start-Process `
        -FilePath $GodotExe `
        -ArgumentList "--path", $Root
}
```

Do not downgrade this back to a plain `git pull + Start-Process` block after a material repo change. Exact-head CI gating is part of the canonical host-test workflow.

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

For documentation/knowledge changes, still resolve and verify CI for the final exact HEAD when a workflow run is produced. Never cite an older green run as proof for a newer commit.

Do not claim success from parser confidence alone.

## Mandatory end-of-task repository hygiene

After any material change, before final response:

1. update durable handoff/state docs affected by the change;
2. resolve the final remote HEAD after those documentation commits;
3. verify CI for that exact final HEAD;
4. report the exact short HEAD + CI state;
5. when a host test is relevant, include the canonical block above automatically.

See `AGENTS.md` for the complete mandatory AI completion protocol.

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
- canonical CI-waiting PowerShell supplied automatically after material repo changes;
- no generic filler.
