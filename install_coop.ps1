<#
.SYNOPSIS
    Installs Swords and Sandals 2 Co-op SWF with pinned SHA-256 verification and stock backup.
#>
[CmdletBinding()]
param(
    [string]$GameDir = "",
    [string]$DistSwf = "",
    [string]$ManifestPath = "",
    [switch]$GenerateManifest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$PINNED_STOCK_SHA256 = "77CB545C2061AB41246251467A4EDF5926AB6FD1DDD95DC9527D7BA9C45BB8CA"
$GAME_FOLDER_NAME = "Swords and Sandals Classic Collection"

if ([string]::IsNullOrWhiteSpace($DistSwf)) {
    $DistSwf = Join-Path $PSScriptRoot "dist\swords_sandals2_coop.swf"
}
if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $PSScriptRoot "dist\manifest.json"
}

function Get-Sha256Upper {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Find-SS2GameDir {
    $candidates = New-Object System.Collections.Generic.List[string]
    $candidates.Add("C:\Program Files (x86)\Steam\steamapps\common\$GAME_FOLDER_NAME")
    $candidates.Add("C:\Program Files\Steam\steamapps\common\$GAME_FOLDER_NAME")

    $steamRoots = New-Object System.Collections.Generic.List[string]
    $steamRoots.Add("C:\Program Files (x86)\Steam")
    $steamRoots.Add("C:\Program Files\Steam")

    $regQueries = @(
        @{ Path = "HKCU:\Software\Valve\Steam"; Name = "SteamPath" },
        @{ Path = "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam"; Name = "InstallPath" },
        @{ Path = "HKLM:\SOFTWARE\Valve\Steam"; Name = "InstallPath" }
    )
    foreach ($rq in $regQueries) {
        if (Test-Path -LiteralPath $rq.Path) {
            try {
                $val = (Get-ItemProperty -LiteralPath $rq.Path -Name $rq.Name -ErrorAction Stop).($rq.Name)
                if (-not [string]::IsNullOrWhiteSpace($val)) {
                    $steamRoots.Add(($val -replace "/", "\"))
                }
            } catch {
                # Ignore missing registry value
            }
        }
    }

    $seenRoots = @{}
    foreach ($root in $steamRoots) {
        if ([string]::IsNullOrWhiteSpace($root)) { continue }
        $normRoot = $root.TrimEnd("\")
        if ($seenRoots.ContainsKey($normRoot)) { continue }
        $seenRoots[$normRoot] = $true

        $candidates.Add((Join-Path $normRoot "steamapps\common\$GAME_FOLDER_NAME"))
        $vdfPath = Join-Path $normRoot "steamapps\libraryfolders.vdf"
        if (Test-Path -LiteralPath $vdfPath) {
            $vdfText = Get-Content -LiteralPath $vdfPath -Raw -Encoding UTF8
            $matches = [regex]::Matches($vdfText, '"path"\s+"([^"]+)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            foreach ($m in $matches) {
                $libPath = $m.Groups[1].Value.Replace("\\", "\")
                $candidates.Add((Join-Path $libPath "steamapps\common\$GAME_FOLDER_NAME"))
            }
        }
    }

    foreach ($cand in $candidates) {
        $swfCheck = Join-Path $cand "swf\swords_sandals2_download.swf"
        if (Test-Path -LiteralPath $swfCheck) {
            return $cand
        }
    }
    throw "Could not locate '$GAME_FOLDER_NAME'. Re-run with -GameDir '<path-to-game>'."
}

if ($GenerateManifest) {
    if (-not (Test-Path -LiteralPath $DistSwf)) {
        throw "Co-op SWF not found for manifest generation: $DistSwf"
    }
    $coopItem = Get-Item -LiteralPath $DistSwf
    $coopHash = Get-Sha256Upper -Path $DistSwf
    $manifestObj = [ordered]@{
        stock_swf_name   = "swords_sandals2_download.swf"
        stock_swf_sha256 = $PINNED_STOCK_SHA256
        coop_swf_name    = $coopItem.Name
        coop_swf_sha256  = $coopHash
        coop_swf_size    = [int64]$coopItem.Length
        generated_utc    = [DateTime]::UtcNow.ToString("o")
    }
    $manifestDir = Split-Path -Parent $ManifestPath
    if (-not [string]::IsNullOrWhiteSpace($manifestDir) -and -not (Test-Path -LiteralPath $manifestDir)) {
        New-Item -ItemType Directory -Path $manifestDir -Force | Out-Null
    }
    $jsonOut = $manifestObj | ConvertTo-Json -Depth 4
    [System.IO.File]::WriteAllText($ManifestPath, $jsonOut + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
    Write-Host "[install_coop] Generated manifest: $ManifestPath (coop_swf_sha256=$coopHash)"
    if ([string]::IsNullOrWhiteSpace($GameDir)) {
        exit 0
    }
}

if (-not (Test-Path -LiteralPath $DistSwf)) {
    throw "Co-op SWF not found: $DistSwf"
}
if (-not (Test-Path -LiteralPath $ManifestPath)) {
    throw "Manifest not found: $ManifestPath. Run with -GenerateManifest first."
}

$manifest = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($manifest.coop_swf_sha256)) {
    throw "Manifest '$ManifestPath' is missing 'coop_swf_sha256'."
}
if ($manifest.PSObject.Properties.Name -contains "stock_swf_sha256" -and -not [string]::IsNullOrWhiteSpace($manifest.stock_swf_sha256)) {
    if ($manifest.stock_swf_sha256.ToUpperInvariant() -ne $PINNED_STOCK_SHA256) {
        throw "Manifest stock_swf_sha256 mismatch: expected $PINNED_STOCK_SHA256, got $($manifest.stock_swf_sha256)"
    }
}

$expectedCoopHash = $manifest.coop_swf_sha256.ToUpperInvariant()
$actualCoopHash = Get-Sha256Upper -Path $DistSwf
if ($actualCoopHash -ne $expectedCoopHash) {
    throw "Co-op SWF SHA-256 verification failed! Expected $expectedCoopHash, got $actualCoopHash ($DistSwf)"
}

if ([string]::IsNullOrWhiteSpace($GameDir)) {
    $GameDir = Find-SS2GameDir
}
if (-not (Test-Path -LiteralPath $GameDir)) {
    throw "Game directory does not exist: $GameDir"
}

$swfDir = Join-Path $GameDir "swf"
$targetSwf = Join-Path $swfDir "swords_sandals2_download.swf"
$backupSwf = "$targetSwf.bak"
$markerPath = Join-Path $swfDir "ss2_coop_install.json"

if (-not (Test-Path -LiteralPath $targetSwf)) {
    throw "Target SWF not found: $targetSwf"
}

if (-not (Test-Path -LiteralPath $backupSwf)) {
    $stockHash = Get-Sha256Upper -Path $targetSwf
    if ($stockHash -ne $PINNED_STOCK_SHA256) {
        throw "Stock SWF SHA-256 verification failed! Expected $PINNED_STOCK_SHA256, got $stockHash ($targetSwf). Aborting without modifying game files."
    }
    Copy-Item -LiteralPath $targetSwf -Destination $backupSwf -Force
    $backupVerifyHash = Get-Sha256Upper -Path $backupSwf
    if ($backupVerifyHash -ne $PINNED_STOCK_SHA256) {
        throw "Backup SWF verification failed after copy: $backupSwf"
    }
    Write-Host "[install_coop] Verified stock SWF ($PINNED_STOCK_SHA256) and backed up to $backupSwf"
} else {
    $backupHash = Get-Sha256Upper -Path $backupSwf
    if ($backupHash -ne $PINNED_STOCK_SHA256) {
        throw "Existing backup SWF SHA-256 mismatch! Expected $PINNED_STOCK_SHA256, got $backupHash ($backupSwf). Refusing to overwrite."
    }
    Write-Host "[install_coop] Verified existing stock backup: $backupSwf"
}

Copy-Item -LiteralPath $DistSwf -Destination $targetSwf -Force
$installedHash = Get-Sha256Upper -Path $targetSwf
if ($installedHash -ne $expectedCoopHash) {
    throw "Installed SWF verification failed! Expected $expectedCoopHash, got $installedHash"
}

$markerObj = [ordered]@{
    installed_utc    = [DateTime]::UtcNow.ToString("o")
    stock_swf_sha256 = $PINNED_STOCK_SHA256
    coop_swf_sha256  = $installedHash
    source_swf       = $DistSwf
}
[System.IO.File]::WriteAllText(
    $markerPath,
    ($markerObj | ConvertTo-Json -Depth 4) + [Environment]::NewLine,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host "[install_coop] Installed Co-op SWF ($installedHash) -> $targetSwf"
exit 0
