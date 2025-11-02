#requires -version 5.1
$ErrorActionPreference = 'Stop'

# === Load constants and modules ===
. "$PSScriptRoot\constants.ps1"
Import-Module (Join-Path $SCRIPTS_MODULES_DIR "PathValidation.psm1") -Force

# === Load repo config functions ===
$SCRIPT_REPO_CONFIG = Join-Path $SCRIPTS_DIR "repo-config.ps1"
$SCRIPT_GENERATE_PASSWORD = Join-Path $SCRIPTS_DIR "generate-password.ps1"

. $SCRIPT_REPO_CONFIG

# === Define config keys ===
$CONFIG_KEY_REPO_TYPE = "REPO_TYPE"
$CONFIG_KEY_REPO_DIR = "REPO_DIR"
$CONFIG_KEY_PASSWORD_FILE = "PASSWORD_FILE"

$REQUIRED_KEYS = @(
	$CONFIG_KEY_REPO_TYPE,
	$CONFIG_KEY_REPO_DIR,
	$CONFIG_KEY_PASSWORD_FILE
)

# === Prompt user for and normalize a directory path ===
function Read-ValidatedPath {
	param([string]$PromptText)
	$inputPath = Read-Host $PromptText
	$normalized = Convert-Directory $inputPath
	if (-not $normalized) {
		Write-Host "Invalid path."
		return $null
	}
	return $normalized
}

# === Prompt user for and validate a .secret file path ===
function Read-ValidatedSecretFilePath {
	param([string]$PromptText)
	$inputPath = Read-Host $PromptText
	if (-not $inputPath.EndsWith(".secret")) {
		Write-Host "File must end with .secret"
		return $null
	}

	$validated = Convert-Path $inputPath
	if (-not $validated) {
		Write-Host "Invalid secret file path."
		return $null
	}
	return $validated
}

# === Configure local repository path ===
function Set-RepoConfigLocal {
	param([hashtable]$ConfigVars)
	$normalized = Read-ValidatedPath -PromptText "Enter local repository path"
	if ($normalized) {
		$ConfigVars[$CONFIG_KEY_REPO_TYPE] = "local"
		$ConfigVars[$CONFIG_KEY_REPO_DIR] = $normalized
	}
	return $ConfigVars
}

# === Configure SFTP repository path ===
function Set-RepoConfigSftp {
	param([hashtable]$ConfigVars)
	$user = Read-Host "Enter SFTP username"
	$password = Read-Host "Enter SFTP password"
	$sftpHost = Read-Host "Enter SFTP host (e.g. example.com)"
	$normalized = Read-ValidatedPath -PromptText "Enter SFTP repository path (e.g. /backups/projectA)"
	if ($normalized) {
		$ConfigVars[$CONFIG_KEY_REPO_TYPE] = "sftp"
		$ConfigVars[$CONFIG_KEY_REPO_DIR] = "${user}:${password}@${sftpHost}:${normalized}"
	}
	return $ConfigVars
}

# === Configure password file (create or select) ===
function Set-PasswordFile {
	param([hashtable]$ConfigVars)

	Write-Host ""
	Write-Host "Password file options:"
	Write-Host "1) Create new secret file"
	Write-Host "2) Enter existing secret file"
	$choice = Read-Host "Enter number"

	switch ($choice) {
		"1" {
			$baseName = Read-Host "Enter base name (e.g. restic_username)"
			if ([string]::IsNullOrWhiteSpace($baseName)) {
				Write-Host "Invalid base name."
				return $ConfigVars
			}

			$fileName = "$baseName.secret"
			$validated = Convert-FileName $fileName
			if (-not $validated) {
				Write-Host "Invalid secret file name."
				return $ConfigVars
			}

			$ConfigVars[$CONFIG_KEY_PASSWORD_FILE] = $validated
			& $SCRIPT_GENERATE_PASSWORD -Filename $validated -ByteSize 1024
		}
		"2" {
			$secretPath = Read-ValidatedSecretFilePath -PromptText "Enter existing secret file path (ending with .secret)"
			if ($secretPath) {
				$ConfigVars[$CONFIG_KEY_PASSWORD_FILE] = $secretPath
			}
		}
		default {
			Write-Host "Invalid choice."
		}
	}

	return $ConfigVars
}

# === Interactive wizard for initial repository setup ===
function Start-RepoWizard {
	param([hashtable]$ConfigVars)

	Write-Host ""
	Write-Host "=== Repository Setup Wizard ==="
	Write-Host "1) Local repository"
	Write-Host "2) SFTP repository"
	$typeChoice = Read-Host "Enter number"

	switch ($typeChoice) {
		"1" { $ConfigVars = Set-RepoConfigLocal -ConfigVars $ConfigVars }
		"2" { $ConfigVars = Set-RepoConfigSftp  -ConfigVars $ConfigVars }
		default { Write-Host "Invalid choice."; return $null }
	}

	$ConfigVars = Set-PasswordFile -ConfigVars $ConfigVars
	return $ConfigVars
}

# === Menu for editing existing repository configuration ===
function Show-EditMenu {
	Write-Host ""
	Write-Host "=== Edit repository settings ==="
	Write-Host "1) Change repository settings"
	Write-Host "2) Change password file"
	Write-Host "3) Save and exit"
	Write-Host "4) Cancel"
}

function Show-RepoConfigMenu {
	param(
		[hashtable]$ConfigVars,
		[string]$TemplateFile,
		[string]$ConfigFile
	)

	do {
		Show-EditMenu
		$choice = Read-Host "Enter number"

		switch ($choice) {
			"1" {
				Write-Host ""
				Write-Host "Select repository type:"
				Write-Host "1) Local repository"
				Write-Host "2) SFTP repository"
				$typeChoice = Read-Host "Enter number"
				switch ($typeChoice) {
					"1" { $ConfigVars = Set-RepoConfigLocal -ConfigVars $ConfigVars }
					"2" { $ConfigVars = Set-RepoConfigSftp  -ConfigVars $ConfigVars }
					default { Write-Host "Invalid choice." }
				}
			}
			"2" {
				$ConfigVars = Set-PasswordFile -ConfigVars $ConfigVars
			}
			"3" {
				if (Test-RepoConfigValidity -ConfigVars $ConfigVars -RequiredKeys $REQUIRED_KEYS) {
					New-RepoConfigFromTemplate -TemplateFile $TemplateFile -OutputFile $ConfigFile -ConfigVars $ConfigVars
					Write-Host "Configuration saved to $ConfigFile"
				}
				else {
					Write-Host "Configuration invalid. Please fix missing or empty values."
				}
				break
			}
			"4" {
				Write-Host "Cancelled. No changes saved."
				break
			}
			default {
				Write-Host "Invalid choice."
			}
		}
	} until ($choice -eq "3" -or $choice -eq "4")
}

# === Load or initialize repository config ===
function Initialize-RepoConfig {
	param(
		[string]$TemplateFile,
		[string]$ConfigFile
	)

	$configVars = Get-RepoConfig -ConfigFile $ConfigFile

	if (-not (Test-RepoConfigValidity -ConfigVars $configVars -RequiredKeys $REQUIRED_KEYS)) {
		Write-Host "No valid repository configuration found. Starting setup wizard..."
		$configVars = Start-RepoWizard -ConfigVars @{}
		if ($configVars -and (Test-RepoConfigValidity -ConfigVars $configVars -RequiredKeys $REQUIRED_KEYS)) {
			New-RepoConfigFromTemplate -TemplateFile $TemplateFile -OutputFile $ConfigFile -ConfigVars $configVars
			Write-Host "Configuration created via wizard."
		}
		else {
			Write-Host "Wizard aborted or invalid input."
			return $null
		}
	}

	return $configVars
}
