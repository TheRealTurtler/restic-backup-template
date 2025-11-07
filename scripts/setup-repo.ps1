#requires -version 5.1
$ErrorActionPreference = 'Stop'

# === Load constants and modules ===
. "$PSScriptRoot\constants.ps1"
Import-Module (Join-Path $SCRIPTS_MODULES_DIR "PathValidation.psm1")
Import-Module (Join-Path $SCRIPTS_MODULES_DIR "EmailSettings.psm1")

# === Script paths ===
$SCRIPT_REPO_CONFIG = Join-Path $SCRIPTS_DIR "repo-config.ps1"
$SCRIPT_GENERATE_PASSWORD = Join-Path $SCRIPTS_DIR "generate-password.ps1"

# === Load repo config functions ===
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

# === Email settings file path ===
$EMAIL_SETTINGS_PATH = Join-Path $SECRETS_DIR "email.secret"

# === Profile template files to copy ===
$PROFILE_TEMPLATE_FILES = @(
	"userdata.yaml",
	"test.yaml",
	"zz_groups.yaml"
)

# === Copy profile templates with optional overwrite ===
function Copy-ProfileTemplates {
	param([bool]$Force = $false)

	foreach ($file in $PROFILE_TEMPLATE_FILES) {
		$source = Join-Path $CONF_TEMPLATES_DIR $file
		$target = Join-Path $CONF_PROFILES_USER_DIR $file

		if ($Force -or -not (Test-Path $target)) {
			Copy-Item -Path $source -Destination $target -Force
			$action = if ($Force) { "Overwritten" } else { "Copied" }
			Write-Host ("{0}: {1}" -f $action, $file)
		}
	}
}

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

# === Configure local repository ===
function Set-RepoConfigLocal {
	param([hashtable]$ConfigVars)
	$normalized = Read-ValidatedPath -PromptText "Enter local repository path"
	if ($normalized) {
		$ConfigVars[$CONFIG_KEY_REPO_TYPE] = "local"
		$ConfigVars[$CONFIG_KEY_REPO_DIR] = $normalized
	}
	return $ConfigVars
}

# === Configure SFTP repository ===
function Set-RepoConfigSftp {
	param([hashtable]$ConfigVars)

	Write-Host ""
	Write-Host "NOTE: SFTP login requires SSH key authentication."
	Write-Host "      Ensure your public key is installed on the remote host"
	Write-Host "      and your private key is available to the backup tool."

	$user = Read-Host "Enter SFTP username"
	$sftpHost = Read-Host "Enter SFTP host (e.g. example.com)"
	$normalized = Read-ValidatedPath -PromptText "Enter SFTP repository path (e.g. /backups/projectA)"

	if ($normalized) {
		$ConfigVars[$CONFIG_KEY_REPO_TYPE] = "sftp"
		$ConfigVars[$CONFIG_KEY_REPO_DIR] = "${user}@${sftpHost}:${normalized}"
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

# === Configure email settings ===
function Set-EmailSettings {
	param (
		[string]$SettingsPath
	)

	Write-Host ""
	Write-Host "=== Configure email settings ==="

	$from = Read-Host "Enter sender address (From)"
	$to = Read-Host "Enter recipient address (To)"
	$smtpServer = Read-Host "Enter SMTP server (e.g. smtp.gmail.com)"
	$portRaw = Read-Host "Enter SMTP port (e.g. 587)"
	$securePwd = Read-Host "Enter app password" -AsSecureString

	if (-not ($portRaw -as [int])) {
		Write-Host "Invalid port number."
		return
	}

	Export-EmailSettings -Path $SettingsPath `
		-From $from -To $to -SmtpServer $smtpServer -Port ([int]$portRaw) -SecurePassword $securePwd

	Write-Host "Email settings saved to $SettingsPath"
}

# === Send test email ===
function Send-TestEmail {
	param (
		[string]$SettingsPath
	)

	if (-not (Test-Path $SettingsPath)) {
		Write-Host "No email.secret file found. Cannot send test email."
		return
	}

	try {
		$email = Get-EmailSettings -Path $SettingsPath

		Send-MailMessage -From $email.From -To $email.To `
			-Subject "ResticProfile Test" `
			-Body "Congratulations, your email configuration is working." `
			-SmtpServer $email.SmtpServer -Port $email.Port `
			-UseSsl -Credential $email.Credential

		Write-Host "Test email sent to $($email.To)"
	}
	catch {
		Write-Host "Test email failed: $($_.Exception.Message)"
	}
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

	$emailChoice = Read-Host "Do you want to configure email settings now? (yes/no)"
	if ($emailChoice -eq "yes") {
		Set-EmailSettings -SettingsPath $EMAIL_SETTINGS_PATH
	}

	Copy-ProfileTemplates -Force $false

	return $ConfigVars
}

# === Menu for editing existing repository configuration ===
# === Menu for editing existing repository configuration ===
function Show-EditMenu {
	Write-Host ""
	Write-Host "=== Edit repository settings ==="
	Write-Host "1) Change repository settings"
	Write-Host "2) Change password file"
	Write-Host "3) Update profile files"
	Write-Host "4) Change email settings"
	Write-Host "5) Send test email"
	Write-Host "6) Save and back to main menu"
	Write-Host "7) Cancel"
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
				Write-Host ""
				Write-Host "WARNING: This will overwrite the following profile files in profiles_user.d:"
				foreach ($file in $PROFILE_TEMPLATE_FILES) {
					Write-Host ("  - {0}" -f $file)
				}

				$confirm = Read-Host "Do you want to overwrite these files? (yes/no)"
				if ($confirm -eq "yes") {
					Copy-ProfileTemplates -Force $true
				}
				else {
					Write-Host "Update cancelled."
				}
			}
			"4" {
				Set-EmailSettings -SettingsPath $EMAIL_SETTINGS_PATH
			}
			"5" {
				Send-TestEmail -SettingsPath $EMAIL_SETTINGS_PATH
			}
			"6" {
				if (Test-RepoConfigValidity -ConfigVars $ConfigVars -RequiredKeys $REQUIRED_KEYS) {
					New-RepoConfigFromTemplate -TemplateFile $TemplateFile -OutputFile $ConfigFile -ConfigVars $ConfigVars
					Write-Host "Configuration saved to $ConfigFile"
				}
				else {
					Write-Host "Configuration invalid. Please fix missing or empty values."
				}
				break
			}
			"7" {
				Write-Host "Cancelled. No changes saved."
				break
			}
			default {
				Write-Host "Invalid choice."
			}
		}
	} until ($choice -eq "6" -or $choice -eq "7")
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
