Write-Host ("Executing {0}..." -f $MyInvocation.MyCommand.Path)

# === Load constants and ResticProfileHooks module ===
. "$PSScriptRoot\..\constants.ps1"
Import-Module (Join-Path $SCRIPTS_MODULES_DIR "ResticProfileHooks.psm1")

# === Collect system and ResticProfile context ===
$SystemInfo = Get-SystemInfo
$Context = Get-ResticProfileContext

# === Format failure report ===
$Report = Format-ResticFailureReport -SystemInfo $SystemInfo -Context $Context
Write-Host $Report

# === Append to log file ===
$LogFileName = Get-ResticLogFile -Context $Context
$LogFilePath = (Join-Path $LOG_DIR $LogFileName)
Write-ResticLog -Report $Report -LogFilePath $LogFilePath

exit 0
