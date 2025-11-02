#requires -version 5.1
param(
	[Parameter(Mandatory = $true)]
	[string]$Filename,   # Full filename including extension

	[int]$ByteSize = 1024
)

$ErrorActionPreference = 'Stop'

# === Load constants and logging module ===
. "$PSScriptRoot\constants.ps1"
Import-Module (Join-Path $SCRIPTS_MODULES_DIR "Logging.psm1")

# === Check if password file already exists ===
function Test-PasswordFileExists {
	param([string]$OutFile)

	if (Test-Path $OutFile) { return $true }
	return $false
}

# === Generate and save a secure password file ===
function New-PasswordFile {
	param(
		[string]$OutFile,
		[int]$ByteSize
	)

	# Ensure secrets directory exists
	if (-not (Test-Path $SECRETS_DIR)) {
		New-Item -ItemType Directory -Path $SECRETS_DIR | Out-Null
	}

	Start-LogBlock "Password Generation"
	Write-LogLine "Generating password..."

	# Create cryptographically secure random byte array
	Add-Type -AssemblyName System.Security
	$bytes = New-Object byte[] $ByteSize
	[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)

	# Convert to base64 string and save to file
	$securePassword = [Convert]::ToBase64String($bytes)
	Set-Content -Path $OutFile -Value $securePassword -Encoding utf8

	Write-LogLine "Password saved to: $OutFile."
	Write-LogLine ""
	Write-LogLine "WARNING: This password file is CRITICAL for repository access!"
	Write-LogLine "         Store it in a safe location outside the backup."
	Write-LogLine "         Without this password, the repository CANNOT be accessed."
}

# === Main execution block ===
if ($ByteSize -lt 1) {
	Write-LogLine "Error: Byte size must be at least 1."
	exit 1
}

$OutFile = Join-Path $SECRETS_DIR $Filename

if (Test-PasswordFileExists -OutFile $OutFile) {
	Write-Host ""
	Write-Host "WARNING: A password file with this name already exists:"
	Write-Host "         $OutFile"
	Write-Host ""
	Write-Host "Overwriting this file will make any existing repository permanently inaccessible."
	Write-Host ""
	$confirm = Read-Host "Do you want to overwrite the existing file? (yes/no)"
	if ($confirm -ne "yes") {
		Write-LogLine "Aborted: Existing password file was not overwritten."
		exit 1
	}
}

New-PasswordFile -OutFile $OutFile -ByteSize $ByteSize
exit 0
