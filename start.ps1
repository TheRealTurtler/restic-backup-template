#requires -version 5.1
$ErrorActionPreference = 'Stop'

# === Load constants and modules ===
. "$PSScriptRoot\scripts\constants.ps1"
Import-Module (Join-Path $SCRIPTS_MODULES_DIR "Logging.psm1")

# === Script paths ===
$SCRIPT_SETUP_REPO = Join-Path $SCRIPTS_DIR "setup-repo.ps1"
$SCRIPT_RUN_BACKUP = Join-Path $SCRIPTS_DIR "run-backup.ps1"
$SCRIPT_OPEN_BROWSER = Join-Path $SCRIPTS_DIR "open-browser.ps1"
$SCRIPT_UPDATE_BINARIES = Join-Path $SCRIPTS_DIR "update-binaries.ps1"

# === Load functions from scripts ===
. $SCRIPT_UPDATE_BINARIES
. $SCRIPT_SETUP_REPO

# === Central config/template files ===
$ProfileConfigFile = Join-Path $CONF_PROFILES_USER_DIR  "01_default_repo.yaml"
$TemplateConfigFile = Join-Path $CONF_TEMPLATES_DIR "01_default_repo.yaml"

# === Default settings ===
$DefaultRepoProfile = "userdata"
$DefaultRepoSnapshot = "latest"

# === Initialize required tools/binaries ===
Initialize-AllTools

# === Load or initialize repository configuration ===
$configVars = Initialize-RepoConfig -TemplateFile $TemplateConfigFile -ConfigFile $ProfileConfigFile
if (-not $configVars) {
	Write-LogLine "Configuration invalid after setup. Aborting."
	exit 1
}

# === Main Menu ===
function Show-MainMenu {
	Write-Host ""
	Write-Host "=== Backup Menu ==="
	Write-Host "1) Restic operations"
	Write-Host "2) Open backup browser"
	Write-Host "3) Change settings"
	Write-Host "4) Show current repository config"
	Write-Host "5) Update binaries"
	Write-Host "6) Exit"
}

# === Operation Menu ===
function Show-OperationMenu {
	Write-Host ""
	Write-Host "=== Profile Operations ==="
	Write-Host " 1) show        - Display profile configuration"
	Write-Host " 2) init        - Initialize repository for profile"
	Write-Host " 3) backup      - Run backup for profile"
	Write-Host " 4) snapshots   - List available snapshots"
	Write-Host " 5) forget      - Remove snapshot references"
	Write-Host " 6) prune       - Clean up unreferenced data"
	Write-Host " 7) check       - Verify repository integrity"
	Write-Host " 8) ls          - List files in snapshot"
	Write-Host " 9) schedule    - Register scheduled backup task"
	Write-Host "10) unschedule  - Remove scheduled backup task"
	Write-Host "11) custom      - Manual input for operation"
	Write-Host "12) cancel      - Return to main menu"
}

# TODO: Add support for remaining commands
#"XX" { $profileOperation = "restore" }
#"XX" { $profileOperation = "dump" }
#"XX" { $profileOperation = "cat" }
#"XX" { $profileOperation = "diff" }
#"XX" { $profileOperation = "tag" }
#"XX" { $profileOperation = "mount" }

# === Invoke run-backup.ps1 ===
# Wrapper function to start run-backup.ps1 with or without elevation.
function Invoke-RunBackup {
	param(
		[string]$ProfileName,
		[string]$Operation,
		[string[]]$ExtraArgs,
		[bool]$RequireAdmin = $false
	)

	# Direct invocation if no elevation required
	if (-not $RequireAdmin) {
		if (-not $ExtraArgs) {
			& $SCRIPT_RUN_BACKUP -ProfileName $ProfileName -Operation $Operation
		}
		else {
			& $SCRIPT_RUN_BACKUP -ProfileName $ProfileName -Operation $Operation -ExtraArgs $ExtraArgs
		}
		return
	}

	# Build process start info
	$psi = New-Object System.Diagnostics.ProcessStartInfo
	$psi.FileName = "powershell.exe"

	# Set working directory to script root
	$psi.WorkingDirectory = $PSScriptRoot

	# Construct arguments
	$psi.Arguments = "-ExecutionPolicy Bypass -File `"$SCRIPT_RUN_BACKUP`" -ProfileName `"$ProfileName`" -Operation `"$Operation`""
	if ($ExtraArgs) {
		$psi.Arguments += " -ExtraArgs " + ($ExtraArgs -join ' ')
	}

	# Elevation only if explicitly requested
	if ($RequireAdmin) {
		$psi.Verb = "runas"
	}

	# Try to start elevated process
	try {
		$process = [System.Diagnostics.Process]::Start($psi)
		if (-not $process) {
			Write-Warning "Execution was cancelled. UAC prompt may have been declined."
		}
	}
	catch {
		Write-Warning "Failed to start process with elevated privileges: $_"
	}
}

# === Main loop ===
do {
	Show-MainMenu
	$choice = Read-Host "Enter number"

	switch ($choice) {
		"1" {
			# Profile name
			$profileName = Read-Host "Enter profile name (default: $DefaultRepoProfile)"
			if ([string]::IsNullOrWhiteSpace($profileName)) {
				$profileName = $DefaultRepoProfile
			}

			$backToMainMenu = $false

			# Operation selection loop
			$profileOperation = $null
			do {
				Show-OperationMenu
				$opChoice = Read-Host "Select operation"

				switch ($opChoice) {
					"1" { $profileOperation = "show" }
					"2" { $profileOperation = "init" }
					"3" { $profileOperation = "backup" }
					"4" { $profileOperation = "snapshots" }
					"5" { $profileOperation = "forget" }
					"6" { $profileOperation = "prune" }
					"7" { $profileOperation = "check" }
					"8" { $profileOperation = "ls" }
					"9" { $profileOperation = "schedule" }
					"10" { $profileOperation = "unschedule" }
					"11" {
						$customInput = Read-Host "Enter custom operation with arguments"
						if ($customInput) {
							$parts = $customInput -split '\s+', 2
							$profileOperation = $parts[0]
							if ($parts.Count -gt 1) {
								$extraArgs = $parts[1] -split '\s+'
							}
						}
					}
					"12" { $backToMainMenu = $true; }
					default { Write-Host "Invalid choice." }
				}
			} until ($profileOperation -or $backToMainMenu)

			if ($backToMainMenu) {
				continue
			}

			if ($profileOperation) {
				# Optional snapshot ID for certain operations
				if (-not $extraArgs -and $profileOperation -in @("restore", "ls", "dump", "cat", "diff", "tag", "mount")) {
					$snapshot = Read-Host "Enter snapshot ID (default: $DefaultRepoSnapshot)"
					if ([string]::IsNullOrWhiteSpace($snapshot)) {
						$snapshot = $DefaultRepoSnapshot
					}
					$extraArgs = @($snapshot)
				}

				$requireAdmin = $profileOperation -in @("schedule", "unschedule")

				# Run backup script
				Invoke-RunBackup -ProfileName $profileName -Operation $profileOperation -ExtraArgs $extraArgs -RequireAdmin $requireAdmin
			}
		}
		"2" {
			# Profile name
			$profileName = Read-Host "Enter profile name (default: $DefaultRepoProfile)"
			if ([string]::IsNullOrWhiteSpace($profileName)) {
				$profileName = $DefaultRepoProfile
			}

			$repoPath = "$($configVars["REPO_TYPE"]):$($configVars["REPO_DIR"])$($profileName)"
			$passwordFile = Join-Path $SECRETS_DIR $configVars["PASSWORD_FILE"]

			& $SCRIPT_OPEN_BROWSER -RepoPath $repoPath -PasswordFile $passwordFile
		}
		"3" {
			Show-RepoConfigMenu -ConfigVars $configVars -TemplateFile $TemplateConfigFile -ConfigFile $ProfileConfigFile
			$configVars = Get-RepoConfig -ConfigFile $ProfileConfigFile
			if (-not (Test-RepoConfigValidity -ConfigVars $configVars)) {
				Write-LogLine "Configuration invalid after changes. Please re-run settings."
			}
			else {
				Write-LogLine "Configuration updated."
			}
		}
		"4" {
			Start-LogBlock "Current Repository Config"
			Write-LogLine ("REPO_TYPE     : {0}" -f $configVars["REPO_TYPE"])
			Write-LogLine ("REPO_DIR      : {0}" -f $configVars["REPO_DIR"])
			Write-LogLine ("PASSWORD_FILE : {0}" -f $configVars["PASSWORD_FILE"])
			Stop-LogBlock "Current Repository Config"
		}
		"5" {
			Update-AllTools
		}
		"6" {
			break
		}
		default {
			Write-Host "Invalid choice."
		}
	}
} until ($choice -eq "6")

exit 0
