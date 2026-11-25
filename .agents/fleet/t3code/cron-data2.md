# Cron Data 2

Questor's T3 account is `t3-questor`, UID 993, with home `/var/lib/t3code/questor`.
Paths beginning with `~` below refer to that account.
Use `tsh ssh cardoso-neto@cron-data2` for maintenance.

## Direct HTTPS access

- Questor endpoint: `https://cron-data2.quorum.us:3774`, reachable through the Quorum VPN/private network.
- DNS: Route53 zone `Z3DWB2B67PJTUQ`; the explicit A record points to `10.1.3.117`.
- Nginx listens on `10.1.3.117:3774` and proxies HTTP/WebSocket traffic to `127.0.0.1:3774` on the same host.
  - Site: `/etc/nginx/sites-available/t3code-questor`.
  - `nginx.service` starts at boot.
  - T3's `~/.config/systemd/user/t3code.service.d/zz-https-loopback.conf` sets its loopback binding after `pilot.conf`.
- Certificate: exportable ACM certificate `arn:aws:acm:us-east-1:596070161069:certificate/ec5bdb71-98f0-459d-bb74-80f9d7f1d5bd`.
  - Retain its DNS validation CNAME for managed renewal.
  - `t3code-certificate.timer` checks daily and after boot; `t3code-certificate.service` exports and deploys a changed certificate, then reloads Nginx.
  - Helper: `/usr/local/sbin/t3code-refresh-certificate`; configuration and root-only keys: `/etc/t3code-https/`.
  - Uses the instance's existing ACM permissions; no stored AWS access keys or interactive SSO are required for renewal.
  - ACM charges $7 per hostname at issuance and renewal under the pricing checked at setup.
- The Pensaplexa bridge (Kubernetes) uses the direct HTTPS endpoint.
  At each start it issues its T3 token over SSH as `t3-questor`, whose `authorized_keys` lets the `pensaplexa-bridge` key run only `/usr/local/sbin/pensaplexa-t3-auth`.
  The temporary Cron Data 3 Tailscale Serve proxy on port 8446 was removed.
- Setup evidence and original host configuration: `/var/lib/t3code-https/backup-20261031/` on Cron Data 2, and `~/.local/state/t3code/cron-data2-https-20261031/` on the maintenance Mac.

Generate a fresh pairing link only when the client is ready:

```sh
sudo -Hu t3-questor env HOME=/var/lib/t3code/questor T3CODE_HOME=/var/lib/t3code/questor/.t3 \
  /var/lib/t3code/questor/.t3/runtime/versions/<activeVersion>/t3 auth pairing create \
  --ttl 1h --label Nei --base-url https://cron-data2.quorum.us:3774 --json
```

Resolve `<activeVersion>` from `~/.t3/runtime/service-state.json`.
Do not store pairing tokens in these notes.

## Other T3 accounts

Each account has linger, a user `t3code.service` bound to loopback, and an Nginx site `t3code-<name>` on `10.1.3.117:<port>`.
All sites share the certificate above.

- `t3-cardoso-neto` (3773): Nei; home `/var/lib/t3code/cardoso-neto`; passwordless sudo, `src` group.
- `t3-lucas` (3775): Lucas Assis; home `/var/lib/t3code/lucas`; no sudo; own checkouts under `/srv/t3code/lucas`.
- `t3-rich-leland` (3776): Richard Leland (`rich.leland@quorum.us`), provisioned 2026-11-18.
  - Home `/home/rich-leland`; moved from `/var/lib/t3code/rich-leland` before first use.
    - Older T3 logs and event history still name the old path; no compatibility symlink exists.
  - Passwordless sudo through `/etc/sudoers.d/t3-rich-leland`.
    - Root here reaches cron-data and cron-data3 as root through the cron SSH mesh in `/root/.ssh/cron-mesh.conf`.
  - `src` group; projects `actacollecta` and `quorum-site` are rooted at `/src/read`, with worktree mode and auto-pull off.
  - Claude Code and Codex in `~/.local/bin` use Richard's own subscription logins, not Shushingface.
  - Rootless Docker, subordinate ID range `493216-558751`.
  - Git identity is set; GitHub access needs `gh auth login` and `gh auth setup-git` as that account.
  - Provisioning script and log: `/var/tmp/t3code-rich-leland-20261118/` on the host and `~/.local/state/t3code/cron-data2-rich-leland-20261118/` on the maintenance Mac.

## ZFS trial status

The approved trial is identified as `cron-data2-zfs-trial-20261025`.
Cutover completed on 2026-10-25 UTC; Questor was restarted and the temporary network gates were removed.
All ten original thread bindings were preserved.

- Dedicated EBS volume: `vol-0e4226d98e2219e31`, encrypted, 128 GiB, gp3.
  - Grown online from 64 GiB on 2026-11-20 UTC; no T3 stop or reboot.
    - Resize: `aws ec2 modify-volume --size` from `AnsibleTowerMinionProd`, then `zpool online -e srcpool <vdev>` with the private tools.
    - The guard's `verify_device` checks the exact disk size in bytes (now `137438953472`); update it with any later resize, or boot will fail.
    - Guard backup: `configure-startup.sh.bak.20261120T131919Z.sj3N9h` beside the installed helper.
      The archived copy under `/var/lib/cron-data2-zfs-trial-20261025/scripts/` still expects 64 GiB; do not reinstall from it unchanged.
- Pool: `srcpool`, GUID `12643406911339345213`.
  - Ownership comment: `c2-zfs:vol-0e4226d98e2219e31`.
  - Device identity: `/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_vol0e4226d98e2219e31`.
  - One disk vdev, `ashift=12`, fast dedup enabled.
  - Pool root: `mountpoint=none`, `canmount=off`, `dedup=off`.
- Private OpenZFS 2.4.1 tools: `/opt/zfs/2.4.1/bin`.
  - These match the host's preloaded Ubuntu ZFS module 2.4.1.
  - Inspect the storage unit's `TOOLS_DIR` and `/sys/module/zfs/version` before maintenance.
- Dataset properties: `compression=zstd-3`, `dedup=sha256`, `recordsize=128K`, `atime=off`, `sync=standard`.
  - Final datasets use `canmount=noauto`; the scoped startup unit owns mounting.
  - `acltype=posix` enables the shared-source default ACLs; ZFS's default ACL setting was insufficient.
- ARC: `zfs_arc_max=103079215104` (96 GiB), `zfs_arc_dnode_limit_percent=50` (48 GiB dnode limit), `zfs_arc_min=268435456` (256 MiB).
  - Raised from 4 GiB and the default 10% dnode limit on 2026-11-20 UTC, at runtime and in `/etc/modprobe.d/cron-data2-zfs-trial.conf`.
    That file is also in the initramfs, so run `update-initramfs -u -k all` after any change (plain `-u` rebuilds only the newest kernel's image; on 2026-11-20 it left 7.0.0-1018-aws at the old 4 GiB cap until fixed).
    Backups and before-state: `/var/lib/cron2-arc-bump-20261120/`.
  - Why: the kernel's dentry/inode cache pinned about 62 GiB of ARC metadata (25 GiB dnodes) against a 4 GiB target and a 410 MiB dnode limit.
    `arc_prune` used a full core for days and freed nothing (6.5 CPU-days in 11 days of uptime), and the hit rate fell to about 89–95%.
    The dedup table was not the cause: 160 MiB in core.
  - ARC max is a target, not a hard cap; pinned metadata can exceed it.
    In telemetry, ARC size followed pool allocation (69 GiB of ARC at 59 GiB allocated on 2026-11-20), so the 128 GiB volume can outgrow 96 GiB.
    If `arc_prune` uses CPU again, compare `dnode_size` with `arc_dnode_limit` in `/proc/spl/kstat/zfs/arcstats`.
  - Stop further increases if `MemAvailable` falls below 32 GiB, or if swap activity or memory PSI continues.

## Source and workspace layout

- `srcpool/src` -> `/src`.
  - Shared Git stores: `/src/bare/QuorumUS/actacollecta`, `/src/bare/QuorumUS/quorum-site`, and `/src/bare/pingdotgg/t3code`.
  - Detached, read-only references use the matching paths under `/src/read`.
  - Shared access uses the `src` group, setgid directories, default ACLs, and `core.sharedRepository=group`.
  - System Git configuration includes `/src/git-trust.config`.
  - `/usr/local/bin/add-src` and `/usr/local/bin/update-src` run as the reference maintainer, `t3-questor`.
    They serialize updates through `/src/.update-src.lock`.
    The updater accepts only a clean detached reference and a fast-forward update.
- `srcpool/worktrees` -> `~/.t3/worktrees`.
  - This retains T3's default worktree path.
- `srcpool/uv-cache` -> `~/.cache/uv`.
  - Cache and worktrees are separate datasets; do not assume cross-dataset hardlinks.
  - `~/.config/uv/uv.toml` sets `link-mode = "copy"` to avoid repeated hardlink fallback warnings.
    ZFS still deduplicates matching written blocks across the datasets.
- Questor's `~/.local/bin/pensaplexa` points to `/src/read/QuorumUS/actacollecta/.venv/bin/pensaplexa`.
  The canonical `.venv` is a managed symlink to `/var/lib/actacollecta/venv`; editable package imports resolve under `/src/read`.
  Dependencies stay outside the read-only source checkout.
  The obsolete `/srv/t3code/questor/actacollecta` checkout was archived privately and removed on 2026-11-05 UTC.
  Do not recreate a separate installed source checkout.
  The updater permits only the exact managed `.venv` symlink, ignores ctime churn in status and fast-forward commands, and avoids unnecessary permission changes.

The existing T3 project ID is `9f385338-28d7-4a63-8718-572c82c42568`.
Its canonical root is `/src/read/QuorumUS/actacollecta`, with `autoPull=false` and `defaultThreadEnvMode=worktree`.
It reuses this project rather than creating another project.
The `quorum-site` project is `64bf3e95-4f7c-5ac5-991e-b1ce10b8fd18`, rooted at `/src/read/QuorumUS/quorum-site`, with the same auto-pull and worktree defaults.
It has full Git history and passed native detached worktree creation/removal.
The existing updater discovers all shared stores automatically, using each repository's default branch (`main` for `pingdotgg/t3code`).
The T3 source reference has full history and passed native detached worktree creation/removal; it has no separate T3 project registration.
Both registered projects also have effective server settings `defaultAutoPull=false` and `defaultThreadEnvMode=worktree`.
On versions with `projectSettingsFolded=true`, maintain these through `server.updateSettings` project overrides; the legacy project fields alone do not control the effective defaults.
Stock auto-pull cannot advance detached, read-only references; leave refreshes to `update-src`.
Linked worktrees still share Git metadata; filesystem deduplication does not isolate repository configuration or refs.
The migrated actacollecta store's shared `config` enables `extensions.worktreeConfig`; `core.bare=true` belongs in that store's `config.worktree`, not shared config.
Keeping that flag private lets unmodified `git worktree add` create usable checkouts.
The existing worktrees retain their private configuration.

T3 state remains at `~/.t3/userdata`, outside the three trial datasets.
Runtime selection is in `~/.t3/runtime/service-state.json`.
The user service is `~/.config/systemd/user/t3code.service`; its local HTTP port is 3774.

## Startup and operation

The root oneshot is `/etc/systemd/system/cron-data2-zfs-storage.service`.
It verifies the exact volume, pool GUID, ownership marker, matching tools/module, and dataset properties before mounting the selected datasets.
An upgrade away from module 2.4.1 requires matching tools and a guard update before restarting Questor.
If import is needed, it imports only GUID `12643406911339345213` through the owned device partition, without mounting all datasets.
Do not substitute a broad pool import or mount command.

- Root dependency: `/etc/systemd/system/user@993.service.d/90-cron-data2-zfs-trial-20261025.conf`.
  - `user@993.service` requires and starts after `cron-data2-zfs-storage.service`.
- User guard: `~/.config/systemd/user/t3code.service.d/90-cron-data2-zfs-trial-20261025.conf`.
  - `ExecStartPre` runs `/usr/local/libexec/cron-data2-zfs-trial-20261025/storage-ready.sh`.
  - This guard checks each exact mountpoint and dataset source; it does not import or mount storage.
- Root helper: `/usr/local/libexec/cron-data2-zfs-trial-20261025/configure-startup.sh`.
  - Inspect its `check`, `boot`, and `rollback-instructions` modes before use.
  - Keep generic ZFS mount services, fstab entries, and generated mount units from competing for these datasets.

Inspect `systemctl cat cron-data2-zfs-storage.service user@993.service`, the merged user `t3code.service`, and their journals for effective configuration and failures.
Run the storage-ready helper to check mounts before starting writers.
Check pool health, capacity, allocation, dedup table growth, ARC, and errors with the matching private tools.
The earlier cron-data3 loop-device benchmarks are not measurements of this EBS trial.

- `src-update.timer` refreshes references hourly at minute 17 through `src-update.service`, running as `t3-questor`.
  - Its unattended refresh passed using the account's existing GitHub CLI credentials, configured with `gh auth setup-git`.
- `srcpool-telemetry.timer` records pool allocation, dedup-table/cache counters, dataset usage, ARC counters, and host available memory every 15 minutes.
  - Inspect `journalctl -u srcpool-telemetry.service`; these counters do not establish savings without a matched baseline.

Cutover checks passed: file/index/HEAD/status and ref preservation for the legacy checkout and ten existing worktrees; a clean detached reference at `origin/master`; native worktree creation/removal; and an offline uv package install into a fresh environment on ZFS.
The mount guard rejected both a missing cache mount and an exported pool.
The installed storage service then imported the exact pool and restored all three mounts.
A host reboot, provider-session resume, and a full project dependency installation were not exercised.
Annex payloads were absent before migration; the trial did not hydrate them.

## Recovery and rollback

Trial scripts and execution evidence are archived on the operator's machine at `~/.local/state/pensaplexa/cron-data2-zfs-trial-20261025/`.
Host scripts are retained under `/var/lib/cron-data2-zfs-trial-20261025/scripts/`.
`configure-startup.sh` and `storage-ready.sh` also have installed host copies in `/usr/local/libexec/cron-data2-zfs-trial-20261025/`.
Use the trial owner's execution record for completed steps and exact invocation arguments.

Retain these host backups:

- `/var/lib/cron-data2-zfs-trial-20261025/backup/`: T3 userdata, user units, and prior system Git configuration.
- `/srv/t3code/questor/.actacollecta.src-migration-20261025/`: original `source.git` and private `manifest.json`.
- `~/.t3/worktrees.ext4-pre-zfs-20261025`: pre-cutover worktrees.
- `~/.cache/uv.ext4-pre-zfs-20261025`: pre-cutover uv cache.
- Adjacent `.bak.TIMESTAMP.XXXXXX` files for startup files replaced by the installer.

1. Stop external launches and all writers, including T3, updater jobs, terminals, and the UID 993 user manager.
   Stop `src-update.timer` and `srcpool-telemetry.timer` and wait for their services to finish before changing mounts.
   Check for remaining UID 993 processes before changing mounts or Git metadata.
2. Preserve and reconcile newer state before returning to ext4.
   Sync current worktrees, Git refs/objects/annex data, and any required cache or T3 state to the selected rollback storage while writers remain stopped.
   The old backups are not current after writers resume.
3. Inspect the installed helper's `rollback-instructions` output to remove or restore only trial-owned startup files, then reload the affected managers.
   This changes boot integration only; it does not revert Git conversion, dataset properties, or data mounts.
4. Review `relocate-git.py` and its manifest before reverting Git conversion.
   Its immediate rollback requires the same explicit paths and frozen state; it refuses changed Git metadata or working files.
   After subsequent writes, reconcile state and plan the metadata reversal rather than forcing that rollback.
5. Verify the selected backing directories, Git pointers, worktree registrations, T3 project root, and effective startup dependencies before restarting writers.
   Do not unmount or export a pool in use, destroy the pool, delete backups, or detach the volume as part of an unverified rollback.

Keep the backups until the trial outcome and recovery procedure have been accepted.
