#requires -version 5.1
$ErrorActionPreference = 'Stop'

# === Load constants and modules ===
. "$PSScriptRoot\scripts\constants.ps1"
Import-Module (Join-Path $SCRIPTS_MODULES_DIR "Logging.psm1")

# === Other scripts ===
$SCRIPT_SETUP_REPO = Join-Path $SCRIPTS_DIR "setup-repo.ps1"
$SCRIPT_RUN_BACKUP = Join-Path $SCRIPTS_DIR "run-backup.ps1"
$SCRIPT_OPEN_BROWSER = Join-Path $SCRIPTS_DIR "open-browser.ps1"
$SCRIPT_GEN_PASS = Join-Path $SCRIPTS_DIR "generate-password.ps1"
$SCRIPT_REPO_CONFIG = Join-Path $SCRIPTS_DIR "repo-config.ps1"
$SCRIPT_UPDATE_BINARIES = Join-Path $SCRIPTS_DIR "update-binaries.ps1"

# === Load functions from other scripts ===
. $SCRIPT_UPDATE_BINARIES
. $SCRIPT_REPO_CONFIG

# Path to the profile config file
$profileConfigFile = Join-Path $CONF_PROFILES_DIR "01_default_repo.yaml"
$templateConfigFile = Join-Path $CONF_TEMPLATES_DIR "01_default_repo.yaml"

# === Ensure all required binaries exist ===
Ensure-AllTools

# === Load and validate config ===
$configVars = Get-ConfigVariables -ConfigFile $profileConfigFile

if (-not (Test-ConfigValid -ConfigVars $configVars)) {
	Write-Host "Config invalid or missing. Running setup-repo.ps1..."
	& $SCRIPT_SETUP_REPO
	exit 1
}

# === Menu loop ===
function Show-Menu {
	Write-Host ""
	Write-Host "=== Backup Menu ==="
	Write-Host "1) Run backup"
	Write-Host "2) Open backup browser"
	Write-Host "3) Generate new password"
	Write-Host "4) Change repository settings"
	Write-Host "5) Update binaries"
	Write-Host "6) Exit"
}

do {
	Show-Menu
	$choice = Read-Host "Enter number"

	switch ($choice) {
		"1" {
			& $SCRIPT_RUN_BACKUP
		}
		"2" {
			& $SCRIPT_OPEN_BROWSER
		}
		"3" {
			& $SCRIPT_GEN_PASS -Filename $configVars[$CONFIG_KEY_PASSWORD_FILE] -ByteSize 1024
		}

		"4" {
			& $SCRIPT_SETUP_REPO
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
