#requires -version 5.1
$ErrorActionPreference = 'Stop'

# === CONFIGURATION ===
$OutputDir       = "secrets"                      # Directory to store generated password files
$SecretExtension = ".secret"                      # File extension for password output
$TempDir         = $env:TEMP                      # Reserved for future use
$DefaultByteSize = 1024                           # Default password size in bytes

# === INPUT HANDLING ===
[string]$Filename = $null
[int]$ByteSize    = $null

if ($args.Count -ge 1) {
    $Filename = $args[0]
}
if ($args.Count -ge 2) {
    $ByteSize = [int]$args[1]
}

if (-not $Filename) {
    Write-Host ""
    $Filename = Read-Host "Enter filename for password (without extension)"
}

if (-not $ByteSize) {
    $ByteSize = Read-Host "Enter password size in bytes (default: $DefaultByteSize)"
    if (-not $ByteSize) {
        $ByteSize = $DefaultByteSize
    } else {
        $ByteSize = [int]$ByteSize
    }
}

# === VALIDATION ===
if (-not $Filename) {
    Write-Host "ERROR: No filename provided."
    Pause
    exit 1
}
if ($ByteSize -lt 1) {
    Write-Host "ERROR: Byte size must be at least 1."
    Pause
    exit 5
}

# === PATH SETUP ===
$OutFile = Join-Path $OutputDir ($Filename + $SecretExtension)

if (Test-Path $OutFile) {
    Write-Host "ERROR: Password file already exists: $OutFile"
    Write-Host "Aborting to prevent overwrite."
    Pause
    exit 2
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

# === PASSWORD GENERATION ===
Add-Type -AssemblyName System.Security
$bytes = New-Object byte[] $ByteSize
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$securePassword = [Convert]::ToBase64String($bytes)

# === WRITE TO FILE ===
Set-Content -Path $OutFile -Value $securePassword -Encoding utf8

# === DONE ===
Write-Host "Password saved to: $OutFile"
Pause
