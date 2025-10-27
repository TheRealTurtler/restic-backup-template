param (
    [string]$Hostname,
    [string]$OS,
    [string]$Arch,
    [string]$CurrentDir,
	[string]$BinaryDir,
    [string]$ConfigDir
)

# Constant debug flag – set to $true to enable console output
$Debug = $true

# Retrieve additional information from environment variables
$ProfileName   = $env:PROFILE_NAME
$Command       = $env:PROFILE_COMMAND
$ExitCode      = $env:ERROR_EXIT_CODE
$ErrorMessage  = $env:ERROR
$CommandLine   = $env:ERROR_COMMANDLINE
$StderrOutput  = $env:ERROR_STDERR

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Build formatted error Message
$message = @()
$message += "============================================================"
$message += " Resticprofile FAILURE [$timestamp]"
$message += "============================================================"
$message += ("  Hostname      : {0}" -f $Hostname)
$message += ("  OS            : {0}" -f $OS)
$message += ("  Arch          : {0}" -f $Arch)
$message += ("  Current Dir   : {0}" -f $CurrentDir)
$message += ("  Binary Dir    : {0}" -f $BinaryDir)
$message += ("  Config Dir    : {0}" -f $ConfigDir)
$message += ("  Profile       : {0}" -f $ProfileName)
$message += ("  Command       : {0}" -f $Command)
$message += ("  Exit Code     : {0}" -f $ExitCode)
$message += "------------------------------------------------------------"
$message += "  Error Message :"
$ErrorMessage.Trim().Split("`n") | ForEach-Object { $message += "    $_" }
$message += "------------------------------------------------------------"
$message += "  Command Line  :"
$CommandLine.Trim().Split("`n") | ForEach-Object { $message += "    $_" }
$message += "------------------------------------------------------------"
$message += "  STDERR Output :"
$StderrOutput.Trim().Split("`n") | ForEach-Object { $message += "    $_" }
$message += "============================================================"

# Join everything into one string
$report = $message -join "`n"

if ($Debug) {
    Write-Host $report
}

# TODO
# Example: send via email
# Send-MailMessage -SmtpServer "mail.example.com" -From "resticprofile@example.com" -To "admin@example.com" -Subject "Resticprofile FAILURE on $Hostname" -Body $report

exit 0
