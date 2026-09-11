# Nei's MacBook Pro installation journal

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
