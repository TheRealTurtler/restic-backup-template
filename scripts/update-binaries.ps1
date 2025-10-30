#requires -version 5.1
$ErrorActionPreference = 'Stop'

# === Load constants and modules ===
. "$PSScriptRoot\constants.ps1"
Import-Module (Join-Path $SCRIPTS_MODULES_DIR "Logging.psm1")
Import-Module (Join-Path $SCRIPTS_MODULES_DIR "GitHub.Releases.psm1")

# === Repositories as constants ===
$REPO_RESTIC = "restic/restic"
$REPO_RESTICPROFILE = "creativeprojects/resticprofile"
$REPO_RESTICBROWSER = "emuell/restic-browser"

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

function Get-InstalledResticBrowserVersion {
	param([string]$ExePath)

	if (-not (Test-Path $ExePath)) { return $null }

	try {
		$startInfo = New-Object System.Diagnostics.ProcessStartInfo
		$startInfo.FileName = $ExePath
		$startInfo.Arguments = "--version"
		$startInfo.UseShellExecute = $false
		$startInfo.RedirectStandardOutput = $true
		$startInfo.RedirectStandardError = $true

		$process = New-Object System.Diagnostics.Process
		$process.StartInfo = $startInfo
		$process.Start() | Out-Null

		$output = $process.StandardOutput.ReadToEnd()
		$process.WaitForExit()

		foreach ($line in ($output -split [Environment]::NewLine)) {
			if ($line -match '^\s*.*?\s*v([0-9.]+)') {
				return $matches[1]
			}
		}
	}
	catch {
		return $null
	}

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
}

if ($latestResticVersion -and $localResticVersion -ne $latestResticVersion) {
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
elseif (-not $latestResticVersion) {
	Write-LogLine "Warning: Version check failed."
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
}

if ($latestProfileVersion -and $localProfileVersion -ne $latestProfileVersion) {
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
elseif (-not $latestProfileVersion) {
	Write-LogLine "Warning: Version check failed."
}
else {
	Write-LogLine "Already up to date."
}

Stop-LogBlock "resticprofile"

# === restic-browser ===
Start-LogBlock "restic-browser"

$browserExe = Join-Path $BIN_DIR "restic-browser.exe"
$localBrowserVersion = Get-InstalledResticBrowserVersion -ExePath $browserExe
$latestBrowserTag = Get-GitHubLatestReleaseTag -Repository $REPO_RESTICBROWSER
$latestBrowserVersion = if ($latestBrowserTag) { $latestBrowserTag -replace '^[^0-9]+', '' } else { $null }

Write-LogLine "Local version:   $localBrowserVersion"
Write-LogLine "Latest version:  $latestBrowserVersion"

if (-not $latestBrowserVersion -and -not $localBrowserVersion) {
	Write-LogLine "Error: Version check failed and no local version available."
	Stop-LogBlock "restic-browser"
	exit 1
}

if ($latestBrowserVersion -and $localBrowserVersion -ne $latestBrowserVersion) {
	$ok = Get-GitHubExecutable `
		-Repository $REPO_RESTICBROWSER `
		-AssetMustContain @("restic-browser", "windows", "zip") `
		-ExecutableMustContain @("restic-browser") `
		-TargetPath $browserExe `
		-ReleaseTag $latestBrowserTag

	if (-not $ok) {
		Write-LogLine "Warning: Failed to download restic-browser."
	}
	else {
		Write-LogLine "Successfully downloaded restic-browser."
	}
}
elseif (-not $latestBrowserVersion) {
	Write-LogLine "Warning: Version check failed."
}
else {
	Write-LogLine "Already installed."
}

Stop-LogBlock "restic-browser"

exit 0
