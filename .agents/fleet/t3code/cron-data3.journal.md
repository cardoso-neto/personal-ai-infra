# Cron Data 3 installation journal

## Earlier host provisioning

Root Bash history records compiler/database/geospatial dependencies and document-processing tools, including OCR, PDF utilities, LibreOffice, and FFmpeg.
Representative packages remain installed as of 2026-09-11.
These are host-level dependencies; the host also runs services outside the T3 account, including a separate system Docker daemon.

## By 2026-09-04: T3 provisioning

- Created the dedicated `t3-cardoso-neto` account with a separate home and workspace, a `nologin` shell, and systemd linger.
  Installed T3 as a user service with an explicit `~/t3` base directory and linked T3 Connect.
- Provisioned rootless Docker instead of granting access to host Docker.
  Assigned subordinate UID/GID ranges in `/etc/subuid` and `/etc/subgid` and added `/etc/apparmor.d/var.lib.t3code.cardoso-neto..local.bin.rootlesskit` for unprivileged user namespaces.
  The T3 service's `tools.conf` supplies the user-tool PATH and Docker socket.
- Installed user tools under `~/.local`, authenticated GitHub and Codex for the service account, and configured GitHub SSH URL rewrites to HTTPS for the repository picker.

## 2026-09-11: Personal configuration and audit

- Cloned personal AI infrastructure into the standard repository tree and linked shared configuration into the agent home directories.
  Preserved VM guidance in Codex's `developer_instructions`; installed the markdown hook's linter.
  Backups are located through `~/.local/state/personal-ai-infra/latest-backup`.
- Checked root and T3-user Bash histories against current configuration.
  The T3 user's Bash history is sparse; noninteractive provisioning is represented by the earlier setup notes and live configuration.
- Confirmed existing cron jobs for CLI, T3, Node/npm, and uv upgrades.
  Node is managed with `n` under `~/.local`.
  Repository maintenance runs `git fetch -p` every four hours, so changed instructions still require checkout updates.
