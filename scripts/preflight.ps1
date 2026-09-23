& {
    $ErrorActionPreference = "Stop"

    $Root = Split-Path -Parent $PSScriptRoot
    Set-Location $Root

    Write-Host "`n===== CREATIVE LAB PREFLIGHT =====" -ForegroundColor Cyan

    $Branch = git branch --show-current
    $Head   = git rev-parse --short HEAD
    $Raw    = @(git status --porcelain)

    Write-Host "Repo   : $Root"
    Write-Host "Branch : $Branch"
    Write-Host "HEAD   : $Head"

    if (-not $Raw) {
        Write-Host "State  : CLEAN" -ForegroundColor Green
        return
    }

    $Paths = @(
        $Raw | ForEach-Object {
            if ($_.Length -ge 4) {
                $_.Substring(3).Trim()
            }
        }
    )

    Write-Host "`nWorking tree :" -ForegroundColor Yellow
    $Raw

    if ($Paths.Count -eq 1 -and $Paths[0] -eq "project.godot") {
        Write-Host "`nClassification : PROJECT_GODOT_ONLY" -ForegroundColor Yellow
        Write-Host "Godot peut avoir normalise ou modifie les Project Settings."
        Write-Host "Ce cas exige une inspection du diff, mais n'est pas automatiquement une erreur."

        Write-Host "`nDiff :" -ForegroundColor DarkGray
        git --no-pager diff -- project.godot

        Write-Host "`nACTION : REVIEW_REQUIRED" -ForegroundColor Yellow
        Write-Host "Ne pas restaurer, stage ou commit automatiquement."
        return
    }

    Write-Host "`nClassification : DIRTY_WORKTREE" -ForegroundColor Red
    Write-Host "ACTION : STOP_AND_RECONCILE" -ForegroundColor Red
}
