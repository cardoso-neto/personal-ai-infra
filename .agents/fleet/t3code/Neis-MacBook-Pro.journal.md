# Nei's MacBook Pro installation journal

## 2026-10-21: Stalled inference-proxy tunnel recovered

- Found the Mac's SSH tunnel listening on `127.0.0.1:8317` but returning no data in repeated 4-10 second HTTP probes.
  The private Tailscale HTTPS endpoint responded, MP600's tunnel responded in about 0.26 seconds, and the proxy on Cron Data 3 responded locally in under a millisecond.
- Reconnected `com.nei.cliproxy-tunnel` with `launchctl kickstart -k`.
  Subsequent HTTP probes returned 200 in 0.29-0.77 seconds.
  A small streamed `gpt-6.1-sol` request returned its first text in 3.14 seconds and completed successfully.
- Confirmed public provider addresses still use the home internet route, outside the Quorum subnet routes.
  No evidence established that the subnet setup caused the stalled tunnel or explained every historical agent delay.
  Kept routing and provider configuration unchanged.
- Follow-up inspection found Mac T3 provider settings already used private Tailscale HTTPS.
  The stalled tunnel affected the localhost path; it does not establish the cause of the reported T3 thread's latency.
- Changed `~/.config/cliproxyapi/aliases.sh`, `client.env`, and `client.json` to use private Tailscale HTTPS for new explicit proxy sessions.
  Backups: `~/.config/cliproxyapi/backups/direct-tailscale-2026-10-21T17-31-55.909Z/`.
  Verified authenticated model listing, a streamed GPT response, and a Codex WebSocket connection over HTTPS.
  Left the tunnel running for existing sessions and the usage keeper dashboard.

## 2026-09-14: Tailscale service started

- Nei started the system service with `sudo /opt/homebrew/bin/brew services start tailscale`.
- Verified that the client can contact Tailscale and that its state is `NeedsLogin`.
- Requested enrollment as `neis-macbook-agent` with DNS changes and subnet acceptance disabled for the initial SSH test.
- Network diagnostics succeeded, including UDP connectivity and reachability of Tailscale relays.
- Account enrollment and the Mac-to-VM test remain pending.

## 2026-09-13: LAN SSH verified; Tailscale installation started

- Connected from `mp600-4tb` with `ssh neicardosoneto@Neis-MacBook-Pro.local` using the existing key.
- Verified macOS 26.3.1 and hostname `Neis-MBP`.
- Installed the Homebrew Tailscale 1.102.4 formula.
- `sudo -n true` returned `sudo: a password is required`.
  Service startup requires local administrator authentication.
- Quorum tailnet enrollment and the Mac-to-VM SSH test remain pending.

## By 2026-09-07: T3 setup and verification

- Installed T3 globally through Homebrew's npm prefix, with lifecycle scripts allowed for `msgpackr-extract` and `node-pty`.
  The CLI lives at `/opt/homebrew/bin/t3`; `t3 service update` installs the service runtime.
- Registered a user LaunchAgent and linked T3 Connect for relay access.
  Retained existing T3 state and power settings.
  The service PATH includes persistent user and Homebrew binary directories.
- The service pins an exact Homebrew Node path.
  Update the service before Homebrew cleanup removes that version.
  Avoid running older T3 releases against a migrated database.
- T3 `0.0.39` shipped its macOS `node-pty` spawn helper without executable permission, causing `Error: posix_spawnp failed.`
  Applied `chmod u+x` to `node_modules/node-pty/prebuilds/darwin-arm64/spawn-helper` in both the global T3 package and `~/.t3/runtime/versions/0.0.39`.
  Check equivalent paths if terminal creation fails after an update.
- Verified the environment endpoint, live relay registration in the service log, agent authentication, and a real pseudo-terminal spawn.
  `t3 connect status` reports saved state; it alone does not confirm a live tunnel.

## 2026-10-03: Grok npm copy removed

Grok ran from `~/.grok/bin`, but `npm update --global` also maintained `@xai-official/grok` under `/opt/homebrew/lib/node_modules`.
Its postinstall rewrote the shared `~/.grok/config.toml` to `installer = "npm"`, which sent `grok update` through npm on every machine.
Uninstalled the npm copy, dropped Grok from `autoupdate.sh`'s npm steps, and let `grok update` record `installer = "internal"`.
Homebrew has no xAI Grok formula; its `grok` is an unrelated regex tool.
