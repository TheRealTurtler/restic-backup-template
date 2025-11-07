#requires -version 5.1
$ErrorActionPreference = 'Stop'

# === Load constants and required modules ===
. "$PSScriptRoot\constants.ps1"
Import-Module (Join-Path $SCRIPTS_MODULES_DIR "Logging.psm1")
Import-Module (Join-Path $SCRIPTS_MODULES_DIR "GitHub.Releases.psm1")

# === Detect installed version of a tool ===
# Executes the binary with given arguments and extracts version using either JSON or regex
function Get-InstalledVersion {
	param(
		[string]$ExePath,
		[string[]]$Arguments,
		[ValidateSet('json', 'regex')][string]$Decoder,
		[string]$DecoderParam
	)

	if (-not (Test-Path $ExePath)) { return $null }

	try {
		$psi = New-Object System.Diagnostics.ProcessStartInfo
		$psi.FileName = $ExePath
		$psi.Arguments = ($Arguments -join ' ')
		$psi.UseShellExecute = $false
		$psi.RedirectStandardOutput = $true
		$psi.RedirectStandardError = $true

		$p = New-Object System.Diagnostics.Process
		$p.StartInfo = $psi
		$p.Start() | Out-Null
		$out = $p.StandardOutput.ReadToEnd()
		$p.WaitForExit()

		switch ($Decoder) {
			'json' {
				$json = $out | ConvertFrom-Json
				return $json.$DecoderParam
			}
			'regex' {
				foreach ($line in ($out -split "`r?`n")) {
					if ($line -match $DecoderParam) { return $matches[1] }
				}
			}
		}
	}
	catch {
		return $null
	}

	return $null
}

# === Return tool specification object ===
# Includes binary path, GitHub repository, version decoder, and asset filters
function Get-ToolSpec {
	param([ValidateSet('restic', 'resticprofile', 'restic-browser')][string]$Name)

	switch ($Name) {
		'restic' {
			[pscustomobject]@{
				Name                  = 'restic'
				ExePath               = Join-Path $BIN_DIR 'restic.exe'
				Repository            = 'restic/restic'
				GetLocalVersion       = { Get-InstalledVersion -ExePath $args[0] -Arguments @('version', '--json') -Decoder json -DecoderParam 'version' }
				AssetMustContain      = @("restic", "windows_amd64", "zip")
				ExecutableMustContain = @("restic", "exe")
			}
		}
		'resticprofile' {
			[pscustomobject]@{
				Name                  = 'resticprofile'
				ExePath               = Join-Path $BIN_DIR 'resticprofile.exe'
				Repository            = 'creativeprojects/resticprofile'
				GetLocalVersion       = { Get-InstalledVersion -ExePath $args[0] -Arguments @('version', '-v') -Decoder regex -DecoderParam '^\s*version:\s*([0-9.]+)' }
				AssetMustContain      = @("resticprofile", "windows_amd64", "zip")
				ExecutableMustContain = @("resticprofile", "exe")
			}
		}
		'restic-browser' {
			[pscustomobject]@{
				Name                  = 'restic-browser'
				ExePath               = Join-Path $BIN_DIR 'restic-browser.exe'
				Repository            = 'emuell/restic-browser'
				GetLocalVersion       = { Get-InstalledVersion -ExePath $args[0] -Arguments @('--version') -Decoder regex -DecoderParam '^\s*.*?\s*v([0-9.]+)' }
				AssetMustContain      = @("restic-browser", "windows", "zip")
				ExecutableMustContain = @("restic-browser", "exe")
			}
		}
	}
}

# === Download tool if not already present ===
function Initialize-Tool {
	param([object]$Spec)

	if (Test-Path $Spec.ExePath) { return }

	Start-LogBlock "$($Spec.Name)"

	$latestTag = Get-GitHubLatestReleaseTag -Repository $Spec.Repository
	if (-not $latestTag) {
		Write-LogLine "Error: Could not determine latest release for $($Spec.Name)."
		Stop-LogBlock "$($Spec.Name)"
		exit 1
	}

	$ok = Get-GitHubExecutable `
		-Repository $Spec.Repository `
		-AssetMustContain $Spec.AssetMustContain `
		-ExecutableMustContain $Spec.ExecutableMustContain `
		-TargetPath $Spec.ExePath `
		-ReleaseTag $latestTag

	if (-not $ok) {
		Write-LogLine "Error: Failed to download $($Spec.Name)."
		Stop-LogBlock "$($Spec.Name)"
		exit 1
	}

	Write-LogLine "Successfully downloaded $($Spec.Name)."
	Stop-LogBlock "$($Spec.Name)"
}

# === Update tool if newer version is available ===
function Update-Tool {
	param([object]$Spec)

	Start-LogBlock $Spec.Name

	$localVersion = & $Spec.GetLocalVersion $Spec.ExePath
	$latestTag = Get-GitHubLatestReleaseTag -Repository $Spec.Repository
	$latestVersion = if ($latestTag) { $latestTag -replace '^[^0-9]+', '' } else { $null }

	Write-LogLine "Local version:   $localVersion"
	Write-LogLine "Latest version:  $latestVersion"

	if (-not $latestVersion -and -not $localVersion) {
		Write-LogLine "Error: Version check failed and no local version available."
		Stop-LogBlock $Spec.Name
		exit 1
	}

	if ($latestVersion -and $localVersion -ne $latestVersion) {
		$ok = Get-GitHubExecutable `
			-Repository $Spec.Repository `
			-AssetMustContain $Spec.AssetMustContain `
			-ExecutableMustContain $Spec.ExecutableMustContain `
			-TargetPath $Spec.ExePath `
			-ReleaseTag $latestTag

		if (-not $ok) {
			if (-not $localVersion) {
				Write-LogLine "Error: Download failed and no local version available."
				Stop-LogBlock $Spec.Name
				exit 1
			}
			Write-LogLine "Warning: Failed to download update, keeping existing version."
		}
		else {
			Write-LogLine "Successfully updated $($Spec.Name)."
		}
	}
	elseif (-not $latestVersion) {
		Write-LogLine "Warning: Version check failed."
	}
	else {
		Write-LogLine "Already up to date."
	}

	Stop-LogBlock $Spec.Name
}

# === Batch initialization and update ===
$TOOLS = @('restic', 'resticprofile', 'restic-browser')

function Initialize-AllTools {
	foreach ($t in $TOOLS) {
		Initialize-Tool (Get-ToolSpec -Name $t)
	}
}

function Update-AllTools {
	foreach ($t in $TOOLS) {
		Update-Tool (Get-ToolSpec -Name $t)
	}
}

# === Direct execution: initialize all, then update only pre-existing tools ===
if ($MyInvocation.InvocationName -ne '.') {
	$preExisting = @{}
	foreach ($t in $TOOLS) {
		$spec = Get-ToolSpec -Name $t
		$preExisting[$t] = Test-Path $spec.ExePath
	}

	Initialize-AllTools

	foreach ($t in $TOOLS) {
		if ($preExisting[$t]) {
			Update-Tool (Get-ToolSpec -Name $t)
		}
	}

	exit 0
}
