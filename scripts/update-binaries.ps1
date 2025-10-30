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

function Update-Tool {
	param(
		[string]$Name,
		[string]$ExePath,
		[string]$Repository,
		[ScriptBlock]$GetLocalVersion,
		[string[]]$AssetMustContain,
		[string[]]$ExecutableMustContain
	)

	Start-LogBlock $Name

	$localVersion = & $GetLocalVersion $ExePath
	$latestTag = Get-GitHubLatestReleaseTag -Repository $Repository
	$latestVersion = if ($latestTag) { $latestTag -replace '^[^0-9]+', '' } else { $null }

	Write-LogLine "Local version:   $localVersion"
	Write-LogLine "Latest version:  $latestVersion"

	if (-not $latestVersion -and -not $localVersion) {
		Write-LogLine "Error: Version check failed and no local version available."
		Stop-LogBlock $Name
		exit 1
	}

	if ($latestVersion -and $localVersion -ne $latestVersion) {
		$ok = Get-GitHubExecutable `
			-Repository $Repository `
			-AssetMustContain $AssetMustContain `
			-ExecutableMustContain $ExecutableMustContain `
			-TargetPath $ExePath `
			-ReleaseTag $latestTag

		if (-not $ok) {
			if (-not $localVersion) {
				Write-LogLine "Error: Download failed and no local version available."
				Stop-LogBlock $Name
				exit 1
			}
			Write-LogLine "Warning: Failed to download update, keeping existing version."
		}
		else {
			Write-LogLine "Successfully updated $Name."
		}
	}
	elseif (-not $latestVersion) {
		Write-LogLine "Warning: Version check failed."
	}
	else {
		Write-LogLine "Already up to date."
	}

	Stop-LogBlock $Name
}

Update-Tool `
	-Name "restic" `
	-ExePath (Join-Path $BIN_DIR "restic.exe") `
	-Repository $REPO_RESTIC `
	-GetLocalVersion ${function:Get-InstalledResticVersion} `
	-AssetMustContain @("restic", "windows_amd64", "zip") `
	-ExecutableMustContain @("restic", "exe")

Update-Tool `
	-Name "resticprofile" `
	-ExePath (Join-Path $BIN_DIR "resticprofile.exe") `
	-Repository $REPO_RESTICPROFILE `
	-GetLocalVersion ${function:Get-InstalledResticProfileVersion} `
	-AssetMustContain @("resticprofile", "windows_amd64", "zip") `
	-ExecutableMustContain @("resticprofile", "exe")

Update-Tool `
	-Name "restic-browser" `
	-ExePath (Join-Path $BIN_DIR "restic-browser.exe") `
	-Repository $REPO_RESTICBROWSER `
	-GetLocalVersion ${function:Get-InstalledResticBrowserVersion} `
	-AssetMustContain @("restic-browser", "windows", "zip") `
	-ExecutableMustContain @("restic-browser", "exe")

exit 0
