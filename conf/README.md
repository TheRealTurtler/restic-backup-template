# ⚙️ conf/

This folder contains the main configuration for `resticprofile`.

It includes two subfolders:

- `conf.d/` – optional fragments or overrides (not used by default)
- `profiles.d/` – actual backup profiles

## 📁 profiles.d/

This is where all backup profiles are defined. Each file describes a specific backup target or behavior.

- Supported formats: `.yaml`, `.toml`, `.hcl`, or `.json`
- `00_default.yaml` – base configuration inherited by all other profiles
- `global.yaml` – global configuration not tied to any specific profile
- `userdata.yaml` – predefined profile for backing up the user directory
- `zz_groups.yaml` – defines profile groups (e.g. for `full-backup` to run multiple profiles at once)

✅ Group definitions allow batch execution of related profiles.
✅ Global settings in `global.yaml` apply across all profiles.

☑️ This folder **may be included in version control**, **as long as no sensitive data** (e.g. passwords, access tokens, repository URLs with embedded credentials) is stored in the profiles.

📚 See: [resticprofile configuration documentation](https://creativeprojects.github.io/resticprofile/configuration/index.html)
