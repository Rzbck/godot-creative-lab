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

    $GodotAutomation = $null

    if ($IsWindows) {
        $PinnedConsole = "C:\Godot\Godot_v4.7.1-stable_win64_console.exe"

        if (Test-Path -LiteralPath $PinnedConsole) {
            $GodotAutomation = $PinnedConsole
        }
    }

    if (-not $GodotAutomation) {
        $GodotCommand = Get-Command godot -ErrorAction SilentlyContinue

        if (-not $GodotCommand) {
            throw "STOP : Godot introuvable."
        }

        $GodotAutomation = $GodotCommand.Source
    }

    $Version = (& $GodotAutomation --version).Trim()

    Write-Host "Automation executable : $GodotAutomation"
    Write-Host "Version               : $Version"

    if ($Version -notmatch "^4\.7\.1\.stable") {
        throw "STOP : version Godot inattendue : $Version"
    }

    function Invoke-GodotChecked {
        param(
            [Parameter(Mandatory = $true)]
            [string[]]$Arguments,

            [Parameter(Mandatory = $true)]
            [string]$Label
        )

        Write-Host "`n=== $Label ===" -ForegroundColor Cyan

        $Output = @(& $GodotAutomation @Arguments 2>&1)
        $Output | ForEach-Object { Write-Host $_ }

        $Text = $Output -join "`n"

        if ($Text -match "(?m)^\s*(SCRIPT ERROR:|ERROR:)") {
            throw "STOP : Godot a signale une erreur pendant '$Label'."
        }
    }

    Invoke-GodotChecked `
        -Label "GODOT HEADLESS IMPORT" `
        -Arguments @("--headless", "--path", ".", "--import")

    Invoke-GodotChecked `
        -Label "GODOT RUNTIME SMOKE" `
        -Arguments @("--headless", "--path", ".", "--quit-after", "3")

    Write-Host "`n=== POST-GODOT GIT CHECK ===" -ForegroundColor Cyan

    $AfterGodot = @(git status --porcelain)

    if ($AfterGodot.Count -ne 0) {
        Write-Host "Godot a modifie le repository :" -ForegroundColor Red
        $AfterGodot
        git --no-pager diff
        throw "STOP : Godot headless n'est pas repository-clean."
    }

    Write-Host "Godot import + runtime smoke : PASS" -ForegroundColor Green

    Write-Host "`n===== ALL LOCAL CHECKS PASS =====" -ForegroundColor Green
}
