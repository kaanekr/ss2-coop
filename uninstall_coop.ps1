<#
.SYNOPSIS
    Restores the stock Swords and Sandals 2 SWF from backup and removes Co-op install metadata.
#>
[CmdletBinding()]
param(
    [string]$GameDir = "",
    [switch]$SkipAppDataCfg
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$PINNED_STOCK_SHA256 = "77CB545C2061AB41246251467A4EDF5926AB6FD1DDD95DC9527D7BA9C45BB8CA"
$GAME_FOLDER_NAME = "Swords and Sandals Classic Collection"

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

if (Test-Path -LiteralPath $backupSwf) {
    $backupHash = Get-Sha256Upper -Path $backupSwf
    if ($backupHash -ne $PINNED_STOCK_SHA256) {
        throw "Backup SWF SHA-256 mismatch! Expected $PINNED_STOCK_SHA256, got $backupHash ($backupSwf)."
    }
    Copy-Item -LiteralPath $backupSwf -Destination $targetSwf -Force
    $restoredHash = Get-Sha256Upper -Path $targetSwf
    if ($restoredHash -ne $PINNED_STOCK_SHA256) {
        throw "Restored SWF verification failed! Expected $PINNED_STOCK_SHA256, got $restoredHash"
    }
    Remove-Item -LiteralPath $backupSwf -Force
    Write-Host "[uninstall_coop] Restored stock SWF ($restoredHash) and removed backup $backupSwf"
} elseif ((Test-Path -LiteralPath $targetSwf) -and ((Get-Sha256Upper -Path $targetSwf) -eq $PINNED_STOCK_SHA256)) {
    Write-Host "[uninstall_coop] Stock SWF ($PINNED_STOCK_SHA256) is already in place."
} else {
    throw "Cannot uninstall: backup '$backupSwf' not found and '$targetSwf' does not match stock SHA-256."
}

if (Test-Path -LiteralPath $markerPath) {
    Remove-Item -LiteralPath $markerPath -Force
    Write-Host "[uninstall_coop] Removed install marker $markerPath"
}

if (-not $SkipAppDataCfg -and -not [string]::IsNullOrWhiteSpace($env:APPDATA)) {
    $soRoots = @(
        (Join-Path $env:APPDATA "Macromedia\Flash Player\#SharedObjects"),
        (Join-Path $env:APPDATA "com.game.whiskeybarrelstudios.swordsandsandalsclassic\Local Store\#SharedObjects")
    )
    foreach ($soRoot in $soRoots) {
        if (Test-Path -LiteralPath $soRoot) {
            Get-ChildItem -LiteralPath $soRoot -Filter "ss2_coop_cfg.sol" -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
                Remove-Item -LiteralPath $_.FullName -Force
                Write-Host "[uninstall_coop] Removed co-op config $($_.FullName)"
            }
        }
    }
}

Write-Host "[uninstall_coop] Uninstall complete."
exit 0
