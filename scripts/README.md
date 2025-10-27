# 🛠️ scripts/

This folder contains custom hook scripts used by `resticprofile`.

These scripts are executed in response to specific lifecycle events, such as:

- `run-after-fail` – triggered when a configured operation (e.g. backup, prune) fails
- `run-after-success` – triggered after successful completion
- `run-before` – executed before a profile starts

⚠️ Scripts must be explicitly referenced in your `resticprofile.yaml` configuration.
They are **not** automatically discovered or executed.

📌 The default hook scripts in this folder are referenced by `00_default.yaml`.

📚 See: [resticprofile hook documentation](https://creativeprojects.github.io/resticprofile/configuration/run_hooks/index.html)
