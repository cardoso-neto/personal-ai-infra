# CLIProxyAPI on Cron Data 3

> 🤖 gpt-6.1-sol via Codex on behalf of Nei Cardoso

The proxy and usage keeper run as `t3-cardoso-neto` on [Cron Data 3](cron-data3.md).
Server paths below are relative to that account's home, `/var/lib/t3code/cardoso-neto`.
Use the deployed config, service units, and management API for current versions, routing, quotas, and model availability.

## Access and client settings

- Local API: `http://127.0.0.1:8317` on the VM, MacBook, and `mp600-4tb`.
  - The MacBook and desktop use SSH tunnels.
- Private HTTPS: `https://cron-data3-agent.tailb524d8.ts.net` through Tailscale Serve.
  - [Genesis](genesis.md#provider-configuration) uses this endpoint directly.
  - Inspect the proxy mapping with `sudo tailscale serve status` on the VM.
- Management console: `/management.html` on either endpoint; management API: `/v0/management`.
  - Management uses `~/.config/cliproxyapi/admin.key` on the VM, separate from inference keys.
- Each client's `~/.config/cliproxyapi/` contains `client.key`, `client.json`, and `client.env`.
  - `client.env` exports `CLIPROXY_BASE_URL` and `CLIPROXY_API_KEY`.
- Ordinary `claude` and `codex` use their saved proxy configuration.
  - Claude: `~/.claude/settings.json`, `ANTHROPIC_BASE_URL`, and `apiKeyHelper` reading `client.key`.
  - Codex: `~/.codex/config.toml`, provider `cliproxyapi`, and `auth.command` reading `client.key`.
  - Genesis uses `/run/current-system/sw/bin/cat` for credential helpers; other clients use `/bin/cat`.
  - Write through existing settings/config symlinks when editing them.

## Server operations

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

## Client tunnels

- MacBook: `~/Library/LaunchAgents/com.nei.cliproxy-tunnel.plist`.
  - Error log: `~/Library/Logs/cliproxy-tunnel.log`.
  - Forwards ports `8317` (proxy) and `8318` (usage keeper).
  - Validate edits with `plutil -lint` before reloading; this tunnel carries running agents' API requests.
- `mp600-4tb`: `~/.config/systemd/user/cliproxy-tunnel.service`.
  - Inspect with `systemctl --user status cliproxy-tunnel.service`.
  - Forwards port `8317`.

## Subscription logins

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

## Automatic subscription recovery

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

[CPA Usage Keeper](https://github.com/Willxup/cpa-usage-keeper) stores per-request usage in SQLite and serves a dashboard.

- Dashboard: `http://127.0.0.1:8318` on the VM or MacBook; the desktop tunnel does not forward this port.
- Password: `~/.config/cliproxyapi/usage-keeper.password` on the VM.
  - Also in the MacBook's `~/quorum/actacollecta/.env.shush` as `CRON_DATA3_USAGE_PASSWORD`, beside `CRON_DATA3_USAGE_URL`.
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
