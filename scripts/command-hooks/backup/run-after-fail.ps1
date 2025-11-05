Write-Host ("Executing {0}..." -f $MyInvocation.MyCommand.Path)

# === Load constants and ResticProfileHooks module ===
. "$PSScriptRoot\..\..\constants.ps1"
Import-Module (Join-Path $SCRIPTS_MODULES_DIR "ResticProfileHooks.psm1")
Import-Module (Join-Path $SCRIPTS_MODULES_DIR "EmailSettings.psm1")

# === Collect system and ResticProfile context ===
$SystemInfo = Get-SystemInfo
$Context = Get-ResticProfileContext

# === Format failure report ===
$Report = Format-ResticFailureReportHtml -SystemInfo $SystemInfo -Context $Context

# === Load email settings and send mail ===
$SettingsPath = Join-Path $SECRETS_DIR "email.secret"

if (Test-Path $SettingsPath) {
	try {
		$Email = Get-EmailSettings -Path $SettingsPath

		Send-MailMessage -From $Email.From -To $Email.To `
			-Subject "[$($SystemInfo.Hostname)] ResticProfile Failure Report" `
			-Body $Report -BodyAsHtml -SmtpServer $Email.SmtpServer -Port $Email.Port `
			-UseSsl -Credential $Email.Credential

		Write-Host "Mail successfully sent to $($Email.To)"
	}
	catch {
		Write-Host "Email dispatch failed: $($_.Exception.Message)"
	}
}
else {
	Write-Host "No email settings found. Skipping email dispatch."
}

exit 0
