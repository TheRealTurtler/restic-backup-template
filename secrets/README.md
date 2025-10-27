# 🔐 secrets/

This folder contains password files used by `resticprofile` for repository access.

✅ Each file stores the encryption password for a specific profile.

📌 File naming is configured via `00_default.yaml`:
`<user>_<profile>.txt`

- Used by `resticprofile` when `password-file` is set in the profile configuration.
- Do **not** include this folder in backups or version control.
- These files contain **real repository passwords** and must be stored securely.

---

### ⚠️ Critical: Backup Your `.secret` File

This file contains the encryption password for your restic repository.

If it is lost, **you will permanently lose access to your backups.**
restic cannot decrypt the repository without the exact password.

✅ Always store this file in a **secure, separate location** — outside your backup targets and version control.

📁 *Example:*
Store it on a USB stick, password manager, or encrypted vault that is not part of the backup set.
