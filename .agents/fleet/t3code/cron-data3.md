# Cron Data 3

Ubuntu VM.
T3 and its agents run as `t3-cardoso-neto`, with home `/var/lib/t3code/cardoso-neto`.
Paths beginning with `~` below refer to that account.

## Access

- Maintenance: `ssh cron-data3`, as `nei`, with passwordless sudo.
- Agent and repository access: `ssh cron-data3-agent` or `ssh cron-data3-agent.tailb524d8.ts.net`, as `t3-cardoso-neto`.
- SSH transport, keys, and host addresses: `~/.ssh/config` on the MacBook or desktop.
- Teleport fallback: `tsh ssh cardoso-neto@cron-data3`, then `sudo -Hu t3-cardoso-neto /bin/bash`.
  Do not use `tsh` inside T3 sessions.
- T3 client: [app.t3.codes](https://app.t3.codes), environment `cron-data3`.

### Production AWS access through the minion

- `ssh ansible-tower-prod` from the MacBook or desktop uses `cron-data3` as its jump host.
- The minion login is `nei`; inspect the client's SSH config for the route and key.
- AWS role and account: `aws sts get-caller-identity` on the minion.
  Production EC2 is in `us-east-1`.
- Teleport fallback: `tsh ssh <github-user>@AnsibleTowerMinionProd`.

### VS Code from the MacBook or desktop

T3's Open in VS Code hostname uses the `cron-data3-agent` SSH entry.
VS Code and T3 agents share the same account, repositories, tools, and credentials.
Coordinate edits with running agents.

### Quorum internal access through the tailnet

Cron Data 3 routes internal Quorum traffic for Nei's tailnet devices without OpenVPN.
The MacBook and desktop accept these subnet routes:

- `10.1.0.0/20`: legacy production VPC, including RDS.
- `10.10.0.0/20`: tools VPC, including Jenkins (`ci.quorum.us`).
- `10.22.0.0/16`: staging Kubernetes API.
- `10.23.0.0/16`: production Kubernetes and database web UI.
- `10.30.0.0/16`: internal tools, including Teleport.
- `172.31.0.0/16`: legacy VPC peering destination.

The tailnet approves these routes on `cron-data3-agent`.
A grant allows `nei.cardoso.neto@gmail.com` to reach them only through `tag:cron-data3`.
Other members and Genesis have no grant to these subnets.
Existing restrictions on connections from Cron Data 3 to personal machines remain in place.

Subnet SNAT uses the VM's `10.1.3.84` address.
Persistent forwarding is in `/etc/sysctl.d/99-quorum-agent-routing.conf`.
No OpenVPN session, exit node, AWS route changes, or tailnet DNS overrides are required.
The tested service names resolve through public DNS to private addresses.
Teleport, AWS, and application authentication still apply.
Public destinations routed by OpenVPN are outside this setup.

To enable route acceptance on another Linux client, run `tailscale set --accept-routes=true` as its Tailscale operator or with sudo.
To stop using the routes on a client, set `--accept-routes=false`.
To disable the router, run `sudo tailscale set --advertise-routes=` on Cron Data 3.
Revoke its subnet route approvals and remove the corresponding grant when retiring the setup.
Policy and route snapshots are on the desktop under `~/.local/state/quorum-subnet-router/20261021/`.

## Files and tools

- Shared Git and annex stores: `/src/bare/<org>/<repo>`.
- Reference checkouts: `/src/read/<org>/<repo>`, detached and read-only, refreshed from the origin default branch (`master` or `main`) by the source updater.
  T3 projects point here; agents can search these copies when exploring repositories.
  Editing belongs in T3-managed worktrees.
- Existing task worktrees retain their paths; installed CLIs use the canonical reference checkout.
  On 2026-10-26 UTC, Quentin and Quasar's private Actacollecta stores were consolidated into `/src/bare/QuorumUS/actacollecta`.
  All 59 adopted checkouts retained their files, exact indexes, HEADs, reflogs, and checkpoint refs; 4,370 existing canonical refs were preserved and 1,506 refs were added.
  Conflicting private branches use `legacy/<account>/<branch>`; original refs also remain under `refs/migration/cron3-20261026/<account>/`.
  Existing T3 worktree paths remain registered worktrees of the shared store.
  The obsolete Quentin and Quasar `/srv/t3code/<account>/actacollecta` roots and Cardoso's `/srv/t3code/cardoso-neto/src/QuorumUS/actacollecta` copy were archived privately and removed on 2026-11-05 UTC.
  The shared store retains its annex identity and filters.
  Quentin's populated project and Quasar's Actacollecta project now point at `/src/read/QuorumUS/actacollecta`; Quasar's datachecks project points at its `/datachecks` subdirectory.
  Seven formerly root-bound threads have explicit legacy cwd bindings; existing thread IDs and histories are preserved.
  Quentin's empty canonical duplicate was removed without force; its populated project and three schedules remain.
  Effective defaults are worktree mode and auto-pull disabled.
  Quentin's overdue interval task ran once through normal startup between Git adoption and its final root update; a fresh stopped-state backup preceded that update.
  T3 services and pilot updater timers were restored; migration guards and updater holds were removed.
  New T3 worktrees for a subdirectory project start at the repository root, so new datachecks work must select that subdirectory explicitly.
  git-annex can replace a new worktree's `.git` file with a symlink; use the git-annex skill's pointer normalization before native removal, with filters disabled during removal to prevent reconversion.
  Full pre-cutover backup, original private Git directories, helpers, and manifests remain under `/var/tmp/cron3-canonical-migration-20261026/`.
  Rehearsal evidence is archived under `/var/lib/cron3-canonical-migration-20261026/evidence/`; disposable rehearsal copies were removed.
  Operator evidence: `~/.local/state/pensaplexa/cron3-canonical-migration-20261026/` on the maintenance Mac.
  Rollback after reopening requires stopping writers and preserving subsequent changes before restoring Git, checkout pointers, and T3 state together; do not blindly restore the pre-cutover snapshot.
- Quentin and Quasar's `~/.local/bin/pensaplexa` links point to `/src/read/QuorumUS/actacollecta/.venv/bin/pensaplexa`.
  The canonical `.venv` is a managed symlink to `/var/lib/actacollecta/venv`; editable package imports resolve under `/src/read`.
  Dependencies stay outside the read-only source checkout.
  Do not recreate separate installed source checkouts.
  Cleanup receipts are in `~/.local/state/quentin-thread-audit-20261104/canonical-cli-cleanup-current.json` on the maintenance Mac.
- Shared repository access: the `src` group can read `/src/read` and write Git metadata under `/src/bare`.
  Add new human and T3 accounts to this group; keep reference refreshes under `t3-cardoso-neto`.
  Setgid directories, default ACLs, and `core.sharedRepository=group` preserve access for new metadata.
  Temporary named user ACLs give existing sessions the same access until their groups refresh.
  Remove these ACLs after all user managers and sessions have refreshed; also remove an account's named ACLs if revoking its access before then.
  Change evidence and bridge notes: `~/.local/state/src-migration-20261019/shared-access/`.
- Global repository helpers: `/usr/local/bin/add-src` and `/usr/local/bin/update-src`.
  System Git configuration includes `/src/git-trust.config`; the reference owner maintains this file.
  Stock T3 auto-pull cannot update detached, read-only references; retain `defaultAutoPull=false` and use the source updater.
  Repository projects must effectively default to `worktree`.
  With folded T3 settings, use `server.updateSettings` project overrides as well as the legacy project fields, preserving other override fields.
  On 2026-10-25, effective worktree mode and disabled auto-pull were verified for all 111 eligible existing canonical repository registrations (103 Quentin, eight Cardoso).
  Roots and 976 saved thread bindings remained unchanged; legacy and missing-root projects were excluded.
- Shared project data: `~/data/<project>/`; keep reusable data outside worktrees.
- Personal instructions and skills: `~/.agents`, linked to the source checkout.
- VM-specific instructions: `~/agents/AGENTS.md` and Codex's `~/.codex/config.toml`.
  Keep them aligned when changing VM guidance.
- User tools: `~/.local/bin`; Node/npm maintenance: `~/.local/bin/weekly-updates.sh`.
- Agent configuration: `~/.claude`, `~/.codex`, and `~/.grok`.
- Shared inference gateway: [CLIProxyAPI](cliproxyapi.md).
- Application videos: `/webapps/quorum-site/quorum_data/videos`.
  Inspect `findmnt` and `lsblk` for current storage.

## ZFS capacity, 2026-11-06

> 🤖 gpt-6.1-sol via Codex on behalf of Nei Cardoso

Expanded `vol-0aae25fae461c2e32` from 256 to 384 GiB at the user's request.
Only EBS size changed; the existing gp3 performance settings were preserved.
Ran `zpool online -e srcpool /dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_vol0aae25fae461c2e32` with the `/opt/zfs/2.4.1/bin/zpool` wrapper.
The whole-disk vdev expanded its GPT partitions online; no manual partition edit or reboot was needed.
At 22:41:42 UTC, the pool had 382 GiB usable physical capacity, 220.05 GiB allocated (57%), 161.95 GiB physically free, and 150.11 GiB available to datasets after ZFS reserves.
The pool was ONLINE with zero read/write/checksum errors, all seven datasets were mounted, and the storage service was active.
AWS had entered `optimizing`; the added capacity was already usable.
The rollout section below records the original 256 GiB configuration.

## ZFS rollout, 2026-11-01

> 🤖 gpt-6.1-sol via Codex on behalf of Nei Cardoso

Status: complete on November 2, 2026.
Cutover and service restoration passed; all seven authorized ext4 originals were deleted by 08:54:52 UTC.
Final absence, exact mount, and service checks passed at 08:56:21 UTC.
The user waived remaining exhaustive checksum/content walks and redundant full-tree verification, and authorized deletion of the seven ext4 originals after successful operational checks.
No deliberate provider-resume or reboot test is claimed.

- EBS: `vol-0aae25fae461c2e32`, encrypted gp3, 256 GiB, 3,000 IOPS, 500 MiB/s provisioned throughput.
  - Attached to this instance, `i-0efffc16d12632a34`, in `us-east-1b`.
  - Throughput is provisioned capacity, not an application read benchmark.
- Pool: `srcpool`, GUID `14288339008813028507`, ownership comment `c3-zfs:vol-0aae25fae461c2e32`.
  - Exact device identity: `/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_vol0aae25fae461c2e32`.
  - Import discovery uses its `-part1` link and the GUID, not a changing NVMe device number.
  - One device, `ashift=12`, fast dedup enabled; no ZFS device redundancy.
  - Pool root: `mountpoint=none`, `canmount=off`, `dedup=off`, `cachefile=none`.
- Selected dataset properties: `compression=zstd-3`, `dedup=sha256`, `recordsize=128K`, `atime=off`, `acltype=posixacl`, `sync=standard`, `canmount=noauto`.
  - They were set before copying data.
  - Matching blocks can deduplicate across these datasets; hard links cannot cross dataset boundaries.
- Matching tools: `/opt/zfs/2.4.1/bin/{zfs,zpool,zdb}`.
  - Loaded module: `2.4.1-1ubuntu5.1` for the current `7.0.0-1014-aws` kernel.
  - Keep absolute wrapper paths in system services; they select private libraries.

All seven datasets are mounted at their fixed final paths:

- `srcpool/src` -> `/src`, including `/src/bare` and `/src/read`.
- `srcpool/cardoso-worktrees` -> `/var/lib/t3code/cardoso-neto/.t3/worktrees`.
- `srcpool/cardoso-uv` -> `/var/lib/t3code/cardoso-neto/.cache/uv`.
- `srcpool/quasar-worktrees` -> `/var/lib/t3code/quasar/.t3/worktrees`.
- `srcpool/quasar-uv` -> `/var/lib/t3code/quasar/.cache/uv`.
- `srcpool/quentin-worktrees` -> `/var/lib/t3code/quentin/.t3/worktrees`.
- `srcpool/quentin-uv` -> `/var/lib/t3code/quentin/.cache/uv`.

Staging uses `/mnt/cron-data3-zfs-20261101/<dataset-suffix>`.
This keeps native Git clone/worktree behavior and existing absolute paths; no overlay or Git shim is introduced.
Existing `.venv` directories move with their worktrees at the same paths.
The installed ancillary integration configures uv `link-mode = "copy"` for all three T3 accounts, while ZFS supplies transparent block sharing.

### Memory and startup controls

- Runtime and persistent module settings are `zfs_arc_max=77309411328` (72 GiB, raised from 4 GiB in steps on 2026-11-19 to 2026-11-21), `zfs_arc_dnode_limit_percent=50`, `zfs_arc_min=268435456` (256 MiB), and `zfs_delete_dentry=0` (the Linux default; set from 1 on 2026-11-20 so the kernel keeps cached path lookups now that the ARC has room for the dnodes they pin).
  - The dnode limit is a percent of ARC max. At the default 10%, cached dnodes (7–11 GB from Quentin's worktrees on 2026-11-19) stay above it, and `arc_prune` uses a full core without freeing anything.
  - Persistent file: `/etc/modprobe.d/90-cron-data3-zfs-20261101.conf`; it is also copied into the initramfs, so run `update-initramfs -u -k all` after changing it (plain `-u` rebuilds only the newest kernel's image, not necessarily the running one).
  - ARC max is a target, not a hard cap on ARC or total ZFS memory; pinned metadata can exceed it.
  - Stop further rollout if ARC exceeds 144 GiB (telemetry warning `arc_above_144_gib_budget`), `MemAvailable` falls below 32 GiB, or sustained swap activity or memory PSI appears.
  - Preserve active work and investigate; do not automatically kill agents, drop global caches, or delete workspaces to meet the gate.
- Minute telemetry is installed as `srcpool-telemetry.timer` and `srcpool-telemetry.service`.
  - Read samples with `sudo journalctl -u srcpool-telemetry.service`.
  - Inspect ARC/dnode/dbuf metadata, memory pressure, swap rates, pool allocation, and DDT growth together.
  - ARC subcategories overlap and must not be added as independent totals.
- Persistent storage startup is installed, enabled, active, and passed exact mount guards and systemd verification.
  - Unit: `cron-data3-zfs-storage.service`.
  - Helper/config: `/usr/local/libexec/cron-data3-zfs-20261101/storage.py` and `/etc/cron-data3-zfs-20261101.json`.
  - It imports only the configured GUID with `-N`, verifies device/properties/module settings, and mounts only the seven configured datasets.
  - `guard cardoso`, `guard quasar`, and `guard quentin` check `/src` plus the account's worktree/cache mounts; `guard all` checks all seven.
  - T3 and guarded source/log jobs check required mounts before startup or writes.
  - The helper's `install` mode still writes a `pensaplexa.service` drop-in; the unit is gone, so the drop-in would be inert.
  - Deliberate missing-mount refusal was not tested under the shortened rollout scope.
  - User-manager ordering does not impose a hard storage dependency on unrelated applications.
- Do not stop whole user managers during maintenance.
  - Preserve Cardoso's shared `cliproxyapi.service`, `cpa-usage-keeper.service`, `cliproxyapi-recovery.timer`, and unrelated Docker workloads.
  - Pause Pensaplexa, schedules and updaters; stop scoped T3/provider slices and verify actual writers before final synchronization.
  - Database run statuses alone did not identify all live provider processes during preflight.
- No reboot validation was performed.
  - Current startup loads the module after the root filesystem is available; real-root modprobe configuration supplies the settings.
  - The older `6.17.0-1012-aws` fallback has ZFS 2.3.4 and is deliberately refused by the helper.
  - Check matching module/tool support before kernel changes or fallback boots.

### Validation, evidence, and rollback

Pensaplexa stopped at 2026-11-01 19:19:06 UTC; T3 request gating began at 19:38:29 UTC.
The maintenance window became prolonged during exhaustive checksum and metadata enumeration.
T3 restarted at 2026-11-02 07:35 UTC; request gates were removed at 07:35:38 UTC, after 11 hours 57 minutes 9 seconds.
Pensaplexa resumed at 07:52:08 UTC, after 12 hours 33 minutes 2 seconds stopped.
An SSH transport interruption did not stop the remote quick copy; it was not restarted.
Schedule restoration recovered from an RPC timeout with fresh connections.
One legitimate new Quentin thread and schedule created after reopening were preserved.

Completed checks passed exact mounts/startup guards, native Git/uv smoke tests for all three accounts, six existing Python 3.14/native-extension imports, all 103 repository records, 3,370 baseline bindings, 5,508 selected paths, 810 virtual environments, and T3 health.
The final state check preserved all 32 original schedule definitions and enabled states (17 enabled), held queues (Cardoso 3, Quentin 7), cron except its approved guard executable, and six updater timer states.
Docker, nginx, user managers, the shared gateway, Pensaplexa, and telemetry are healthy.
At the final operational check, Quentin totals included the resumed-work additions: 2,447 bindings and 33 schedules, 18 enabled.
Deliberate missing-cache refusal, pool export/import rehearsal, and further full-tree verification were omitted under the shortened scope.
The five completed `/src`, Cardoso, and Quasar checksum/metadata proofs are reused.
Only Quentin worktrees/cache were reconciled using normal `rsync -aHAX --open-noatime --numeric-ids --delete` size/mtime checks.
Use the fresh quiesced snapshots as the authority; thread and schedule counts changed legitimately during staging.
The preflight found 228 broken Git pointers (Cardoso 158, Quasar 2, Quentin 68); unchanged pointers are known baseline issues, not migration regressions.
Do not repair or prune them as an undocumented storage change.

- Initial post-restoration pool status: `ONLINE`, zero read/write/checksum errors, 120.51 GiB allocated, 133.49 GiB free, reported dedup ratio 2.69x.
  - This is not an exact ext4 space-saving measurement; the source allocated-space baseline is incomplete.
- The 699-sample audit through November 2 07:52:57 UTC recorded no threshold warnings or OOMs.
  - ARC peak 4.10 GiB, available RAM minimum 142.94 GiB, 23.3 MB total host swap-out, and 4.96 seconds total full memory PSI stall over nearly 12 hours.
  - Minute samples can miss short peaks; host counters do not attribute activity to ZFS.
- Durable host state: `/var/lib/cron-data3-zfs-20261101/`.
  - Root-private seven-path map: `migration-manifest.json`.
  - Maintenance controls and backups: `control/maintenance/`; quiescence proof: `control/writers-quiesced/writers.json`.
  - Final copy logs, marker-renewal evidence, and `cutover.jsonl` identify completed transitions; inspect them before recovering a partial cutover.
- Operator state on the maintenance Mac: `~/.local/state/pensaplexa/cron-data3-zfs-20261101/`.
  - [Rollout and recovery procedure](/Users/neicardosoneto/.local/state/pensaplexa/cron-data3-zfs-20261101/ROLLOUT.md).
  - [Quiesced metadata baseline](/Users/neicardosoneto/.local/state/pensaplexa/cron-data3-zfs-20261101/inventory/final-pre-cutover.json) and [existing-environment baseline](/Users/neicardosoneto/.local/state/pensaplexa/cron-data3-zfs-20261101/inventory/env-final-pre.json).
  - [Memory investigation](/Users/neicardosoneto/.local/state/pensaplexa/cron-data3-zfs-20261101/memory/FINDINGS.md) and [staging memory audit](/Users/neicardosoneto/.local/state/pensaplexa/cron-data3-zfs-20261101/memory/staging-complete-memory-audit-20261101.json).

Cutover renamed the seven originals to `<original-path>.ext4-pre-zfs-20261101`; user-authorized cleanup deleted all seven by 2026-11-02 08:54:52 UTC.
The bounded background runner verified ledger inode/device identities, ext4 backing, no symlinks/mounts/descendant mounts, and no active process dependencies.
All small rollout/control/application-state backups and unrelated directories remain.
The seven `deleted` records and `/var/lib/cron-data3-zfs-20261101/cleanup-complete.json` are present; the cleanup unit exited with status 0.
[Final absence and health evidence](/Users/neicardosoneto/.local/state/pensaplexa/cron-data3-zfs-20261101/evidence/07-final-readonly.log) passed at 08:56:21 UTC.
Root ext4 has 669.11 GiB available; `srcpool` is `ONLINE` with zero errors, 121.72 GiB allocated and 132.28 GiB free, and reported dedup ratio 2.77x after resumed work.
The last minute sample shows ARC 3.61 GiB, available RAM 149.22 GiB, no threshold warning, and zero memory PSI averages.
Rollback requires stopping writers and reconstructing full trees from current ZFS or independent backups; renaming the former originals is no longer available.
Budget destination capacity for decompressed, undeduplicated data and preserve local/untracked changes, numeric ownership, ACLs, xattrs, symlinks, hard links, Git state, and application state consistently.
Small SQLite/control backups do not contain the complete migrated trees.
Removing startup integration or setting `dedup=off` does not restore data or undo existing dedup references.

## Root disk maintenance

For authorized EBS changes, use `ssh ansible-tower-prod` and run AWS CLI commands with `--region us-east-1`.
Its `AnsibleTowerMinion` role can modify EBS volumes; Cron Data 3's own instance role cannot.
The access policy is documented in `~/quorum/actacollecta/docs/aws-roles.md` on the maintenance Mac.
Resolve the current root volume from the instance block-device mapping and confirm it matches the NVMe serial before changing it.

After increasing the EBS volume, confirm Linux sees the new disk size, then run `sudo growpart /dev/nvme0n1 1` and `sudo resize2fs /dev/nvme0n1p1` on Cron Data 3.
Verify the current device names first with `findmnt` and `lsblk`.
Both operations support online growth.
Under heavy writes, `growpart` can wait in `sfdisk` while `sync()` flushes dirty pages; let the existing operation finish before retrying or changing the partition table.

## T3 and services

- Direct VPN/private-network HTTPS uses `cron-data3.quorum.us`, whose explicit Route53 A record points to `10.1.3.84` in zone `Z3DWB2B67PJTUQ`.
  - Personal: `https://cron-data3.quorum.us:3773`.
  - Quasar: `https://cron-data3.quorum.us:3774`.
  - Quentin: `https://cron-data3.quorum.us:3775`.
  - Nginx binds each migrated port on `10.1.3.84` and forwards HTTP/WebSocket traffic to the same port on loopback.
    Site files: `/etc/nginx/sites-available/t3code-<account>`; enabled sites: `/etc/nginx/sites-enabled/`.
  - Migrated T3 services use `~/.config/systemd/user/t3code.service.d/zz-https-loopback.conf`, loaded after the existing overrides.
- Trusted certificate: exportable ACM certificate `arn:aws:acm:us-east-1:596070161069:certificate/900b38fd-fbad-48b1-909f-8c13bcf8a53e`, shared by all three ports.
  - Keep its DNS validation CNAME for managed renewal.
  - `t3code-certificate.timer` checks daily and after boot; its service uses the existing instance role to export and deploy changed certificates, then reload Nginx.
  - Helper: `/usr/local/sbin/t3code-refresh-certificate`; configuration and root-only keys: `/etc/t3code-https/`.
  - ACM charges $7 for the hostname at issuance and renewal under the pricing checked at setup.
- Migration scripts: `/var/tmp/t3code-https-20261031/`; original host and bridge configuration: `/var/lib/t3code-https/backup-20261031/`.
  - `cutover-instance <account>` refuses active or runnable queued work by default; it preserves held queues.
  - Completed cutovers are recorded under `/var/lib/t3code-https/cutovers/`.
  - Operator evidence: `~/.local/state/t3code/cron-data3-https-20261031/` on the maintenance Mac.
- The Pensaplexa bridge runs in Kubernetes since 2026-11-24 (Actacollecta's `pensaplexa/README.md`, "Operations"); nothing of it runs here.
  - It reaches Quasar and Quentin's direct HTTPS endpoints.
  - At each start it issues its T3 tokens over SSH as `t3-quasar` and `t3-quentin`.
    Their `~/.ssh/authorized_keys` let the `pensaplexa-bridge` key run only `/usr/local/sbin/pensaplexa-t3-auth`.
  - Do not recreate `pensaplexa.service`: a second bridge splits Slack events, and the old token renewal revokes the Kubernetes bridge's sessions.
- T3 home: `~/.t3`; `~/t3` is a compatibility symlink used by stored paths.
- State and settings: `~/.t3/userdata`; logs: `~/.t3/userdata/logs`.
- Runtime selection: `~/.t3/runtime/service-state.json` and `~/.t3/runtime/versions/`.
- T3 service: `~/.config/systemd/user/t3code.service`.
- Environment overrides: `~/.config/systemd/user/t3code.service.d/`, including `tools.conf` for PATH and Docker access.
- Rootless Docker: `docker.service` in the same user manager.
- Tailscale daemon: system `tailscaled.service`; inspect `tailscale status` and `tailscale serve status` for connectivity.
- Private Tailscale HTTPS: `https://cron-data3-agent.tailb524d8.ts.net:8443` maps to T3 at `http://127.0.0.1:3773`.
  Ports `8444` and `8445` map to Quasar and Quentin's loopback ports `3774` and `3775`.
  These existing routes remain available alongside direct VPN access.
  Inspect `tailscale serve status` before changes; HTTPS port `443` serves CLIProxyAPI.
- The VM's LAN address is inside the corporate VPC and has no direct path from the home LAN.

From the maintenance login, inspect a user service with:

```sh
t3_service_uid=$(id -u t3-cardoso-neto)
sudo -Hu t3-cardoso-neto env \
  XDG_RUNTIME_DIR=/run/user/"$t3_service_uid" \
  DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/"$t3_service_uid"/bus \
  systemctl --user status t3code.service
```

Use the same wrapper with `systemctl --user cat` for the effective unit and overrides.
The unit supplies the executable and environment; the listener is `127.0.0.1:3773`.
For host journal access, use `sudo journalctl _UID="$t3_service_uid" _SYSTEMD_USER_UNIT=t3code.service` from the maintenance login.

## Rootless Docker

`t3-cardoso-neto`, `t3-quentin`, `t3-quasar`, and the `nei` maintenance login each have a rootless daemon.
Their `docker.service` user units and systemd linger are enabled.
Each account selects the `rootless` Docker context at `unix:///run/user/$(id -u)/docker.sock`.
Use `docker` and `docker compose` without sudo; images, containers, and volumes are separate per account.
Docker SDKs can require `export DOCKER_HOST="unix:///run/user/$(id -u)/docker.sock"` because they do not read CLI contexts.

The Cardoso T3 account retains its existing private Docker 29.7.2 installation under `~/.local/bin`.
The other three accounts use Ubuntu's Docker 29.1.3 and its packaged RootlessKit, slirp4netns, and UID mapping tools.
Matching upstream rootless setup scripts are installed in `/usr/local/bin`; `/usr/local/bin/docker` links to `/usr/bin/docker` for the setup tool.
AppArmor's existing `/usr/bin/rootlesskit` profile permits user namespaces.
Quentin's subordinate UID/GID range is `558752-624287`; Quasar's is `624288-689823`.
The existing ranges for Cardoso and Nei are unchanged.

Quentin and Quasar have `t3code.service.d/docker.conf` overrides for `DOCKER_HOST`.
These take effect on the next T3 restart; the selected CLI contexts work in existing sessions.
Provisioning did not request a T3 restart; Quentin's service stayed running.
Publish local test services on `127.0.0.1` with an available host port; separate daemons can otherwise select the same published port.

Quentin and Quasar's three `INFRA.md` links now point to per-account copies at `~/.config/pensaplexa/INFRA.md`.
These copies preserve the shared source's other guidance and replace the obsolete Docker restriction.
The read-only shared reference remains unchanged so hourly source refreshes can continue.
The corresponding source edit is in `agent-personas/INFRA.md` in the maintenance checkout; a future persona deployment can restore source-backed links after that change lands.
Provisioning logs, original documentation, and original link targets: `/var/tmp/cron3-rootless-docker-RkZqSnS0/`.

## Updates and scheduled work

- Schedules and update commands: the T3 account's `crontab -l`; also inspect `systemctl --user list-timers --all`.
- T3 update output: `~/.local/state/t3code-update/latest.log`.
- Other maintenance output: `~/.local/state/`; helper scripts: `~/.local/bin/`.
- Repository helpers: `~/.local/bin/add-src` and `~/.local/bin/update-src`, maintained in [super-system-stuff/shared/src](https://github.com/cardoso-neto/super-system-stuff/tree/master/shared/src).
  The installed `/usr/local/bin/update-src` refreshes Actacollecta every 15 minutes and all repositories daily at 04:07 UTC under `t3-cardoso-neto`.
  Its cleanliness guard permits only the exact managed `.venv` symlink and managed environment files in Actacollecta.
  Status and fast-forward commands ignore ctime churn without disabling annex filters; permission updates make only directories writable and skip entries already in the required mode.
- Agent log archive: `~/.agent-logs/sync-agent-logs.sh`, scheduled hourly at minute 7.
  Its writable worktree is under the account's home; the old `/srv/t3code/cardoso-neto/src/cardoso-neto/agent-logs` path is a compatibility symlink.
  Host data: `data/hosts/cron-data3`; run log: `~/.local/state/agent-logs/agent-logs-sync.log`.
- Manual T3 upgrades: use the client's Update server action; restarting the service interrupts active work.
  Verify continuation through live thread projections and fresh provider activity after a restart; persisted SQLite run statuses can remain stale.

## Google Drive

- Remote: `employer-drive:` for `nei.cardoso@quorum.us`.
- Credentials: `~/.config/rclone/rclone.conf`; keep its contents private.
- Connection check: `rclone lsf employer-drive: --max-depth 1 --dirs-only >/dev/null`.
- Reauthorization: `rclone config reconnect employer-drive:` as the T3 account.
  For browserless login, run the printed `rclone authorize` command on a client with a browser and return the token to the VM.

Historical setup and repair records: [installation journal](cron-data3.journal.md).
