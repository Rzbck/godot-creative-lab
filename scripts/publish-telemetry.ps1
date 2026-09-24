param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot,

    [Parameter(Mandatory = $true)]
    [string]$TelemetryFile,

    [string]$Reason = "runtime",
    [string]$Remote = "origin",
    [string]$Branch = "telemetry/runtime"
)

$ErrorActionPreference = "Stop"
# Git non-zero exit codes are handled explicitly below. This avoids inheriting
# $PSNativeCommandUseErrorActionPreference=$true from an interactive PS7 shell.
$PSNativeCommandUseErrorActionPreference = $false

Set-Location -LiteralPath $RepoRoot

if (-not (Test-Path -LiteralPath $TelemetryFile -PathType Leaf)) {
    exit 0
}

$RuntimeDir = Join-Path $RepoRoot ".telemetry_runtime"
New-Item -ItemType Directory -Force -Path $RuntimeDir | Out-Null

$SessionFile = [System.IO.Path]::GetFileName($TelemetryFile)
$StatusFile = Join-Path $RuntimeDir "publish-status.json"
$LockFile = Join-Path $RuntimeDir "publish.lock"
$TempIndex = Join-Path ([System.IO.Path]::GetTempPath()) ("creative-lab-telemetry-" + [guid]::NewGuid().ToString("N") + ".index")
$SanitizedFile = Join-Path $RuntimeDir ("publish-" + [guid]::NewGuid().ToString("N") + ".jsonl")
$RemoteRef = "refs/remotes/$Remote/$Branch"
$TargetRef = "refs/heads/$Branch"
$OldIndex = $env:GIT_INDEX_FILE
$LockStream = $null

function Write-Status {
    param(
        [bool]$Ok,
        [string]$Message,
        [string]$Commit = ""
    )

    $Payload = [ordered]@{
        ok      = $Ok
        reason  = $Reason
        session = $SessionFile
        message = $Message
        commit  = $Commit
        utc     = [DateTime]::UtcNow.ToString("o")
    } | ConvertTo-Json -Compress

    [System.IO.File]::WriteAllText($StatusFile, $Payload)
}

function Get-PublicSessionId {
    param([string]$Value)

    $Sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $Bytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
        $Hash = $Sha.ComputeHash($Bytes)
        $Hex = -join ($Hash | ForEach-Object { $_.ToString("x2") })
        return $Hex.Substring(0, 16)
    }
    finally {
        $Sha.Dispose()
    }
}

$SafeKeys = @{
    # event payload
    previous_mode = $true; previous_position = $true; previous_size = $true
    saved_restore_position = $true; saved_restore_size = $true; saved_has_restore_rect = $true
    restore_mode = $true; restore_position = $true; restore_size = $true
    target_mode = $true; target_position = $true; target_size = $true
    attempt = $true; matched = $true; mode_ok = $true; rect_ok = $true
    has_restore_rect = $true; from_mode = $true
    godot = $true; os = $true; remote_enabled = $true

    # layout snapshot
    layout = $true; viewport_visible_size = $true
    main = $true; margin = $true; top_bar = $true; rail = $true; status_bar = $true
    gallery_view = $true; project_view = $true; preview_container = $true; fullscreen_overlay = $true
    visible = $true; position = $true; global_position = $true; size = $true
}

$SafeStringKeys = @{
    previous_mode = $true; restore_mode = $true; target_mode = $true; from_mode = $true
    godot = $true; os = $true
}

function Convert-ToSafeValue {
    param(
        $Value,
        [string]$Key = ""
    )

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [bool] -or
        $Value -is [byte] -or $Value -is [sbyte] -or
        $Value -is [int16] -or $Value -is [uint16] -or
        $Value -is [int32] -or $Value -is [uint32] -or
        $Value -is [int64] -or $Value -is [uint64] -or
        $Value -is [single] -or $Value -is [double] -or $Value -is [decimal]) {
        return $Value
    }

    if ($Value -is [string]) {
        if (-not $SafeStringKeys.ContainsKey($Key)) {
            return $null
        }
        $Text = [string]$Value
        if ($Text.Length -gt 128) {
            $Text = $Text.Substring(0, 128)
        }
        return $Text
    }

    if ($Value -is [System.Management.Automation.PSCustomObject] -or $Value -is [hashtable]) {
        $Result = [ordered]@{}
        foreach ($Property in $Value.PSObject.Properties) {
            $Name = [string]$Property.Name
            if (-not $SafeKeys.ContainsKey($Name)) {
                continue
            }
            $SafeValue = Convert-ToSafeValue -Value $Property.Value -Key $Name
            if ($null -ne $SafeValue) {
                $Result[$Name] = $SafeValue
            }
        }
        return $Result
    }

    if ($Value -is [System.Collections.IEnumerable]) {
        $Items = @()
        foreach ($Item in $Value) {
            $SafeItem = Convert-ToSafeValue -Value $Item -Key $Key
            if ($null -ne $SafeItem) {
                $Items += $SafeItem
            }
        }
        return ,$Items
    }

    return $null
}

function Convert-ToSanitizedTelemetry {
    param(
        [string]$SourcePath,
        [string]$PublicSession
    )

    $Output = New-Object System.Collections.Generic.List[string]

    foreach ($Line in [System.IO.File]::ReadLines($SourcePath)) {
        if ([string]::IsNullOrWhiteSpace($Line)) {
            continue
        }

        try {
            $Record = $Line | ConvertFrom-Json
        }
        catch {
            continue
        }

        $EventName = [string]$Record.event
        if ($EventName -notmatch '^[a-z0-9_]{1,64}$') {
            continue
        }

        $SafeWindow = [ordered]@{}
        if ($null -ne $Record.window) {
            foreach ($Name in @(
                "mode", "position", "size", "screen", "screen_size",
                "restore_position", "restore_size", "has_restore_rect",
                "fullscreen_active", "presentation_transition", "restoring_window", "sketch"
            )) {
                $Property = $Record.window.PSObject.Properties[$Name]
                if ($null -eq $Property) {
                    continue
                }

                if ($Name -eq "mode" -or $Name -eq "sketch") {
                    $Text = [string]$Property.Value
                    if ($Text -match '^[A-Za-z0-9_\-\.]{0,64}$') {
                        $SafeWindow[$Name] = $Text
                    }
                }
                else {
                    $SafeWindow[$Name] = $Property.Value
                }
            }
        }

        $SafeData = Convert-ToSafeValue -Value $Record.data -Key "data"
        if ($null -eq $SafeData) {
            $SafeData = [ordered]@{}
        }

        $SafeRecord = [ordered]@{
            schema     = 3
            session    = $PublicSession
            seq        = [int64]$Record.seq
            elapsed_ms = [int64]$Record.elapsed_ms
            event      = $EventName
            window     = $SafeWindow
            data       = $SafeData
        }

        $Output.Add(($SafeRecord | ConvertTo-Json -Depth 16 -Compress))
    }

    if ($Output.Count -eq 0) {
        throw "Telemetry contains no valid records after sanitization."
    }

    return ($Output -join [Environment]::NewLine) + [Environment]::NewLine
}

try {
    # Serialize concurrent automatic publishers. The application launches this
    # script asynchronously on several key events, so overlapping git pushes are possible.
    for ($Attempt = 0; $Attempt -lt 50 -and $null -eq $LockStream; $Attempt++) {
        try {
            $LockStream = [System.IO.File]::Open(
                $LockFile,
                [System.IO.FileMode]::OpenOrCreate,
                [System.IO.FileAccess]::ReadWrite,
                [System.IO.FileShare]::None
            )
        }
        catch [System.IO.IOException] {
            Start-Sleep -Milliseconds 200
        }
    }

    if ($null -eq $LockStream) {
        throw "Telemetry publisher lock timeout."
    }

    $PublicSession = Get-PublicSessionId -Value $SessionFile
    $PublicSessionFile = "session_$PublicSession.jsonl"
    $SanitizedContent = Convert-ToSanitizedTelemetry -SourcePath $TelemetryFile -PublicSession $PublicSession
    $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($SanitizedFile, $SanitizedContent, $Utf8NoBom)

    $null = git rev-parse --is-inside-work-tree
    if ($LASTEXITCODE -ne 0) {
        throw "Not inside a Git worktree."
    }

    # Refresh the telemetry-only branch if it already exists. A missing branch is fine.
    git fetch --quiet $Remote "+$TargetRef`:$RemoteRef" 2>$null
    $HasParent = $LASTEXITCODE -eq 0
    $Parent = ""

    if ($HasParent) {
        $Parent = (git rev-parse $RemoteRef).Trim()
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($Parent)) {
            $HasParent = $false
        }
    }

    $env:GIT_INDEX_FILE = $TempIndex

    if ($HasParent) {
        git read-tree $Parent
    }
    else {
        git read-tree --empty
    }
    if ($LASTEXITCODE -ne 0) {
        throw "git read-tree failed."
    }

    $Blob = (git hash-object -w -- $SanitizedFile).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($Blob)) {
        throw "git hash-object failed."
    }

    git update-index --add --cacheinfo 100644 $Blob "latest.jsonl"
    if ($LASTEXITCODE -ne 0) {
        throw "Could not stage latest.jsonl in telemetry index."
    }

    git update-index --add --cacheinfo 100644 $Blob ("sessions/" + $PublicSessionFile)
    if ($LASTEXITCODE -ne 0) {
        throw "Could not stage sanitized session history in telemetry index."
    }

    $Tree = (git write-tree).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($Tree)) {
        throw "git write-tree failed."
    }

    # Never expose the developer's configured Git identity in telemetry commits.
    $env:GIT_AUTHOR_NAME = "Creative Lab Telemetry"
    $env:GIT_AUTHOR_EMAIL = "telemetry@localhost"
    $env:GIT_COMMITTER_NAME = "Creative Lab Telemetry"
    $env:GIT_COMMITTER_EMAIL = "telemetry@localhost"

    $CommitMessage = "telemetry: $Reason $PublicSessionFile"
    if ($HasParent) {
        $Commit = (git commit-tree $Tree -p $Parent -m $CommitMessage).Trim()
    }
    else {
        $Commit = (git commit-tree $Tree -m $CommitMessage).Trim()
    }

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($Commit)) {
        throw "git commit-tree failed."
    }

    git push --quiet $Remote "$Commit`:$TargetRef"
    if ($LASTEXITCODE -ne 0) {
        throw "git push failed. Check the existing GitHub credentials for this repository."
    }

    Write-Status -Ok $true -Message "Published sanitized telemetry to $Branch" -Commit $Commit
    Write-Host "CREATIVE_LAB_TELEMETRY_PUBLISHED branch=$Branch commit=$Commit session=$PublicSessionFile"
    exit 0
}
catch {
    Write-Status -Ok $false -Message $_.Exception.Message
    Write-Error $_.Exception.Message
    exit 1
}
finally {
    if ($null -eq $OldIndex) {
        Remove-Item Env:GIT_INDEX_FILE -ErrorAction SilentlyContinue
    }
    else {
        $env:GIT_INDEX_FILE = $OldIndex
    }

    if ($null -ne $LockStream) {
        $LockStream.Dispose()
    }

    Remove-Item -LiteralPath $TempIndex -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $SanitizedFile -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $LockFile -Force -ErrorAction SilentlyContinue
}
