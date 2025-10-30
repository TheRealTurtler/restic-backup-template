#requires -version 5.1
$ErrorActionPreference = 'Stop'

# === Load constants and modules ===
. "$PSScriptRoot\scripts\constants.ps1"
Import-Module (Join-Path $SCRIPTS_MODULES_DIR "Logging.psm1") -Force

# === Constants ===
# Script paths
$SCRIPT_UPDATE_BINARIES = "$PSScriptRoot\update-binaries.ps1"
$SCRIPT_GENERATE_PASS = "$PSScriptRoot\generate-password.ps1"
$SCRIPT_RUN_BACKUP = "$PSScriptRoot\run-backup.ps1"

# Template configuration
$PROFILE_TEMPLATE = "01_default_repo.yaml"
$PLACEHOLDER_USER = "<<USER_NAME>>"
$PLACEHOLDER_TYPE = "<<REPO_TYPE>>"
$PLACEHOLDER_DIR = "<<REPO_BASE_DIR>>"

# Validation regex
$USERNAME_REGEX = '^[a-zA-Z0-9_-]+$'
$PATH_REGEX = '^[a-zA-Z]:\\[a-zA-Z0-9_\-\\/ ]+$|^[a-zA-Z0-9_\-\\/ ]+$'

# --- Helper functions ---
function Read-ValidatedInput {
	param(
		[string]$Prompt,
		[string]$Regex
	)
	do {
		$input = Read-Host $Prompt
		$isValid = $input -match $Regex
		if (-not $isValid) {
			Write-Host "Invalid input. Please try again."
		}
	} until ($isValid)
	return $input
}

function Ask-YesNo {
	param([string]$Prompt)
	do {
		$answer = Read-Host "$Prompt (yes/no)"
	} until ($answer -in @("yes", "no"))
	return $answer -eq "yes"
}

# === Initialize repository ===
Start-LogBlock "Repository Setup"

# --- Update binaries first ---
Write-LogLine "Updating binaries..."
& $SCRIPT_UPDATE_BINARIES
if ($LASTEXITCODE -ne 0) {
	Stop-LogBlock "Repository Setup"
	exit $LASTEXITCODE
}

# --- Check if profile already exists ---
$profilePath = Join-Path $CONF_PROFILES_DIR $PROFILE_TEMPLATE
$templatePath = Join-Path $CONF_TEMPLATES_DIR $PROFILE_TEMPLATE
if (Test-Path $profilePath) {
	Write-LogLine "Warning: A backup profile already exists at '$profilePath'."
	if (-not (Ask-YesNo "Overwrite")) {
		Stop-LogBlock "Repository Setup"
		exit 0
	}
}

# --- Username ---
$username = Read-ValidatedInput "Please enter backup username" $USERNAME_REGEX

# --- Repo type ---
Write-Host "`nSelect restic repository type:"
Write-Host "1) local"
Write-Host "2) sftp"
do {
	$repoChoice = Read-Host "Enter number"
} until ($repoChoice -in @("1", "2"))

Write-Host "`nNote: The structure 'username/backup/...' will be appended automatically."

if ($repoChoice -eq "1") {
	$repoType = "local"
	$baseDir = Read-ValidatedInput "Enter base directory" $PATH_REGEX
}
elseif ($repoChoice -eq "2") {
	$repoType = "sftp"
	$sftpUser = Read-Host "Enter SFTP username"
	$sftpHost = Read-Host "Enter SFTP host"
	$remoteBase = Read-ValidatedInput "Enter remote base directory" $PATH_REGEX
	$baseDir = "${sftpUser}@${sftpHost}:${remoteBase}"
}

# --- Normalize repo path ---
if ([string]::IsNullOrWhiteSpace($baseDir)) {
	$repoPath = ""
}
else {
	$repoPath = ($baseDir -replace '\\', '/') -replace '/+$', ''
	$repoPath = "$repoPath/"
}

# --- Password handling ---
Write-LogLine "Setting up repository password..."
$secretFile = "restic_$username"

if (Test-Path (Join-Path $SECRETS_DIR "$secretFile.secret")) {
	Write-LogLine "Warning: Password file already exists."
	Write-LogLine "Warning: If you overwrite it, repos encrypted with the old password will be UNREADABLE."
	if (Ask-YesNo "Overwrite password file") {
		Remove-Item (Join-Path $SECRETS_DIR "$secretFile.secret") -Force
		& $SCRIPT_GENERATE_PASS $secretFile
		if ($LASTEXITCODE -ne 0) {
			Stop-LogBlock "Repository Setup"
			exit $LASTEXITCODE
		}
	}
	else {
		Write-LogLine "Keeping existing password file."
	}
}
else {
	& $SCRIPT_GENERATE_PASS $secretFile
	if ($LASTEXITCODE -ne 0) {
		Stop-LogBlock "Repository Setup"
		exit $LASTEXITCODE
	}
}

# --- Create configuration ---
Write-LogLine "Creating repository configuration..."
$configContent = Get-Content $templatePath -Raw
$configContent = $configContent -replace [regex]::Escape($PLACEHOLDER_USER), $username
$configContent = $configContent -replace [regex]::Escape($PLACEHOLDER_TYPE), $repoType
$configContent = $configContent -replace [regex]::Escape($PLACEHOLDER_DIR), $repoPath

$destDir = Split-Path $profilePath
if (-not (Test-Path $destDir)) {
	New-Item -ItemType Directory -Path $destDir | Out-Null
}
$configContent | Set-Content $profilePath
Write-LogLine "Configuration saved to: $profilePath."

Write-LogLine "Setup completed successfully."

# --- Run full backup? ---
if (Ask-YesNo "Do you want to run a full backup now") {
	& $SCRIPT_RUN_BACKUP
	if ($LASTEXITCODE -ne 0) {
		Stop-LogBlock "Repository Setup"
		exit $LASTEXITCODE
	}
}

Stop-LogBlock "Repository Setup"
exit 0
