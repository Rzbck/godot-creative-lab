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

Set-Location -LiteralPath $RepoRoot

if (-not (Test-Path -LiteralPath $TelemetryFile)) {
    exit 0
}

$Content = [System.IO.File]::ReadAllText($TelemetryFile)
if ([string]::IsNullOrWhiteSpace($Content)) {
    exit 0
}

$SessionFile = [System.IO.Path]::GetFileName($TelemetryFile)
$RuntimeDir  = Join-Path $RepoRoot ".telemetry_runtime"
$StatusFile  = Join-Path $RuntimeDir "publish-status.json"
$TempIndex   = Join-Path ([System.IO.Path]::GetTempPath()) ("creative-lab-telemetry-" + [guid]::NewGuid().ToString("N") + ".index")
$RemoteRef   = "refs/remotes/$Remote/$Branch"
$TargetRef   = "refs/heads/$Branch"
$OldIndex    = $env:GIT_INDEX_FILE

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

try {
    $null = git rev-parse --is-inside-work-tree
    if ($LASTEXITCODE -ne 0) {
        throw "Not inside a Git worktree."
    }

    # Refresh the telemetry branch if it already exists. A missing branch is fine.
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

    $Blob = (git hash-object -w -- $TelemetryFile).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($Blob)) {
        throw "git hash-object failed."
    }

    git update-index --add --cacheinfo 100644 $Blob "latest.jsonl"
    if ($LASTEXITCODE -ne 0) {
        throw "Could not stage latest.jsonl in telemetry index."
    }

    git update-index --add --cacheinfo 100644 $Blob ("sessions/" + $SessionFile)
    if ($LASTEXITCODE -ne 0) {
        throw "Could not stage session history in telemetry index."
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

    $CommitMessage = "telemetry: $Reason $SessionFile"
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

    Write-Status -Ok $true -Message "Published to $Branch" -Commit $Commit
    exit 0
}
catch {
    Write-Status -Ok $false -Message $_.Exception.Message
    exit 1
}
finally {
    if ($null -eq $OldIndex) {
        Remove-Item Env:GIT_INDEX_FILE -ErrorAction SilentlyContinue
    }
    else {
        $env:GIT_INDEX_FILE = $OldIndex
    }

    Remove-Item -LiteralPath $TempIndex -Force -ErrorAction SilentlyContinue
}
