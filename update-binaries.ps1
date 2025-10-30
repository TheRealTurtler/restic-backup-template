#requires -version 5.1
$ErrorActionPreference = 'Stop'

# === Load constants and modules ===
. "$PSScriptRoot\scripts\constants.ps1"
Import-Module (Join-Path $SCRIPTS_MODULES_DIR "Logging.psm1")
Import-Module (Join-Path $SCRIPTS_MODULES_DIR "GitHub.Releases.psm1")

# === Repositories as constants ===
$REPO_RESTIC = "restic/restic"
$REPO_RESTICPROFILE = "creativeprojects/resticprofile"

# === Version check functions ===

function Get-InstalledResticVersion {
	param([string]$ExePath)
	if (-not (Test-Path $ExePath)) { return $null }
	try {
		$json = & $ExePath "version" "--json" 2>$null | ConvertFrom-Json
		return $json.version
	}
 catch { return $null }
}

function Get-InstalledResticProfileVersion {
	param([string]$ExePath)
	if (-not (Test-Path $ExePath)) { return $null }
	try {
		$output = & $ExePath "version" "-v" 2>$null
		foreach ($line in $output) {
			if ($line -match '^\s*version:\s*([0-9.]+)') {
				return $matches[1]
			}
		}
	}
 catch { return $null }
	return $null
}

# === restic ===
Start-LogBlock "restic"

$resticExe = Join-Path $BIN_DIR "restic.exe"
$localResticVersion = Get-InstalledResticVersion -ExePath $resticExe
$latestResticTag = Get-GitHubLatestReleaseTag -Repository $REPO_RESTIC
$latestResticVersion = if ($latestResticTag) { $latestResticTag -replace '^[^0-9]+', '' } else { $null }

Write-LogLine "Local version:   $localResticVersion"
Write-LogLine "Latest version:  $latestResticVersion"

if (-not $latestResticVersion -and -not $localResticVersion) {
	Write-LogLine "Error: Version check failed and no local version available."
	Stop-LogBlock "restic"
	exit 1
}if ($latestResticVersion -and $localResticVersion -ne $latestResticVersion) {
	$ok = Get-GitHubExecutable `
		-Repository $REPO_RESTIC `
		-AssetMustContain @("restic", "windows_amd64", "zip") `
		-ExecutableMustContain @("restic", "exe") `
		-TargetPath $resticExe `
		-ReleaseTag $latestResticTag

	if (-not $ok) {
		if (-not $localResticVersion) {
			Write-LogLine "Error: Download failed and no local version available."
			Stop-LogBlock "restic"
			exit 1
		}
		Write-LogLine "Warning: Failed to download update, keeping existing version."
	}
	elseif ($ok) {
		Write-LogLine "Successfully updated restic."
	}
}
else {
	Write-LogLine "Already up to date."
}

Stop-LogBlock "restic"

# === resticprofile ===
Start-LogBlock "resticprofile"

$profileExe = Join-Path $BIN_DIR "resticprofile.exe"
$localProfileVersion = Get-InstalledResticProfileVersion -ExePath $profileExe
$latestProfileTag = Get-GitHubLatestReleaseTag -Repository $REPO_RESTICPROFILE
$latestProfileVersion = if ($latestProfileTag) { $latestProfileTag -replace '^[^0-9]+', '' } else { $null }

Write-LogLine "Local version:   $localProfileVersion"
Write-LogLine "Latest version:  $latestProfileVersion"

if (-not $latestProfileVersion -and -not $localProfileVersion) {
	Write-LogLine "Error: Version check failed and no local version available."
	Stop-LogBlock "resticprofile"
	exit 1
}if ($latestProfileVersion -and $localProfileVersion -ne $latestProfileVersion) {
	$ok = Get-GitHubExecutable `
		-Repository $REPO_RESTICPROFILE `
		-AssetMustContain @("resticprofile", "windows_amd64", "zip") `
		-ExecutableMustContain @("resticprofile", "exe") `
		-TargetPath $profileExe `
		-ReleaseTag $latestProfileTag

	if (-not $ok) {
		if (-not $localProfileVersion) {
			Write-LogLine "Error: Download failed and no local version available."
			Stop-LogBlock "resticprofile"
			exit 1
		}
		Write-LogLine "Warning: Failed to download update, keeping existing version."
	}
	elseif ($ok) {
		Write-LogLine "Successfully updated resticprofile."
	}
}
else {
	Write-LogLine "Already up to date."
}

Stop-LogBlock "resticprofile"

exit 0
