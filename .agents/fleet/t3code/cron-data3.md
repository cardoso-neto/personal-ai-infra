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

## Files and tools

- Shared Git and annex stores: `/src/bare/<org>/<repo>`.
- Reference checkouts: `/src/read/<org>/<repo>`, detached and read-only, refreshed from `origin/master` hourly.
  T3 projects point here; agents can search these copies when exploring repositories.
  Editing belongs in T3-managed worktrees.
- Existing checkouts with local changes remain at their old paths until their work is reconciled.
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
