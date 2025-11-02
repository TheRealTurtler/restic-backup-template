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
$ProfileConfigFile = Join-Path $CONF_PROFILES_DIR  "01_default_repo.yaml"
$TemplateConfigFile = Join-Path $CONF_TEMPLATES_DIR "01_default_repo.yaml"

$DefaultRepoProfile = "userdata"

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
	Write-Host "1) Run backup"
	Write-Host "2) Open backup browser"
	Write-Host "3) Change repository settings"
	Write-Host "4) Show current repository config"
	Write-Host "5) Update binaries"
	Write-Host "6) Exit"
}

do {
	Show-MainMenu
	$choice = Read-Host "Enter number"

	switch ($choice) {
		"1" {
			& $SCRIPT_RUN_BACKUP
		}
		"2" {
			$repoPath = "$($configVars["REPO_TYPE"]):$($configVars["REPO_DIR"])$($DefaultRepoProfile)"
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
