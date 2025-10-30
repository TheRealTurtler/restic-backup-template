# Global indentation level
$script:LogIndent = 0

# Define Unicode box characters
$script:LogCornerTopLeft = [char]0x250C       # ┌
$script:LogLineVertical = [char]0x2502        # │
$script:LogCornerBottomLeft = [char]0x2514    # └
$script:LogLineHorizontal = [char]0x2500      # ─

$script:LogStart = "$script:LogCornerTopLeft$([string]::new($script:LogLineHorizontal, 3))"
$script:LogEnd = "$script:LogCornerBottomLeft$([string]::new($script:LogLineHorizontal, 3))"

function Start-LogBlock {
	param([string]$Message)

	$prefix = ("$script:LogLineVertical " * $script:LogIndent)
	Write-Host "$prefix$script:LogStart $Message"
	$script:LogIndent++
}

function Stop-LogBlock {
	param([string]$Message)

	$script:LogIndent--
	$prefix = ("$script:LogLineVertical " * $script:LogIndent)
	Write-Host "$prefix$script:LogEnd"
}

function Write-LogLine {
	param([string]$Message)

	$prefix = ("$script:LogLineVertical " * $script:LogIndent)
	Write-Host "$prefix$Message"
}
