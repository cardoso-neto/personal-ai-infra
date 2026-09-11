# T3 Code on Nei's MacBook Pro

Last verified: 2026-09-07.

## Access

Sign in to [app.t3.codes](https://app.t3.codes) as `nei.neto@hotmail.com` and select the environment named after this Mac's Computer Name, `Nei's MacBook Pro` (shown with a typographic apostrophe).
T3 Connect exposes the environment through its managed relay; the application listens only on `127.0.0.1:3773`.

T3 and its agents run as `neicardosoneto`, with that user's filesystem access and credentials.
Keep this environment and its Connect authorization private.

## Installation

- macOS 26.3.1, Apple Silicon.
- T3 Code: `0.0.39`, installed globally through Homebrew's npm prefix.
- CLI: `/opt/homebrew/bin/t3`.
- Node.js: `26.8.1`.
- Service Node: `/opt/homebrew/Cellar/node/26.8.1/bin/node`.
- State and existing project/conversation history: `/Users/neicardosoneto/.t3/userdata`.
- Service runtime: `/Users/neicardosoneto/.t3/runtime`.
- LaunchAgent: `~/Library/LaunchAgents/com.t3tools.t3code.service.plist`.
- Log: `~/.t3/userdata/logs/boot-service.log`.
- Relay: `https://relay.t3.codes`.
- Managed Cloudflared: `2026.5.2`, under `~/.t3/tools/cloudflared`.

Codex is authenticated through ChatGPT.
GitHub CLI is authenticated as `cardoso-neto`.
The LaunchAgent PATH contains persistent user and Homebrew binary directories.

## Service and availability

The LaunchAgent starts at login and restarts the server after failure.
Keep the Mac logged in and awake for remote access; logging out or sleeping makes it unavailable.
The existing power settings were retained: idle sleep after 70 minutes on AC and 15 minutes on battery.

```sh
t3 service status
t3 connect status
launchctl print gui/$(id -u)/com.t3tools.t3code.service
launchctl kickstart -k gui/$(id -u)/com.t3tools.t3code.service
tail -n 100 ~/.t3/userdata/logs/boot-service.log
```

To keep it awake temporarily while plugged in, run this in a terminal and leave it running:

```sh
caffeinate -s
```

This does not provide access after logout or guarantee operation with the lid closed.

## Verification

```sh
curl --max-time 15 --fail --silent \
  http://127.0.0.1:3773/.well-known/t3/environment
t3 connect status
codex login status
gh auth status
```

The environment endpoint must return HTTP 200 and the Mac's label.
Connect status must report enabled exposure, a stored credential, and a provisioned environment link.
This command reports saved state; the service log must also show `Relay client tunnel connection registered` for live tunnel confirmation.

Setup verified these checks and a real pseudo-terminal spawn.

## Updates and repair

```sh
npm install --global --no-audit --no-fund \
  --allow-scripts=msgpackr-extract,node-pty t3@VERSION
t3 service update
```

Recheck the service and Connect after updating.
The service pins an exact Homebrew Node path; repair the service before removing that Node version during a Homebrew cleanup.
Do not start an older T3 release against the migrated database.

The `0.0.39` installation shipped its macOS `node-pty` helper without executable permission, causing `Error: posix_spawnp failed.`
Setup corrected the owner execute bit in both installed copies:

```sh
chmod u+x ~/.t3/runtime/versions/0.0.39/node_modules/node-pty/prebuilds/darwin-arm64/spawn-helper
chmod u+x /opt/homebrew/lib/node_modules/t3/node_modules/node-pty/prebuilds/darwin-arm64/spawn-helper
```

If terminal creation fails after an update, check the equivalent paths for the installed version.

To replace Connect authorization:

```sh
t3 connect logout
t3 connect link
launchctl kickstart -k gui/$(id -u)/com.t3tools.t3code.service
t3 connect status
```

To stop the service and remove startup registration, run `t3 service uninstall`.
This retains projects, threads, and settings.
Use `t3 connect unlink` to disable exposure or `t3 connect logout` to also clear the Connect login.

Treat authorization codes, pairing links, and credential files as secrets.
Back up `~/.t3` only to an encrypted destination.
