# Nei's MacBook Pro installation journal

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
