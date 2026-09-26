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

Repository workflow: `.github/workflows/ci.yml`

Local equivalent: `scripts/check.ps1`

For runtime/code changes, expected checks include:

- Repository policy
- Godot 4.7.1 headless setup/import
- main-scene smoke test
- tracked-file cleanliness after import

Repository policy now includes the full-canvas `ShaderSurface` rule documented in `docs/CI.md` and `docs/SKETCH_CONTRACT.md`.

For docs/knowledge changes, still resolve and verify CI for the final exact HEAD when a workflow run is produced. Never cite an older green run for a newer commit.

## Mandatory end-of-task repository hygiene

After any material change, before final response:

1. update durable handoff/state docs affected by change;
2. resolve final remote HEAD after docs commits;
3. verify CI for that exact final HEAD;
4. report exact short HEAD + CI;
5. when host test relevant, include canonical block above automatically.

## Telemetry workflow

Local runtime path: `res://.telemetry_runtime/`

Public sanitized branch: `telemetry/runtime`

Important files:

- `latest.jsonl`
- `sessions/session_<sanitized-id>.jsonl`

Publication is asynchronous/queued. Publisher start messages are not proof remote branch changed.

### Debugging procedure after user test

1. Read `telemetry/runtime/latest.jsonl`.
2. Verify branch/session advanced and matches tested HEAD.
3. Inspect session snapshots if rolling file stale/empty.
4. Analyze event chronology before changing runtime.
5. Only request screenshots/log text when telemetry lacks needed evidence.

Telemetry can answer window/layout/SubViewport/output/linkage/input/resize/filter state plus:

- `sketch_surface_contract` viewport/coverage diagnostics;
- `sketch_review_changed` numeric host ratings;
- Trash/restore/purge/retention events.

## PROGRAM / LIVE OUT regression

1. Open 004.
2. Send 004 to LIVE OUT.
3. Touch/drag physical output; art responds.
4. Return Gallery: PROGRAM continues.
5. Open 002 in PREVIEW: 004 still PROGRAM.
6. Change 002 parameters.
7. TAKE LIVE: 002 replaces 004.
8. Keep using workstation while PROGRAM active.

Navigation must not stop PROGRAM.

## Gallery regression

- real thumbnails;
- only hovered card animates;
- no giant tooltip overlay;
- search indexes title/id/index/tags/engine/description and every metadata tag;
- first tag still automatic primary group;
- permanent tag rail bounded to ALL + at most six generated tags + optional MORE;
- universal tags not shown as useless filters;
- rare tags accessible through MORE/search;
- active rare tag promoted while selected;
- MORE collapsed by default;
- empty groups disappear;
- resize remains clean.

## Full-canvas render regression

1. Open 025 FARADAY QUASI in maximized workstation PREVIEW.
2. Confirm artwork covers the whole PREVIEW (previous failing case was 1520×852) with no gray right/bottom gap.
3. Resize workstation repeatedly; surface remains full-canvas.
4. Repeat with 021 and 005, the other current named `ShaderSurface` scenes.
5. Press F11 on a shader-backed sketch; surface remains full-canvas.
6. After close, telemetry should include `sketch_surface_contract` with `pass=true` for tested surfaces.

A gray region caused by a fixed sketch surface is a release blocker, not an acceptable aspect-ratio letterbox.

## Review regression

1. Open a sketch.
2. Set several REVIEW criteria from 1–5.
3. Return Gallery; rated card shows `R x.x`.
4. Reopen; scores persist.
5. Close/relaunch normally; scores remain from `user://creative_lab_reviews.cfg`.
6. Verify telemetry publishes `sketch_review_changed` with numeric ratings.

Review scores are creative evidence for future AI work, not decorative UI.

## Trash regression

1. Choose a disposable/noncritical sketch.
2. `MOVE TO TRASH`.
3. Confirm it disappears from normal Gallery and `TRASH 1` appears.
4. Open Trash and RESTORE; sketch returns.
5. Test retention selector (7/14/30 days) if relevant.
6. `PURGE` may be tested only with understanding that it retires the sketch from this workstation Gallery; source remains in Git.

The runtime must never delete version-controlled `res://sketches/...` files.

## Persistence regression

1. Open a sketch.
2. Change multiple creative parameters.
3. Close normally.
4. Relaunch.
5. Reopen.
6. Values restore from `user://creative_lab_sketch_settings.cfg`.
7. Gallery thumbnail reflects persisted parameters.

## Git safety

Allowed normal workflow: direct commits to active feature branch through GitHub connector.

Not allowed without explicit user approval:

- merging `main`;
- force-pushing;
- destructive reset/clean;
- rewriting unrelated published history.

Never use blind `git add -A` in user-facing instructions.

## Communication

User language is French and often phonetic/fast. Respond to intent rather than correcting spelling.

User values concrete progress, direct repo actions, exact branch/SHA, CI verification, minimal manual steps, telemetry-first diagnosis, automatic canonical PowerShell after material changes, and no generic filler.
