# Cron Data 3 installation journal

## 2026-10-31: Rootless Docker for all agent accounts

- Added separate rootless Docker daemons for `t3-quentin`, `t3-quasar`, and `nei`, with enabled user services and systemd linger.
  Kept `t3-cardoso-neto`'s working rootless installation and selected its rootless CLI context.
- Assigned non-overlapping subordinate UID/GID ranges to Quentin and Quasar.
  Used existing Ubuntu Docker, RootlessKit, slirp4netns, UID mapping tools, and AppArmor support, with matching upstream rootless scripts.
- Added `DOCKER_HOST` overrides for Quentin and Quasar's next T3 restart.
  CLI contexts make Docker available immediately without granting access to the host daemon.
  Provisioning did not request T3 restarts, and Quentin's service stayed running.
  Cardoso and Quasar's T3 services restarted during the provisioning window; the initiator was not established, and both were active afterward.
- Updated the maintenance checkout's `agent-personas/INFRA.md` and deployed runtime copies for Quentin and Quasar.
  Their instruction links use these copies, preserving the clean shared reference and its hourly updates.
- Verified all four accounts started PostgreSQL 16 containers, wrote rows, and queried them through localhost-published ports.
  Removed the disposable containers after the checks; Docker Compose and rootless security checks also passed.
- Logs and rollback evidence: `/var/tmp/cron3-rootless-docker-RkZqSnS0/`.

## 2026-10-21: Quorum subnet routing

- Advertised and approved the five internal subnet routes listed in [Quorum internal access](cron-data3.md#quorum-internal-access-through-the-tailnet).
- Added a grant for Nei's identity with `via: ["tag:cron-data3"]`.
  Preserved existing policy and tests, and added tests allowing Nei and denying Martin and Genesis access to representative internal endpoints.
  Tailscale validated the candidate before an ETag-guarded policy update.
- Kept default SNAT and the existing persistent IPv4 forwarding setting.
  Enabled route acceptance on the MacBook and desktop.
  Made no DNS, AWS routing, or EC2 source/destination-check changes.
- With OpenVPN off on the desktop, verified Teleport's ping endpoint returned 200, the database web UI returned its expected 401, and a legacy RDS PostgreSQL port accepted a TCP connection.
  The same checks passed on the MacBook, where the route table selected Tailscale's `utun0` rather than OpenVPN's `utun5`.
- Both configured Kubernetes API endpoints returned their expected unauthenticated 401 responses from the MacBook and desktop, with TLS certificates verified against the kubeconfig CAs.
- After Nei disconnected OpenVPN on the MacBook, repeated the service checks successfully on both machines.
  The MacBook used home DNS and had no OpenVPN routes; internal subnet routes remained on Tailscale's `utun0`.
- Policy and route snapshots: desktop `~/.local/state/quorum-subnet-router/20261021/`.

## 2026-10-16: Grok npm postinstall repair

- Reinstalled Grok with `npm install --global --prefix "$HOME/.local" --allow-scripts=@xai-official/grok @xai-official/grok@latest`.
  The package and executable now agree on 1.0.62; blocked postinstall had left the executable at 1.0.25.
- Added `npm_config_allow_scripts=@xai-official/grok` to the hourly Grok cron command, preserving its prefix, PATH, lock, and timeout.
  Left `.npmrc` and its Claude script permission unchanged.
- Ran the installed updater command with a minimal cron environment: exit 0, `Already up to date (1.0.62).`
  Backups and verification logs: `~/.local/state/grok-update/repair-20261016T220607Z/`.

## 2026-10-07: Capacity resize

Resized on 2026-10-07 to `m8a.12xlarge`: AMD EPYC 9R45, 48 physical cores/vCPUs, one thread per core, and 192 GiB nominal RAM.
Linux reports approximately 185 GiB usable RAM.
The root disk, private IP, and existing `6.17.0-1012-aws` kernel were preserved for the resize.
Existing backfill concurrency and CPU affinity `0-27` remain unchanged.
The ENI's established TCP idle timeout is explicitly 432000 seconds, preserving the previous instance's behavior.

## 2026-10-04: T3 base directory moved to `~/.t3`

- Renamed `~/t3` to `~/.t3` and left `~/t3 -> .t3`, so the running server, agents, and stored absolute paths kept working.
  - The desktop app's SSH launcher only detects a running server through `~/.t3/userdata/server-runtime.json`; with the old path it would start a second server.
- Updated `t3code.service` (`T3CODE_HOME`, `ExecStart`, log paths) and the nightly `t3 update --base-dir`; ran `daemon-reload` without restarting.
  - Backups: `t3code.service.before-dot-t3-20261004` and `~/.local/state/t3code-update/crontab.before-dot-t3-20261004`.
- Verified: same server PID, environment endpoint 200, T3 Connect tunnel and running agents unaffected, and the CLI resolves this install without `--base-dir`.

## 2026-09-27: CLIProxyAPI usage keeper

- Installed CPA Usage Keeper v1.15.8 as the `cpa-usage-keeper.service` user unit on `127.0.0.1:8318`; details in [the CLIProxyAPI notes](cliproxyapi.md#usage-keeper).
- Chose the checksum-verified release binary over rootless Docker, matching the proxy's install; it ingests in `subscribe` mode as the proxy's only usage collector.
- A `sed -i` edit of the proxy's `config.yaml` dropped the proxy's config-file watch; the file was restored in place and the restart deferred to Nei.
  - See [Config file watch](cliproxyapi.md#config-file-watch).
- Adding 8318 to the Mac tunnel briefly broke it (bad plist argument order), cutting the Mac's proxy-routed Claude traffic until it was fixed.

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
