# 🗂️ cache/

This folder stores the local restic repository cache.

✅ restic uses this to speed up operations like `check`, `diff`, and `mount`.

- Contents are automatically managed by restic.
- Safe to delete — restic will recreate it as needed.
- Do **not** include this folder in backups or version control.
