& {
    $ErrorActionPreference = "Stop"
    $PSNativeCommandUseErrorActionPreference = $true
    Set-StrictMode -Version Latest

    $Root = Split-Path -Parent $PSScriptRoot
    Set-Location $Root

    Write-Host "`n===== CREATIVE LAB CHECK =====" -ForegroundColor Cyan

    Write-Host "`n=== PREFLIGHT ===" -ForegroundColor Cyan
    & ".\scripts\preflight.ps1"

    if (@(git status --porcelain).Count -ne 0) {
        throw "STOP : lancer les checks depuis un worktree CLEAN."
    }

    Write-Host "`n=== REPOSITORY POLICY ===" -ForegroundColor Cyan

    $Python = Get-Command python -ErrorAction SilentlyContinue

    if (-not $Python) {
        $Python = Get-Command py -ErrorAction SilentlyContinue
    }

    if (-not $Python) {
        throw "STOP : Python introuvable."
    }

    if ($Python.Name -eq "py.exe") {
        & $Python.Source -3 ".\scripts\ci\validate_repository.py"
    }
    else {
        & $Python.Source ".\scripts\ci\validate_repository.py"
    }

    Write-Host "`n=== GODOT ===" -ForegroundColor Cyan

    $Version = (godot --version).Trim()

    Write-Host "Version : $Version"

    if ($Version -notmatch "^4\.7\.1\.stable") {
        throw "STOP : version Godot inattendue : $Version"
    }

    Write-Host "`n=== GODOT HEADLESS IMPORT ===" -ForegroundColor Cyan

    godot `
        --headless `
        --path . `
        --import

    Write-Host "`n=== POST-GODOT GIT CHECK ===" -ForegroundColor Cyan

    $AfterGodot = @(git status --porcelain)

    if ($AfterGodot.Count -ne 0) {
        Write-Host "Godot a modifie des fichiers versionnes :" -ForegroundColor Red
        $AfterGodot
        git --no-pager diff
        throw "STOP : Godot headless n'est pas repository-clean."
    }

    Write-Host "Godot headless : PASS" -ForegroundColor Green

    Write-Host "`n===== ALL LOCAL CHECKS PASS =====" -ForegroundColor Green
}
