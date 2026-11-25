# Cron Data 3 installation journal

## 2026-11-24: Pensaplexa bridge moved to Kubernetes

- The bridge is now the `actacollecta-agent-pensaplexa-bridge` Deployment (PRs #19922, #19923, #19953; Jenkins `agent` builds #1749 and #1750). It runs on the worker's image, so one deploy moves both.
- Its entrypoint issues T3 tokens over SSH with a new `pensaplexa-bridge` key (`PENSAPLEXA_T3_AUTH_KEY` in `data-scraping-secret`). The key is authorized for `t3-quasar`, `t3-quentin` (here) and `t3-questor` (cron-data2), forced to `/usr/local/sbin/pensaplexa-t3-auth`, now installed here too. Questor's old renewal key was removed (`authorized_keys.bak-20261124-bridge-k8s`).
- Stopped and disabled `pensaplexa.service` and `pensaplexa-t3-tokens.timer` at 21:05:30 UTC. A Quentin session (worktree `t3-73cf6289`) restarted the unit at 21:15:36 and 21:16:38 UTC; its token renewal revoked the Kubernetes bridge's sessions, and two bridges briefly shared Slack's Socket Mode. Stopped at 21:18 UTC; build #1750 restarted the pod with new sessions.
- Removed the units, the `pensaplexa.service.d` drop-in, `/usr/local/sbin/pensaplexa-t3-tokens`, `/etc/pensaplexa`, and the `pensaplexa` account. Archive: `/var/lib/pensaplexa-vm-bridge-20261124/` (root 0700).

## 2026-11-24: Agents back on the public shushingface host

- QuorumWAF now has `AllowLLMProxyFromQuorumEgress` (priority 8, Allow) for the `QuorumEgress-NAT` IP set, which holds cron-data3's `3.226.60.13`, with host `shushingface.quorum.us`. It is capped by `RateLimitLLMProxyFromQuorumEgress` (priority 6, 10,000 requests per 60 s, 429 with `retry-after: 30`). The old 400/60 s rule (priority 17) no longer reaches this traffic.
- At Nei's request, `https://shushingface-admin.quorum.us` became `https://shushingface.quorum.us` again in t3-quentin and t3-quasar `~/.codex/config.toml`, `~/.claude/settings.json` and `~/.config/pensaplexa/agent.env` (backups `*.bak-20261124-admin`). Both agents' keys returned 200 on the public `/v1/models` first.
- Restarted Quasar's `t3code.service` at 19:27 UTC (it was idle). Quentin's T3 was not restarted: its running Codex app-server and older Claude sessions stay on the admin host until they end or T3 restarts; new Claude sessions already use the public host.

## 2026-11-24: Source updater ignores `__pycache__`; bridge restarted

- Root-run Python without `-B` (from other sessions' maintenance scripts) left root-owned `__pycache__` in `/src/read`, and the updater refused the reference again ("Reference contains changes or extra files").
- `/usr/local/bin/update-src.pre-cron-data3-zfs-20261101` now excludes `**/__pycache__/**` from its clean check, and `readonly_tree`/`writable_tree` prune `__pycache__` (its chmod failed on root-owned files). Backup: `/var/lib/cron3-update-src-20261122/update-src.pre-cron-data3-zfs-20261101.bak-20261124-pycache`.
- Tested with a root-owned probe `.pyc` present: the updater fast-forwarded to `e75fcc16d6` and exited 0.
- Restarted `pensaplexa.service` at 18:44:34 UTC on `e75fcc16d6`; no errors or rate limits in the first 100 s.

## 2026-11-24: Two days after the resume

- Backlog drained: 0 pending findings, empty outbox, 0 overdue schedules. Load ~8, ARC 52/72 GiB, dnodes 19/36 GiB, arc_prune idle.
- GitHub secondary rate limits hit on 2026-11-22 17:00-22:00 UTC (~900 journal lines, 254 failed issue POSTs); retries filed them, no duplicate titles among the 250 issues created then. Clean since.
- A Quentin session restarted pensaplexa.service at 19:12 UTC on 2026-11-22 (sudo from a t3-quentin worktree).
- 92 tasks were still parked from the 2026-11-21 21:00 UTC WAF failure wave (the check-ins had been disabled); 4 retried by hand and started fine, the check-ins (re-enabled, 10 per run) do the rest.
- Claude slots: quimby, quizmo, tellurium, claude-quentin at limits until Nov 25-28; claude-actacollecta refresh token invalid (needs re-login).

## 2026-11-22: Agents off the WAF path; source updater unstuck; bridge resumed

- **Agents off the WAF path.** Pointed t3-quentin and t3-quasar at shushingface through the internal ALB. In each account, `https://shushingface.quorum.us` became `https://shushingface-admin.quorum.us` in `~/.codex/config.toml`, `~/.claude/settings.json` and `~/.config/pensaplexa/agent.env`. Backups are suffixed `.bak-20261122-waf`. Restarted both `t3code.service`; Quasar's Codex app-server now connects to `10.23.111.146:443`.
  - The admin host routes every path and has no web ACL; `/v1/models` and `/v1/messages` returned 200 with each agent's own key.
  - It is a stopgap. The clean form is a dedicated internal host name, because the admin host also serves the management API.
  - Why: the public ALB's `QuorumWAF` rule `Quorum-rate-based-rule` blocks a source IP above 400 requests in 60 s, and all of cron-data3 shares `3.226.60.13`.
- **Source updater.** `/usr/local/bin/update-src.pre-cron-data3-zfs-20261101` had refused `/src/read/QuorumUS/actacollecta` every 15 minutes since 2026-11-19 ("Reference contains changes or extra files"). There were two causes:
  - Per-agent and per-person `.env.*` files had been copied into the reference, outside its five-name allowlist. The updater now exempts every ignored `.env.*` regular file. Backup: `/var/lib/cron3-update-src-20261122/`.
  - Root-owned `__pycache__` in `pensaplexa/` and `actaschedule/`, written 2026-11-20 by maintenance scripts run as root from `/src/read`. They were removed; those scripts now run Python with `-B`.
  - The reference fast-forwarded from `6dc8364dac` (2026-11-19) to `906a1f7802`.
- **Resume.** Started `pensaplexa.service` at 16:31:36 UTC on the new code; `actaschedule-dispatcher.timer` stays stopped until the bridge proves stable. Backlog at resume: 90 pending findings and 197 overdue schedules.
- Resume result: in the first 25 minutes there were no GitHub rate-limit errors, no bridge restarts and no real model 403s. One load spike to 240 at 16:35 UTC came from the bridge's catch-up. Pending findings went from 90 to 4. 123 tasks now carry `workflow.retries`, which the new code reads. Started `actaschedule-dispatcher.timer` at 16:45:55 UTC; it is catching up on about 200 overdue schedules, and load stayed at 40-95 with CPU pressure below 5% (one minute at 15%).

## 2026-11-21: Tungsten intake paused

- At 21:27:11 UTC, at Nei's request, stopped `pensaplexa.service` (the bridge) and `actaschedule-dispatcher.timer`. `actaschedule-worker.timer` keeps running and drains messages already queued.
- Reason: since about 21:07 UTC almost every new Claude run failed within seconds with `Failed to authenticate. API Error: 403 Forbidden`. Each failed intake made the bridge file its finding directly, and it retried GitHub issue creation into GitHub's secondary rate limit with no backoff. The journal had 882 rate-limit or 403 lines in 10 minutes.
- Nothing is lost while paused. Findings, the outbox, the Slack cursor and schedules all live in MongoDB. Actaschedule runs missed occurrences on resume instead of skipping them.
- Resume: `sudo systemctl start pensaplexa.service actaschedule-dispatcher.timer`, once Claude runs succeed again.

## 2026-11-21: Root disk alert, leaked spider test PDFs

- Datadog P2 "Host Disk space is low" fired for `/dev/nvme0n1p1` (root ext4) at 90%. `srcpool` is a separate disk and was not involved.
- Root use, 893 of 991 GiB: `/var` 650 GiB (rootless Docker: `t3-quentin` 121 GiB, `t3-cardoso-neto` 112 GiB, system 27 GiB), `/tmp` 106 GiB, `/var/tmp` 73 GiB, `/srv` 59 GiB, `/webapps` 48 GiB.
- The `/tmp` growth was 154,352 `wv_amendment_*.pdf` files (49.6 GB) from `t3-quentin`, 19 GB on 2026-11-20 alone. The spider test suite leaks them: `stage_pdf` writes to `tempfile`'s directory, and only the production pipelines delete the files. `/etc/tmpfiles.d` deletes `/tmp` files after 7 days, which is too slow at this rate.
- Deleted the `wv_amendment_*.pdf` files older than 60 minutes. Root went from 91% to 86% (147 GiB free).
- Fix for the leak: an autouse session fixture in `spiders/tests/conftest.py` that sets `tempfile.tempdir` to a pytest temporary directory.
- At Nei's request, ran `docker builder prune -af` for `t3-quentin`, `t3-cardoso-neto` and the system daemon, with no builds running. Root went from 86% to 75% (250 GiB free). Images and volumes were not touched.
- The leak fix landed as PR #18599.
- Not done, possible next space: old `/var/tmp` work directories (`backlog-10243-dates` 36 GiB, `virgil-consolidation-20261006` 12 GiB, `cron3-canonical-migration-20261026` 9 GiB).

## 2026-11-21: ARC target 72 GiB

- With the 48 GiB target, ARC ran over target (53.1 GiB, 98% metadata: dnodes 20.0, metadata 16.8, dbufs 8.1, bonus 6.7, data 0.9 GiB). `arc_prune` spun at 94% of a core (about 1,250 calls/s), although dnodes were below their 24 GiB limit. In the previous 24 hours, 354 minutes had more than 1,000 prune calls. ARC had filled 48 GiB within about 2 hours of the raise, partly because `zfs_delete_dentry=0` (set the same day) keeps dentries, and with them dnodes, pinned.
- At Nei's request, raised `zfs_arc_max` from 48 to 72 GiB (77309411328) at runtime and in the modprobe file. The dnode limit stays at 50%, now 36 GiB. Regenerated both initramfs images (`-k all`); unpacked, `7.0.0-1014-aws` and `7.0.0-1018-aws` both carry the new option. `storage.verify_tools()` passes.
- Raised the telemetry ARC warning to 144 GiB (`arc_above_144_gib_budget`). Backups: `/var/lib/cron3-arc-bump-20261121/`.
- After the change: `arc_prune` 0 calls over 30 seconds, ARC 54 GiB growing toward the new target, 115 GiB available.
- This is an experiment to see whether the metadata working set levels off below 72 GiB. If it fills 72 GiB again, more RAM is not the fix; test a higher `vm.vfs_cache_pressure` together with `zfs_delete_dentry` instead.

## 2026-11-20: `zfs_delete_dentry` back to 0

- At Nei's request, set `zfs_delete_dentry` from 1 to 0 at runtime and in the modprobe file. With 1, the kernel dropped every unused dentry at once, so repeated path lookups (git status, uv, imports) went back to ZFS. With the 48 GiB ARC and 24 GiB dnode limit, the dnodes that cached dentries pin now fit.
- Regenerated both initramfs images (`update-initramfs -u -k all`); unpacked `7.0.0-1014-aws` (running) and `7.0.0-1018-aws` both carry `zfs_delete_dentry=0`. `storage.verify_tools()` passes.
- After the change, over 30 seconds: `arc_prune` 0 calls, ARC hit rate 99.4%, dnodes 11.5 GB against the 24 GiB limit, 118 GB available, memory PSI 0. Backup of the modprobe file and ARC counters: `/var/lib/cron3-delete-dentry-20261120/`.
- Revert: `echo 1 > /sys/module/zfs/parameters/zfs_delete_dentry`, restore the backup file, and regenerate all initramfs images. Revert if `arc_prune` uses CPU again while dnodes sit at the dnode limit.

## 2026-11-20: ARC target 48 GiB

- At Nei's request, raised `zfs_arc_max` from 32 to 48 GiB at runtime and in the modprobe file, and regenerated the initramfs (`7.0.0-1014-aws`); the unpacked initramfs carries the new option. The dnode limit stays at 50%, now 24 GiB.
- ARC had filled its 32 GiB target (33.9 GB), with 11.4 GB of dnodes against the 16 GiB dnode limit. `arc_prune` used 3.8% of a core over 20 seconds.
- Raised the telemetry ARC warning to 96 GiB (`arc_above_96_gib_budget`). Backups: `/var/lib/cron3-arc-bump-20261120/`.
- After the change: ARC grew to 36.8 GB, dipped to 32.4 GB, then grew again with no direct or indirect reclaim. `arc_prune` used 9%, 15%, and 0% of a core in three 20-second windows. RAM available went from 111 to 113 GiB, and memory PSI stayed near 0.
- `storage.py` `verify_tools()` still requires `zfs_arc_max=4294967296`, and `boot()` runs that check before the pool import. Since the first raise on 2026-11-19, the next boot fails `cron-data3-zfs-storage.service` and does not mount srcpool.
- Fixed the same day: `verify_tools()` now reads the expected ZFS module parameters from `/etc/modprobe.d/90-cron-data3-zfs-20261101.conf`, the file the kernel loads, so a future ARC change cannot break the boot check. It still requires `zfs_arc_max`, `zfs_arc_min` and `zfs_delete_dentry` to be present. Verified: `verify_tools()` and `trusted(HELPER)` pass against the live module, and ownership and mode are still `root:root 755`. Backup: `/var/lib/cron3-arc-bump-20261120/storage.py.before`.

## 2026-11-19: quorum-site cron scheduler removed

- quorum-site's crons had moved to cron-data1, but the `quorum_user` crontab still ran `manage.py run_quorum_crons` (`SERVER="cron_data3"`) every minute. In prod `cron_config_cronjobconfiguration`, only `TestCron` and `DeleteTemporaryFilesCronJob` were still active for `cron_data3`.
- Runs from 2026-10-29 to 2026-11-03 had hung on open sockets: 142 processes holding about 42 GiB of RAM and all of the swap.
- At Nei's request, removed the `run_quorum_crons` line from that crontab and killed every `run_quorum_crons` process: SIGTERM, then SIGKILL for 46 hung ones. The `cw-monitor-memusage.py`, chromedriver, and `/tmp` cleanup lines remain.
- Available memory rose from 92 to 124 GiB, and free swap from 0 to 15.3 GiB.
- Backup of the old crontab: `/var/lib/cron3-quorum-crons-20261119/quorum_user.crontab.before`. If provisioning (Ansible) adds the line back, remove it again or take `cron_data3` off those two configs' `servers`.

## 2026-11-19: ARC target 32 GiB

- At Nei's request, raised `zfs_arc_max` from 24 to 32 GiB at runtime and in the modprobe file, and regenerated the initramfs. The dnode limit stays at 50%, now 16 GiB.
- ARC had already filled its 24 GiB target, and dnodes had grown from 6.5 to 10.6 GB during the legacy→Tungsten migration.
- Raised the telemetry ARC warning to 64 GiB (`arc_above_64_gib_budget`). Backups: `/var/lib/cron3-arc-bump-20261119c/`.
- After the change: ARC 28.9 GB, `arc_prune` at 0%, and 91 GiB of RAM available.

## 2026-11-19: ARC target 24 GiB, dnode limit 50%

- At 12 GiB, `arc_prune` still used 97% of a core. Its trigger is `arc_dnode_limit` (10% of ARC max, so 1.2 GiB), and about 7 GiB of dnodes were cached, so a larger ARC alone could not clear it.
- Set `zfs_arc_max` to 24 GiB and `zfs_arc_dnode_limit_percent` to 50 (a 12 GiB dnode limit) at runtime and in the modprobe file, then regenerated the initramfs.
- Raised the telemetry ARC warning to 32 GiB (`arc_above_32_gib_budget`). Backups: `/var/lib/cron3-arc-bump-20261119b/`.
- Measured over 20 seconds: `arc_prune` dropped from 97% of a core to 0%. The main `arc_evict` thread used 0% both before and after. ARC settled at about 18.9 GB.

## 2026-11-19: ARC target raised to 12 GiB

- The dedup table had grown to 6.4 GiB at a 14x dedup ratio, more than the 4 GiB ARC target. ARC already held 17 GiB of pinned metadata, and `arc_prune` had averaged about 57% of a core for 18 days.
- At Nei's request, set `zfs_arc_max` to 12 GiB at runtime and in `/etc/modprobe.d/90-cron-data3-zfs-20261101.conf`, then regenerated the initramfs for the running kernel and confirmed it carries the new option.
- Raised the telemetry ARC warning in `/usr/local/libexec/cron-data3-zfs-20261101/telemetry.py` from 8 to 16 GiB, renamed `arc_above_16_gib_budget`, keeping it at twice the target.
- Backups of both files: `/var/lib/cron3-arc-bump-20261119/`.
- Memory at the change: 118 GiB available, PSI near 0, and the 16 GiB swap already full of idle pages.

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

## 2026-10-28: Root disk expanded to 1 TiB

- Expanded the root gp3 EBS volume from 512 to 1,024 GiB through `ssh ansible-tower-prod`, using its `AnsibleTowerMinion` role and `--region us-east-1`.
  Cron Data 3's own instance role cannot perform `ec2:ModifyVolume`.
- Grew partition 1 with `growpart /dev/nvme0n1 1`, then grew ext4 online with `resize2fs /dev/nvme0n1p1`.
  No reboot was required.
- Concurrent creation of about 300 Git worktrees delayed `sfdisk` in `sync()` for about nine minutes.
  Monitored free space and dirty pages throughout; observed free space remained above 31 GiB and recovered as writes drained.
  No jobs were paused and no files were removed.
- Verified the disk is 1,024 GiB, partition 1 is about 1,023 GiB, and `df -h /` reports a 991 GiB filesystem with 455 GiB used, 537 GiB available, and 46% usage.

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
