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
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}

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

$SafeWindowKeys = @(
    "mode", "position", "size", "screen", "screen_size",
    "restore_position", "restore_size", "has_restore_rect",
    "fullscreen_active", "presentation_transition", "restoring_window", "sketch",
    "display_position", "display_size", "root_position", "root_size",
    "screen_position", "screen_usable_position", "screen_usable_size", "min_size",
    "borderless", "resize_disabled", "always_on_top", "unresizable", "content_scale_factor"
)

$SafeStringKeys = @{
    previous_mode = $true
    restore_mode = $true
    target_mode = $true
    from_mode = $true
    godot = $true
    os = $true
    git_head = $true
}

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

function Convert-ToDiagnosticValue {
    param(
        $Value,
        [string]$Key = "",
        [int]$Depth = 0
    )

    if ($Depth -gt 20 -or $null -eq $Value) {
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

        $Text = ([string]$Value).Trim()
        if ($Text.Length -gt 128) {
            $Text = $Text.Substring(0, 128)
        }

        if ($Key -eq "git_head" -and $Text -notmatch '^(?:[0-9a-fA-F]{7,40}|unknown|headless)$') {
            return $null
        }

        if ($Key -ne "git_head" -and $Text -notmatch '^[A-Za-z0-9 ._()\-]{0,128}$') {
            return $null
        }

        return $Text
    }

    if ($Value -is [System.Management.Automation.PSCustomObject] -or $Value -is [hashtable]) {
        $Result = [ordered]@{}
        foreach ($Property in $Value.PSObject.Properties) {
            $Name = [string]$Property.Name
            if ($Name -notmatch '^[a-z0-9_]{1,64}$') {
                continue
            }

            $SafeValue = Convert-ToDiagnosticValue -Value $Property.Value -Key $Name -Depth ($Depth + 1)
            if ($null -ne $SafeValue) {
                $Result[$Name] = $SafeValue
            }
        }
        return $Result
    }

    if ($Value -is [System.Collections.IEnumerable]) {
        $Items = @()
        foreach ($Item in $Value) {
            $SafeItem = Convert-ToDiagnosticValue -Value $Item -Key $Key -Depth ($Depth + 1)
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
            foreach ($Name in $SafeWindowKeys) {
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
                    $SafeValue = Convert-ToDiagnosticValue -Value $Property.Value -Key $Name
                    if ($null -ne $SafeValue) {
                        $SafeWindow[$Name] = $SafeValue
                    }
                }
            }
        }

        $SafeData = Convert-ToDiagnosticValue -Value $Record.data -Key "data"
        if ($null -eq $SafeData) {
            $SafeData = [ordered]@{}
        }

        $SafeRecord = [ordered]@{
            schema     = 4
            session    = $PublicSession
            seq        = [int64]$Record.seq
            elapsed_ms = [int64]$Record.elapsed_ms
            event      = $EventName
            window     = $SafeWindow
            data       = $SafeData
        }

        $Output.Add(($SafeRecord | ConvertTo-Json -Depth 24 -Compress))
    }

    if ($Output.Count -eq 0) {
        throw "Telemetry contains no valid records after sanitization."
    }

    return ($Output -join [Environment]::NewLine) + [Environment]::NewLine
}

try {
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

    $PreviousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $RemoteLines = @(& git ls-remote --heads $Remote $TargetRef 2>$null)
    $LsRemoteExit = $LASTEXITCODE
    $ErrorActionPreference = $PreviousErrorActionPreference

    if ($LsRemoteExit -ne 0) {
        throw "Could not query remote telemetry branch."
    }

    $HasParent = $RemoteLines.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace(($RemoteLines -join ""))
    $Parent = ""

    if ($HasParent) {
        $PreviousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        & git fetch --quiet $Remote "+$TargetRef`:$RemoteRef" 2>$null
        $FetchExit = $LASTEXITCODE
        $ErrorActionPreference = $PreviousErrorActionPreference

        if ($FetchExit -ne 0) {
            throw "Could not refresh existing telemetry branch."
        }

        $Parent = (& git rev-parse $RemoteRef).Trim()
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($Parent)) {
            throw "Could not resolve telemetry branch parent."
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
        throw "Could not stage latest.jsonl."
    }

    git update-index --add --cacheinfo 100644 $Blob ("sessions/" + $PublicSessionFile)
    if ($LASTEXITCODE -ne 0) {
        throw "Could not stage session history."
    }

    $Tree = (git write-tree).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($Tree)) {
        throw "git write-tree failed."
    }

    $env:GIT_AUTHOR_NAME = "Creative Lab Telemetry"
    $env:GIT_AUTHOR_EMAIL = "telemetry@localhost"
    $env:GIT_COMMITTER_NAME = "Creative Lab Telemetry"
    $env:GIT_COMMITTER_EMAIL = "telemetry@localhost"

    $SafeReason = ($Reason -replace '[^A-Za-z0-9_\-]', '_')
    if ([string]::IsNullOrWhiteSpace($SafeReason)) {
        $SafeReason = "runtime"
    }
    if ($SafeReason.Length -gt 64) {
        $SafeReason = $SafeReason.Substring(0, 64)
    }

    $CommitMessage = "telemetry: $SafeReason $PublicSessionFile"
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
        throw "git push failed."
    }

    Write-Status -Ok $true -Message "Published diagnostic telemetry to $Branch" -Commit $Commit
    Write-Host "CREATIVE_LAB_TELEMETRY_PUBLISHED branch=$Branch commit=$Commit session=$PublicSessionFile schema=4"
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
