Write-Host ("Executing {0}..." -f $MyInvocation.MyCommand.Path)

# === Load constants and ResticProfileHooks module ===
. "$PSScriptRoot\..\..\constants.ps1"
Import-Module (Join-Path $SCRIPTS_MODULES_DIR "ResticProfileHooks.psm1")

# === Collect ResticProfile context ===
$Context = Get-ResticProfileContext

exit 0
