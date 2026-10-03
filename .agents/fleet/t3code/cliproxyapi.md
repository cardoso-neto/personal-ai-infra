# CLIProxyAPI on Cron Data 3

> 🤖 GPT-6 via Codex on behalf of Nei Cardoso

Installed on 2026-09-24 as `t3-cardoso-neto` on `cron-data3`.
CLIProxyAPI v8.0.4 is pinned as of 2026-09-30; its Linux amd64 release archive passed the published SHA-256 check.
Management Center v1.25.0 is installed, with its release asset SHA-256 verified.
The legacy config and `/v0/management` endpoints remain supported; `/v8/management` is also available.

## Access

- MacBook, `mp600-4tb`, and Cron Data 3: `http://127.0.0.1:8317`.
  - The VM serves directly; the MacBook and `mp600-4tb` use persistent SSH tunnels over their existing Tailscale SSH transport.
  - These tunnels also work independently of MagicDNS.
- Private HTTPS: `https://cron-data3-agent.tailb524d8.ts.net`.
  - Tailscale Serve exposes all routes through a root proxy to `http://127.0.0.1:8317`; the existing `/v1` proxy remains.
  - Console: `https://cron-data3-agent.tailb524d8.ts.net/management.html`, authenticated with the separate management key.
  - Configured persistently with `sudo tailscale serve --bg --yes http://127.0.0.1:8317`.
  - Requires working tailnet DNS/routing; no public Funnel is enabled.
  - [Genesis](genesis.md) uses this endpoint directly; private DNS and HTTPS access were verified on 2026-09-28.
- Each machine has its own inference key in `~/.config/cliproxyapi/client.json` and `client.env`.
  - On the VM these belong to `t3-cardoso-neto`; on the desktop, to `nei`.
  - `client.env` exports `CLIPROXY_BASE_URL` and `CLIPROXY_API_KEY`.
  - Client keys do not grant management access.
  - `client.key` contains the same key for the clients' command-based credential readers.

## Use

Run ordinary `claude` or `codex` on any of the four machines.
Both now default to the proxy through their user configuration files.
The separate `claude-proxy` and `codex-proxy` executables were removed on 2026-09-24.
Existing shell aliases/functions, including the Mac's custom `claude()` wrapper, remain usable.

Claude's user settings set `ANTHROPIC_BASE_URL` and an `apiKeyHelper` that reads `client.key`.
The settings clear inherited Anthropic API/auth token and Claude OAuth token variables so the helper supplies the gateway credential.
Codex's user config selects `model_provider = "cliproxyapi"` and a Responses provider using HTTP/SSE.
Its `auth.command` runs `/bin/cat` on the machine's absolute `client.key` path, so GUI/T3 launches need no shell-exported secret.
Genesis uses NixOS's `/run/current-system/sw/bin/cat` for both credential helpers.
No credential values are stored in the configuration repository.

Genesis was provisioned on 2026-09-28 with its own inference key through the management API.
The key was applied without restarting the proxy; existing client keys remained valid.
Its default models are `claude-opus-5-5[1m]` and `gpt-6-astra`.
See [Genesis's client configuration](genesis.md#claude-code-and-codex) for package versions and paths.

Work subscriptions for Claude and Codex are installed at priority 200.
Quentin subscriptions were previously installed at priority 100; only the two Work auth files were present on 2026-09-28.
Claude Work served successful live requests, confirmed by response trace auth index and success counters.
Claude Quentin authenticated against Anthropic's OAuth usage endpoint; at verification it had used 32% of the five-hour allowance and 95% of the weekly allowance.
Its weekly allowance resets at 2026-09-27 20:00 America/Sao_Paulo.
Codex Work authenticated but returned `workspace_member_credits_depleted` and `usage_limit_reached`, with 100% weekly use.
OpenAI reported reset at 2026-10-01 16:44:06 America/Sao_Paulo.
Before Quentin was connected, the proxy successfully fell back to the paid OpenAI key.
After Quentin was connected, a live `gpt-6-luna` request completed through Codex Quentin, confirmed by its response trace auth index.
The provider keys were transferred from the MacBook's `.zshrc.secrets` over SSH without displaying them.
Paid OpenAI uses `codex-api-key` with explicit base URL `https://api.openai.com/v1` and model IDs returned by that API account.

## Subscription logins

From the MacBook or desktop, open a terminal with both callback forwards:

```sh
ssh -t -o ExitOnForwardFailure=yes \
  -L 127.0.0.1:54545:127.0.0.1:54545 \
  -L 127.0.0.1:1455:127.0.0.1:1455 \
  cron-data3-agent
```

Work is connected for both providers as of 2026-09-28.
To reauthorize a slot, run the helper on the VM with `--replace`, opening the printed authorization URL in the appropriate browser account:

```sh
~/.local/bin/cliproxy-login claude quentin --replace
~/.local/bin/cliproxy-login codex quentin --replace
```

The helper stages each login separately, then installs the credential atomically.
Existing slots require `--replace`.
The running server watches the auth directory; no restart is required for new credentials.

- Work priority: `200`.
- Quentin priority when installed: `100`.
- Paid API priority: `-100`.
- Routing: `fill-first`, session affinity disabled, cooldowns enabled and persisted.
- Codex OAuth and paid API entries enable WebSocket capability consistently.

Higher-priority available credentials are preferred for the requested model.
Fallback also applies to other retryable failures, not only subscription limits.
Return to subscriptions normally follows cooldown expiry; a persisted future deadline can prevent early recovery from being noticed.
Codex Work-to-API failover and subsequent Quentin selection were observed during setup.
On 2026-09-28, clearing a stale Work cooldown restored successful `gpt-6-luna` and `gpt-6-astra` requests through subscription OAuth over HTTP and WebSocket.
Existing WebSocket connections can retain their selected API credential until reconnecting.

### Stale subscription cooldown incident, 2026-09-28

The usage keeper recorded 5,631 requests between September 27 at 10:43 and September 28 at 16:51 Sao Paulo time, all through API keys.
The Codex subscription's September 25 `usage_limit_reached` response supplied an October 1 at 16:44:06 reset deadline.
CLIProxyAPI persisted that deadline in `codex-work.cds` and restored it at its September 28 restart.
By September 28, the same installed subscription reported available quota and completed a direct request, but the router still excluded it until October 1.
The retained records do not establish why the provider's allowance recovered before its earlier deadline.
Nei reports that Tibo often grants everyone a gifted limit reset.
That is a likely explanation for this incident and an expected reason for allowance to recover before a previously reported deadline, although the retained logs do not confirm this particular reset.
The recovery check therefore treats future reset deadlines as subject to change and verifies current availability instead of waiting blindly for expiry.

In v7.3.17, token refresh preserves credential quota cooldowns, and quota observations update display data without clearing scheduler blocks.
There is no periodic reconciliation with the provider's current allowance.
This was a failure to return to a recovered subscription; paid API fallback continued to work.

The local reset endpoint is `POST /v0/management/reset-quota` with the credential's `auth_index`.
It clears runtime and persisted cooldown state without consuming a provider quota-reset credit.
Do not confuse it with the usage keeper's provider quota-reset action, which can consume a reset credit.
Do not disable cooldowns or persistence: that would repeatedly try exhausted subscriptions or merely hide the problem after a restart.

Claude's September 28 block was valid: weekly usage was 100%, extra usage was $400.19 against a $400 limit, and a direct request returned HTTP 429 for the monthly spend limit.
Its next scheduled attempt was September 28 at 21:00:01 Sao Paulo time, matching the weekly reset.

### Automatic subscription recovery

Source and fixture tests: [scripts/cliproxyapi-recovery](../../../scripts/cliproxyapi-recovery/).
The helper is installed at `~/.local/lib/cliproxyapi-recovery/recover.py` for `t3-cardoso-neto`.
`cliproxyapi-recovery.timer` schedules its oneshot service every five minutes, with up to 15 seconds of jitter and persistent catch-up after downtime.
Enabled on 2026-09-28; its first systemd run succeeded and reported `claude: allowance-exhausted` without changing that credential.
The installed helper's Codex diagnostic completed a live OAuth request successfully.
CLIProxyAPI was not restarted.

Only enabled Claude/Codex credentials with a credential-wide quota cooldown qualify.
Active credentials are skipped without a provider request.
For a blocked credential, the helper requires both available provider quota and a completed minimal inference probe through that exact OAuth credential before calling the local reset endpoint.
Exhaustion, authentication/network errors, unknown quota responses, and incomplete probes leave the block intact.
Independent model cooldowns later than the credential deadline are excluded because the reset endpoint clears all model state.
The helper rechecks identity, update metadata, and cooldowns before resetting; the endpoint has no atomic conditional-reset operation.

Provider requests go through authenticated `/v0/management/api-call`, which substitutes OAuth tokens inside CLIProxyAPI.
The helper reads only the existing management key, never copies OAuth credentials, and logs no keys or raw provider responses.
It does not redeem provider reset credits or alter subscription/API priorities.
Unexpected failures produce a failed systemd run and are retried on the next scheduled invocation.

Use the same `sudo -Hu ... env ...` wrapper shown under server operations for these commands:

```sh
systemctl --user list-timers cliproxyapi-recovery.timer
systemctl --user status cliproxyapi-recovery.service
```

The service account cannot read the host journal directly.
From the `nei` maintenance login, read logs with:

```sh
sudo journalctl _SYSTEMD_USER_UNIT=cliproxyapi-recovery.service _UID=992 -n 30 --no-pager
```

For an explicit diagnostic, run the helper with `--check-auth-index <index>`.
It checks quota and makes a minimal inference probe but never resets state.
Default scheduled runs generate no probes for healthy subscriptions and none while quota remains exhausted.
To remove the safeguard, disable `cliproxyapi-recovery.timer`; normal proxy fallback remains unchanged.

The 36 fixture integration cases exercise successful recovery, genuine exhaustion, unknown/malformed responses, failed/incomplete probes, timeouts, disabled credentials, identity/state changes, and independent model restrictions.
Codex may emit successful text in earlier streaming events while leaving the final completion's output list empty; the validator requires a completed, error-free response and observed output across those events.
The installed v7.3.17 binary was separately tested with synthetic preferred/fallback upstreams in an isolated process: same-request 429 fallback, cooldown expiry, stale future deadline, and explicit recovery all passed.
The isolated test does not emulate OAuth persistence or native WebSocket continuation; production OAuth HTTP and new WebSocket requests were verified separately.

## Server operations

Paths below are under `/var/lib/t3code/cardoso-neto`:

- Binary: `.local/opt/cliproxyapi/8.0.4/cli-proxy-api`, linked from `.local/bin/cli-proxy-api`.
- Config and provider keys: `.config/cliproxyapi/config.yaml`.
- Management key: `.config/cliproxyapi/admin.key`.
- Client key inventory: `.config/cliproxyapi/client-keys.json`.
- Subscription files: `.local/state/cliproxyapi/auths/`.
- Error logs: `.local/state/cliproxyapi/logs/`.
- Unit: `.config/systemd/user/cliproxyapi.service`.
- Login helper: `.local/bin/cliproxy-login`.

From an administrator SSH session:

```sh
sudo -Hu t3-cardoso-neto env \
  XDG_RUNTIME_DIR=/run/user/992 \
  DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/992/bus \
  systemctl --user status cliproxyapi.service
sudo journalctl _SYSTEMD_USER_UNIT=cliproxyapi.service -n 50 --no-pager
```

The service starts through the lingering user manager and restarts on failure.
It binds only `127.0.0.1:8317`, uses umask `0077`, and has write access to its private config/state directories.
Debug and normal request logging are disabled; retained error logs can still contain request bodies.
Usage statistics are enabled and are not a durable billing ledger.
Since 2026-09-29, remote model catalog updates are enabled; `--local-model` was removed and the service restarted.
CLIProxyAPI refreshes routing and Codex client catalogs at startup and every three hours, keeping current data if fetching fails.
The authenticated Codex model endpoint listed `gpt-6.1-sol` after the restart.
The previous unit is backed up beside the service as `cliproxyapi.service.before-remote-models-20260929`.
The web management panel downloads separately; periodic automatic panel updates are disabled.

For management, use the private HTTPS console or `http://127.0.0.1:8317/management.html` through a local SSH tunnel, with the separate management key.
`allow-remote` is true and `disable-control-panel` is false.
The backend remains loopback-only; Tailscale Serve is tailnet-only and Funnel is disabled.
Both API and management authentication remain required.

## Client tunnels

- MacBook: `~/Library/LaunchAgents/com.nei.cliproxy-tunnel.plist`.
  - Starts at login, restarts automatically.
  - Error log: `~/Library/Logs/cliproxy-tunnel.log`.
- Desktop: `~/.config/systemd/user/cliproxy-tunnel.service`.
  - Enabled under the existing lingering `nei` user manager.
  - Inspect with `systemctl --user status cliproxy-tunnel.service`.

Both forward local `127.0.0.1:8317` to the VM's `127.0.0.1:8317`.
The Mac tunnel also forwards `127.0.0.1:8318` to the [usage keeper](#usage-keeper).
Server-alive checks reconnect failed tunnels.

- The Mac's default Claude and Codex traffic, including running agents, rides this tunnel.
  - An invalid plist edit or a failed reload cuts API access for every running agent; edit it as a whole and validate before reloading.

## Usage keeper

> 🤖 Claude Opus 5.5 via Claude Code on behalf of Nei Cardoso

Installed on 2026-09-27 as `t3-cardoso-neto`.
[CPA Usage Keeper](https://github.com/Willxup/cpa-usage-keeper) v1.15.9 (MIT) is pinned as of 2026-09-30; its Linux amd64 release archive passed the published SHA-256 check.
It persists the proxy's per-request usage in SQLite and serves a dashboard for usage, cost, request health, and quotas.

- Open `http://127.0.0.1:8318` on the Mac, through the existing tunnel.
  - On the VM, the same URL works directly; the desktop tunnel does not forward 8318.
- Login password: `~/.config/cliproxyapi/usage-keeper.password` on the VM.
  - Also in the Mac's `~/quorum/actacollecta/.env.shush` as `CRON_DATA3_USAGE_PASSWORD`, next to `CRON_DATA3_USAGE_URL`.
- Login protection stays on; scripted `POST`s need the `X-CPA-Usage-Keeper-Request: fetch` header.

Paths below are under `/var/lib/t3code/cardoso-neto`:

- Binary: `.local/opt/cpa-usage-keeper/1.15.9/cpa-usage-keeper`, linked from `.local/bin/cpa-usage-keeper`.
- Settings, without secrets: `.config/cliproxyapi/usage-keeper.env`.
- Unit: `.config/systemd/user/cpa-usage-keeper.service`, enabled under `default.target`.
  - Its `ExecStart` reads `admin.key` and `usage-keeper.password` at start and passes them as `CPA_MANAGEMENT_KEY` and `LOGIN_PASSWORD`; no secret is copied into the unit or settings.
  - Same hardening as `cliproxyapi.service`: umask `0077`, `ProtectSystem=strict`, write access only to its state directory, restart on failure.
- State: `.local/state/cpa-usage-keeper/` (`app.db`, `logs/`, daily `backups/`).
  - The database and backups hold unredacted request metadata.

It binds only `127.0.0.1:8318` and uses `America/Sao_Paulo` for daily totals.
Inspect it like the proxy: `systemctl --user status cpa-usage-keeper.service` and `journalctl _SYSTEMD_USER_UNIT=cpa-usage-keeper.service`.

### Ingest

The keeper auto-selects its ingest mode at start; it runs in `subscribe` mode (RESP `SUBSCRIBE usage` on port 8317, authenticated with the management key).
While a subscriber is connected, the proxy hands each usage record to it instead of queueing it.
On each (re)connect, the keeper drains the queue with `LPOP` to backfill.
The queue keeps records only for `redis-usage-queue-retention-seconds` (default 60, maximum 3600), so a keeper outage longer than that loses usage records.
`usage-statistics-enabled` is on, as the keeper requires.

- Run only one collector against this proxy.
  - Any other `LPOP` or `/v0/management/usage-queue` consumer steals records; a second subscriber is safe only if every collector subscribes.
- The keeper reads management endpoints only; it changes proxy state only through explicit dashboard actions (credential priority, quota refresh).

### Config watch incident, resolved

On 2026-09-27, an attempt to raise the queue retention to 3600 used `sed -i`, which replaced `config.yaml`'s inode.
The proxy watches the config file itself, not its directory, so it lost that inotify watch; the auth-directory watch is intact.
The config was restored byte for byte, in place, so the file matches what the process runs with.

- The September 29 restart restored the config watch; the service restarted again for the September 30 upgrade.
- Restarts drain for 30 s and cut longer streams for every client.
- Edit `config.yaml` in place from now on (`cat new > config.yaml` or the management API), never with `sed -i`, `mv`, or editors that replace the file.
- To check the watch, compare `config.yaml`'s inode with the `ino:` entries in the proxy's inotify `/proc/<pid>/fdinfo`.

### Keeper verification

- The service is active and enabled; `ss` shows it listening only on `127.0.0.1:8318`.
- From the Mac, `/` returned 200; the events API returned 401 without a session, a wrong password returned 401, and the stored password returned 204.
- On first start, the keeper backfilled 17 queued records, then switched to `subscribe`.
- A one-token `claude-haiku-4-5-20251001` Messages request with the Mac client key appeared in `/api/v1/usage/events` within seconds, with matching tokens (9 in, 1 out), status 200, and auth index.

### Keeper rollback

- Stop and disable `cpa-usage-keeper.service`; remove the unit, `.local/bin/cpa-usage-keeper`, and `.local/opt/cpa-usage-keeper/`.
- Delete `usage-keeper.env`, `usage-keeper.password`, and `.local/state/cpa-usage-keeper/` to discard the data.
- Restore the Mac tunnel plist from `~/.config/cliproxyapi/backups/com.nei.cliproxy-tunnel.plist.before-usage-keeper-20260927`, then reload it.
  - Validate the plist with `plutil -lint` first; see the tunnel warning above.
- Remove the `CRON_DATA3_USAGE_URL` and `CRON_DATA3_USAGE_PASSWORD` lines from `.env.shush`.
- The proxy needs no change: with no subscriber, records stay in its queue until retention expires.

## Verification

On 2026-09-30, the v8.0.4 upgrade passed authenticated v0/v8 management and model-list checks.
Unauthenticated model listing returned 401; the panel and usage dashboard returned 200.
Live Claude and Codex requests succeeded, and Keeper v1.15.9 resumed subscription ingestion after applying its database migrations.
Its SQLite database recorded 96 successful requests in the first five minutes after the restart.
All 36 recovery fixtures and six isolated routing/failover checks passed against v8.0.4.
Private upgrade backups, including config, auth files, panel, units, and the stopped Keeper database, are in `.config/cliproxyapi/backups/upgrade-20260930-v8.0.4/`.
The previous versioned binaries remain installed.

- Authenticated model listing succeeded from the VM, MacBook, and desktop.
- Unauthenticated inference requests returned HTTP 401.
- Live Claude Messages and OpenAI Responses requests returned HTTP 200 and the requested short response.
- Ordinary Claude and Codex commands use the saved default proxy configuration.
- Private HTTPS certificate validation and authenticated model listing succeeded from the desktop, using an explicit tailnet address to bypass DNS.
- Since 2026-09-28, the HTTPS console and authenticated management config return HTTP 200; management without a key returns HTTP 401.
- The existing client key lists 73 models over HTTPS; unauthenticated model listing returns HTTP 401.
- Normal Mac HTTPS access validates the certificate and resolves the hostname through macOS split DNS; plain `dig` can misleadingly query a non-Tailscale resolver.
- Claude Work routing, Codex Work-to-API fallback, and Codex Quentin selection were verified with live generation.
- Claude Quentin authentication and remaining quota were verified through Anthropic's OAuth usage endpoint; Work remains the preferred Claude credential.

## Rollback

Stop/disable `cliproxyapi.service` on the VM and `cliproxy-tunnel.service` on the desktop.
Unload the Mac tunnel with `launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.nei.cliproxy-tunnel.plist`.
Disable the private HTTPS proxy with `sudo tailscale serve --https=443 off` on the VM.
Restore each client's original Claude settings and Codex config from its private `~/.config/cliproxyapi/backups/20260925T0211*/` directory before stopping the gateway.
Write back through the existing config symlinks instead of replacing the symlinks.
The clients' original direct authentication stores were retained.
