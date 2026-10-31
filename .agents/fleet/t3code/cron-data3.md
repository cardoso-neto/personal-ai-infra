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
- Reference checkouts: `/src/read/<org>/<repo>`, detached and read-only, refreshed from `origin/master` hourly.
  T3 projects point here; agents can search these copies when exploring repositories.
  Editing belongs in T3-managed worktrees.
- Existing checkouts with local changes remain at their old paths until their work is reconciled.
- Shared repository access: the `src` group can read `/src/read` and write Git metadata under `/src/bare`.
  Add new human and T3 accounts to this group; keep reference refreshes under `t3-cardoso-neto`.
  Setgid directories, default ACLs, and `core.sharedRepository=group` preserve access for new metadata.
  Temporary named user ACLs give existing sessions the same access until their groups refresh.
  Remove these ACLs after all user managers and sessions have refreshed; also remove an account's named ACLs if revoking its access before then.
  Change evidence and bridge notes: `~/.local/state/src-migration-20261019/shared-access/`.
- Global repository helpers: `/usr/local/bin/add-src` and `/usr/local/bin/update-src`.
  System Git configuration includes `/src/git-trust.config`; the reference owner maintains this file.
- Shared project data: `~/data/<project>/`; keep reusable data outside worktrees.
- Personal instructions and skills: `~/.agents`, linked to the source checkout.
- VM-specific instructions: `~/agents/AGENTS.md` and Codex's `~/.codex/config.toml`.
  Keep them aligned when changing VM guidance.
- User tools: `~/.local/bin`; Node/npm maintenance: `~/.local/bin/weekly-updates.sh`.
- Agent configuration: `~/.claude`, `~/.codex`, and `~/.grok`.
- Shared inference gateway: [CLIProxyAPI](cliproxyapi.md).
- Application videos: `/webapps/quorum-site/quorum_data/videos`.
  Inspect `findmnt` and `lsblk` for current storage.

## T3 and services

- T3 home: `~/.t3`; `~/t3` is a compatibility symlink used by stored paths.
- State and settings: `~/.t3/userdata`; logs: `~/.t3/userdata/logs`.
- Runtime selection: `~/.t3/runtime/service-state.json` and `~/.t3/runtime/versions/`.
- T3 service: `~/.config/systemd/user/t3code.service`.
- Environment overrides: `~/.config/systemd/user/t3code.service.d/`, including `tools.conf` for PATH and Docker access.
- Rootless Docker: `docker.service` in the same user manager.
- Tailscale daemon: system `tailscaled.service`; inspect `tailscale status` and `tailscale serve status` for connectivity.
- Private Tailscale HTTPS: `https://cron-data3-agent.tailb524d8.ts.net:8443` maps to T3 at `http://127.0.0.1:3773`.
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
  `update-src` discovers shared bare repositories and refreshes their reference checkouts hourly at minute 17.
- Agent log archive: `~/.agent-logs/sync-agent-logs.sh`, scheduled hourly at minute 7.
  Its writable worktree is under the account's home; the old `/srv/t3code/cardoso-neto/src/cardoso-neto/agent-logs` path is a compatibility symlink.
  Host data: `data/hosts/cron-data3`; run log: `~/.local/state/agent-logs/agent-logs-sync.log`.
- Manual T3 upgrades: use the client's Update server action; restarting the service interrupts active work.

## Google Drive

- Remote: `employer-drive:` for `nei.cardoso@quorum.us`.
- Credentials: `~/.config/rclone/rclone.conf`; keep its contents private.
- Connection check: `rclone lsf employer-drive: --max-depth 1 --dirs-only >/dev/null`.
- Reauthorization: `rclone config reconnect employer-drive:` as the T3 account.
  For browserless login, run the printed `rclone authorize` command on a client with a browser and return the token to the VM.

Historical setup and repair records: [installation journal](cron-data3.journal.md).
