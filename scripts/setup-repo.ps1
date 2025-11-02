#requires -version 5.1
param(
	[Parameter(Mandatory = $true)]
	[string]$TemplateFile,

	[Parameter(Mandatory = $true)]
	[string]$ConfigFile
)

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\constants.ps1"
. (Join-Path $SCRIPTS_DIR "repo-config.ps1")

Import-Module (Join-Path $SCRIPTS_MODULES_DIR "PathValidation.psm1") -Force

$CONFIG_KEY_REPO_TYPE = "REPO_TYPE"
$CONFIG_KEY_REPO_DIR = "REPO_DIR"
$CONFIG_KEY_PASSWORD_FILE = "PASSWORD_FILE"

# --- Hilfsfunktion für Pfade ---
function Read-ValidatedPath {
	param([string]$PromptText = "Enter path")

	$inputPath = Read-Host $PromptText
	$normalized = Convert-Directory $inputPath
	if (-not $normalized) {
		Write-Host "Invalid path."
		return $null
	}
	return $normalized
}

function Read-ValidatedSecretFilePath {
	param([string]$PromptText = "Enter secret file path")

	$inputPath = Read-Host $PromptText
	if (-not $inputPath.EndsWith(".secret")) {
		Write-Host "File must end with .secret"
		return $null
	}

	$validated = $null
	if (Get-Command Convert-FilePath -ErrorAction SilentlyContinue) {
		$validated = Convert-FilePath $inputPath
	}
 else {
		$validated = Convert-FileName (Split-Path $inputPath -Leaf)
		if ($validated) {
			$dir = Split-Path $inputPath -Parent
			$validated = (Join-Path $dir $validated)
		}
	}

	if (-not $validated) {
		Write-Host "Invalid secret file path."
		return $null
	}
	return $validated
}

# --- Repo-Einstellungen: LOCAL ---
function Set-RepoConfigLocal {
	param([hashtable]$ConfigVars)

	$normalized = Read-ValidatedPath -PromptText "Enter local repository path"
	if ($normalized) {
		$ConfigVars[$CONFIG_KEY_REPO_TYPE] = "local"
		$ConfigVars[$CONFIG_KEY_REPO_DIR] = $normalized
	}
	return $ConfigVars
}

# --- Repo-Einstellungen: SFTP ---
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

# --- Passwortdatei ---
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
			& (Join-Path $SCRIPTS_DIR "generate-password.ps1") -Filename $validated -ByteSize 1024
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

# --- Menüs ---
$configVars = Get-RepoConfig -ConfigFile $ConfigFile

function Show-EditMenu {
	Write-Host ""
	Write-Host "=== Edit repository settings ==="
	Write-Host "1) Change repository settings"
	Write-Host "2) Change password file"
	Write-Host "3) Save and exit"
	Write-Host "4) Cancel"
}

function Show-RepoTypeMenu {
	Write-Host ""
	Write-Host "=== Select repository type ==="
	Write-Host "1) Local repository"
	Write-Host "2) SFTP repository"
}

do {
	Show-EditMenu
	$choice = Read-Host "Enter number"

	switch ($choice) {
		"1" {
			Show-RepoTypeMenu
			$typeChoice = Read-Host "Enter number"
			switch ($typeChoice) {
				"1" { $configVars = Set-RepoConfigLocal -ConfigVars $configVars }
				"2" { $configVars = Set-RepoConfigSftp  -ConfigVars $configVars }
				default { Write-Host "Invalid choice." }
			}
		}
		"2" { $configVars = Set-PasswordFile -ConfigVars $configVars }
		"3" {
			if (Test-RepoConfigValidity -ConfigVars $configVars) {
				New-RepoConfigFromTemplate -TemplateFile $TemplateFile -OutputFile $ConfigFile -ConfigVars $configVars
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
		default { Write-Host "Invalid choice." }
	}
} until ($choice -eq "3" -or $choice -eq "4")
