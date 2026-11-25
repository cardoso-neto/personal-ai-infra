# CLIProxyAPI: Shushingface and retired Cron Data 3

> 🤖 gpt-6.1-sol via Codex on behalf of Nei Cardoso

The retired proxy and Usage Keeper used `t3-cardoso-neto` on [Cron Data 3](cron-data3.md).
Historical server paths below are relative to that account's home, `/var/lib/t3code/cardoso-neto`.
Shushingface now serves personal devices and agents; the retained Cron server procedures below are historical.

## Retirement on 2026-11-03

`cliproxyapi.service`, `cpa-usage-keeper.service`, and `cliproxyapi-recovery.timer` are stopped and disabled.
The configuration, credentials, original database, and binaries remain for recovery.
The operations below describe the retained installation; its endpoints are offline.

- Final verified snapshot on the VM: `~/.local/state/cliproxyapi-retirement/20261103/cron-final.db`.
- Verified off-host copy on the MacBook: `~/.local/state/cliproxyapi-retirement/20261103/cron-final.db`.
- The Cron history is merged into the live Shushingface Usage Keeper; all four historical device keys are attributed to Nei.
- Cron Data 3's Quentin and Quasar T3 setups and Cron Data 2's Questor use `https://shushingface.quorum.us` with distinct `QUENTIN_T3`, `QUASAR`, and `QUESTOR` client keys.
  Kubernetes Quentin retains `QUENTIN`; Nei has the separate `NEI` key.
  Before the split at about 21:25 UTC, the four agent setups shared `QUENTIN`, so that key's older history contains mixed agent traffic.
- Detailed cutover, validation, and rollback record on the MacBook: `~/.local/state/cliproxyapi-retirement/20261103/RETIREMENT.md`.
- Personal-device verification and backup paths: `~/.local/state/cliproxyapi-retirement/20261103/personal-devices-cutover-report.json` on the MacBook.

## Current client settings

- Inference: `https://shushingface.quorum.us`.
  - The MacBook, `mp600-4tb`, and [Genesis](genesis.md#provider-configuration) use the personal `NEI` key in explicit proxy clients and T3 Claude/Codex providers.
  - Codex uses the `/v1` API base; Claude uses the base URL without that suffix.
  - Separate agent keys are listed in the retirement section above.
- Admin API: `https://shushingface-admin.quorum.us/v0/management`; usage dashboard: `https://shushingface-usage.quorum.us`.
  - Admin and usage endpoints require the VPN.
  - Current operator and client keys are inventoried in `~/quorum/actacollecta/.env.ops.shush` on the MacBook.
    Retired `CRON_DATA3_*` fields were removed.
- Each client's `~/.config/cliproxyapi/` contains `client.key`, `client.json`, and `client.env`.
  - `client.env` exports `CLIPROXY_BASE_URL` and `CLIPROXY_API_KEY`.
  - `aliases.sh` defines explicit `claude-proxy` and `codex-proxy` commands using Shushingface.
  - New shells load the updated aliases; existing shells can reload them with `. ~/.config/cliproxyapi/aliases.sh`.
- Ordinary `claude` and `codex` use direct provider access and their own saved logins.
  - Their user settings contain no proxy endpoint or credential helper.
  - Write through existing settings/config symlinks when editing them.
- T3 Code supplies proxy configuration per provider instance in Settings -> Providers.
  - Claude keeps its existing config directory; T3 supplies `ANTHROPIC_BASE_URL` and a sensitive `ANTHROPIC_API_KEY`.
  - Codex keeps its shared home and sessions, with separate API-key authentication in `~/.codex-t3/cliproxyapi/auth.json`.
  - Its T3 launch arguments select `cliproxyapi`, set `requires_openai_auth=true`, and use file credential storage.
  - These API-key connections have no native subscription quota; the hub supplies the pooled account limits.
- T3's Usage providers entry `Shushingface` is stored on the MacBook environment.
  - Its legacy dictionary ID contains `cron-data3`, but its actual URL is `https://shushingface-admin.quorum.us`.
  - Usage -> Limits shows the hub's accounts across connected environments.
  - Migration backups and the local configuration manifest are under `~/.config/cliproxyapi/`.

## Historical: server operations

- Binary: `~/.local/bin/cli-proxy-api`, linked into `~/.local/opt/cliproxyapi/`.
- Config and provider API keys: `~/.config/cliproxyapi/config.yaml`.
- Management key: `~/.config/cliproxyapi/admin.key`.
- Client key inventory: `~/.config/cliproxyapi/client-keys.json`.
- Subscription credentials and persisted cooldowns: `~/.local/state/cliproxyapi/auths/`.
- Error logs: `~/.local/state/cliproxyapi/logs/`; these can contain request bodies.
- Unit: `~/.config/systemd/user/cliproxyapi.service`.
- Login helper: `~/.local/bin/cliproxy-login`.
- Private backups: `~/.config/cliproxyapi/backups/`.

From the `nei` maintenance login (`ssh cron-data3`), operate the service account's user manager:

```sh
cliproxy_uid=$(id -u t3-cardoso-neto)
sudo -Hu t3-cardoso-neto env \
  XDG_RUNTIME_DIR=/run/user/"$cliproxy_uid" \
  DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/"$cliproxy_uid"/bus \
  systemctl --user status cliproxyapi.service
sudo journalctl _SYSTEMD_USER_UNIT=cliproxyapi.service _UID="$cliproxy_uid" -n 50 --no-pager
```

Use the same wrapper for the recovery timer and usage keeper.
The service account cannot read the host journal directly.

### Config file watch

The proxy watches `config.yaml` itself.
Edit it in place or through the management API; replacing its inode with `sed -i`, `mv`, or an editor can detach the watch.
After replacement, restart the service to restore the watch.
Restarts interrupt active streams, including requests from running agents.

## Retired client tunnels

The MacBook launch agent is unloaded and disabled; the `mp600-4tb` user service is stopped and disabled.
Genesis has no `cliproxy-tunnel.service` unit.
These retained definitions and the diagnosis below describe the historical setup; do not reconnect them for Shushingface.

- MacBook: `~/Library/LaunchAgents/com.nei.cliproxy-tunnel.plist`.
  - Error log: `~/Library/Logs/cliproxy-tunnel.log`.
  - Forwards ports `8317` (proxy) and `8318` (usage keeper).
  - The retained plist is disabled; its backup path is in the personal-device report.
- `mp600-4tb`: `~/.config/systemd/user/cliproxy-tunnel.service`.
  - Inspect with `systemctl --user status cliproxy-tunnel.service`.
  - Forwards port `8317`.

### Historical tunnel diagnosis

A listening port does not prove that the SSH tunnel forwards requests.
First check the affected client's endpoint: a client configured for private HTTPS does not use this tunnel.
Check `curl --max-time 5 http://127.0.0.1:8317/` and compare with `https://cron-data3-agent.tailb524d8.ts.net/`.
If the local request times out while the private HTTPS endpoint responds, reconnect the Mac tunnel with `launchctl kickstart -k "gui/$(id -u)/com.nei.cliproxy-tunnel"`.
This closes existing streams through that tunnel.
Retest the local endpoint and a small inference request before concluding that agent latency has recovered.

## Historical: subscription logins

From the MacBook or desktop, forward OAuth callback ports while logging in as the T3 account:

```sh
ssh -t -o ExitOnForwardFailure=yes \
  -L 127.0.0.1:54545:127.0.0.1:54545 \
  -L 127.0.0.1:1455:127.0.0.1:1455 \
  cron-data3-agent
```

On the VM, use `~/.local/bin/cliproxy-login <claude|codex> <slot> --replace` to reauthorize an existing slot.
Open the printed URL in the intended provider account.
The helper installs credentials atomically; the proxy watches the auth directory, so logins need no service restart.
Inspect current slot names and priorities in the auth directory or management API.

## Historical: automatic subscription recovery

- Source, fixture tests, and unit definitions: [scripts/cliproxyapi-recovery](../../../scripts/cliproxyapi-recovery/).
- Deployed helper: `~/.local/lib/cliproxyapi-recovery/recover.py`.
- User units: `cliproxyapi-recovery.timer` and `cliproxyapi-recovery.service` in `~/.config/systemd/user/`.
  - Inspect scheduling with `systemctl --user list-timers cliproxyapi-recovery.timer` through the wrapper above.
  - Read logs with `sudo journalctl _SYSTEMD_USER_UNIT=cliproxyapi-recovery.service -n 30 --no-pager`.
- Diagnostic: run `python3 ~/.local/lib/cliproxyapi-recovery/recover.py --check-auth-index <index>` as `t3-cardoso-neto`.
  - It checks quota and makes a minimal inference probe; it does not reset state.

Recovery checks blocked subscriptions before clearing stale local cooldowns.
It requires available provider quota and a completed inference probe for that credential.
`POST /v0/management/reset-quota` clears local cooldowns; it does not spend a provider quota-reset credit.
The usage keeper's provider reset action can spend one.
Keep cooldown persistence enabled; inspect recovery failures before manually clearing blocks.

## Usage keeper

This section describes the retired Cron installation.

[CPA Usage Keeper](https://github.com/Willxup/cpa-usage-keeper) stores per-request usage in SQLite and serves a dashboard.

- Dashboard: `http://127.0.0.1:8318` on the VM or MacBook; the desktop tunnel does not forward this port.
- Password: `~/.config/cliproxyapi/usage-keeper.password` on the VM.
  - The old `CRON_DATA3_*` fields were removed from the MacBook's `.env.ops.shush`; current Shushingface fields are documented there.
- Binary: `~/.local/bin/cpa-usage-keeper`, linked into `~/.local/opt/cpa-usage-keeper/`.
- Settings: `~/.config/cliproxyapi/usage-keeper.env`.
- Unit: `~/.config/systemd/user/cpa-usage-keeper.service`.
  - Reads `admin.key` and `usage-keeper.password` at startup.
  - Inspect with the service-account wrapper and journal commands above, substituting `cpa-usage-keeper.service`.
- State: `~/.local/state/cpa-usage-keeper/`, including `app.db`, `logs/`, and `backups/`.
  - Database and backups contain unredacted request metadata.
- Scripted authenticated `POST`s need `X-CPA-Usage-Keeper-Request: fetch`.

Run one collector per proxy.
Other queue consumers can steal records, and reconnect backfill uses the proxy's bounded queue.
Inspect `usage-statistics-enabled` and `redis-usage-queue-retention-seconds` in `config.yaml` when diagnosing missing records; outages beyond retention lose usage data.
