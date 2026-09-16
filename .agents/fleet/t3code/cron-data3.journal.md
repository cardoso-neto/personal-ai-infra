# Cron Data 3 installation journal

## 2026-09-16: Storage and minion access

- Expanded root EBS from 200 to 512 GiB and grew partition 1 and ext4 online.
- Rechecked the secondary volume was empty and unused, unmounted it normally, removed its exact fstab entry, then detached and deleted `vol-051599b22f8257791`.
- Preserved the videos directory on the root filesystem with its original ownership and permissions.
- Configured `ssh ansible-tower-prod` on the MacBook and desktop through `ProxyJump cron-data3`; verified both connections and the minion's AWS role with the corporate VPN off.
- Access details live in [the host notes](cron-data3.md#production-aws-access-through-the-minion); personal Tailnet setup stays out of the shared work repository.

## 2026-09-16: Block reverse SSH to personal machines

- Replaced the default unrestricted network grant through the Tailscale API with grants excluding Cron Data 3 → desktop/MacBook TCP port 22. Covered IPv4 and IPv6; kept other TCP ports, UDP, and ICMP available between these machines.
- Validated the candidate and its embedded allow/deny tests before applying it with an ETag condition.
- Live probes from Cron Data 3 to both personal machines' IPv4 and IPv6 SSH endpoints timed out after application.
- Verified desktop and MacBook SSH to Cron Data 3 with `sudo -n id` returning root. Desktop → MacBook SSH and MacBook → desktop TCP port 22 remained reachable.
- Original policy, applied policy response, and management script are on the desktop under `~/.local/state/tailscale-policy/`. API credentials remain outside the repository.

## 2026-09-13: Tailscale host provisioning

- Installed Tailscale 1.102.4 from the official signed Ubuntu 24.04 package repository.
- Enabled and started the system `tailscaled` service.
- Created the unprivileged `quorum-agent` account with home `/var/lib/quorum-agent` and shell `/bin/bash`.
- Enrollment requires a Quorum work identity; the current backend state is `NeedsLogin`.
- Tailscale SSH, subnet advertisements, and the test from the MacBook remain pending.
- The Mac's baseline route to the VM's private address used its LAN interface, and a direct TCP connection to the VM's private SSH port failed.

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
