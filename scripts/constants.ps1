# === Global constants for project paths ===

# Root directory (relative to this script location)
$ROOT_DIR = Split-Path -Parent $PSScriptRoot

# Top-level directories
$BIN_DIR = Join-Path $ROOT_DIR "bin"
$CACHE_DIR = Join-Path $ROOT_DIR "cache"
$CONF_DIR = Join-Path $ROOT_DIR "conf"
$LOCK_DIR = Join-Path $ROOT_DIR "lock"
$LOG_DIR = Join-Path $ROOT_DIR "log"
$SCRIPTS_DIR = Join-Path $ROOT_DIR "scripts"
$SECRETS_DIR = Join-Path $ROOT_DIR "secrets"

# Subdirectories under conf
$CONF_RESTICPROFILE_DIR = Join-Path $CONF_DIR "resticprofile"
$CONF_PROFILES_DIR = Join-Path $CONF_RESTICPROFILE_DIR "profiles.d"
$CONF_TEMPLATES_DIR = Join-Path $CONF_RESTICPROFILE_DIR "templates.d"

# Subdirectories under scripts
$SCRIPTS_MODULES_DIR = Join-Path $SCRIPTS_DIR "modules"
