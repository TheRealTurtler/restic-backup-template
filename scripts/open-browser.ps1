. "$PSScriptRoot\constants.ps1"
Import-Module (Join-Path $SCRIPTS_MODULES_DIR "Logging.psm1")

param(
    [string]$ResticExe   = (Join-Path $BIN_DIR "restic.exe"),
    [string]$BrowserExe  = (Join-Path $BIN_DIR "restic-browser.exe"),
    [string]$ProfilePath = (Join-Path $CONF_PROFILES_DIR "01_default_repo.yaml")
)

# Profil einlesen (z. B. YAML parsen oder Regex)
$config = Get-Content $ProfilePath -Raw

# Einfacher Ansatz: Pfade aus der YAML extrahieren
$repoLine    = ($config -split "`n" | Where-Object { $_ -match 'repository:' }) -replace 'repository:\s*', ''
$passwordLine= ($config -split "`n" | Where-Object { $_ -match 'password-file:' }) -replace 'password-file:\s*', ''

Start-Process -FilePath $BrowserExe -ArgumentList @(
    "--restic", $ResticExe,
    "--repo",   $repoLine.Trim(),
    "--password-file", $passwordLine.Trim()
)
