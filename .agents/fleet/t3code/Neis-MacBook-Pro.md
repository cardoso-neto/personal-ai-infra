# Nei's MacBook Pro

## Access

Sign in to [app.t3.codes](https://app.t3.codes) as `nei.neto@hotmail.com` and select `Nei's MacBook Pro` (shown with a typographic apostrophe).
T3 Connect provides remote access; the server listens on `127.0.0.1:3773`.
T3 and its agents run as `neicardosoneto`.
Keep the Mac logged in and awake for access.

SSH to Cron Data 3 through Tailscale, independently of the corporate VPN:

```sh
ssh cron-data3
```

The alias uses `~/.ssh/id_ed25519_cron_data3` and `/opt/homebrew/bin/tailscale nc`.

## Locations

- Personal repositories: `~/cardoso-neto/<repo>`.
- Upstream repositories: `~/upstream/<org>/<repo>`.
- Personal instructions and skills: `~/.agents`; follow its symlink to the source repository.
- T3 state: `~/.t3/userdata`; runtime: `~/.t3/runtime`.
- LaunchAgent: `~/Library/LaunchAgents/com.t3tools.t3code.service.plist`.
- Service log: `~/.t3/userdata/logs/boot-service.log`.

The LaunchAgent starts at login and restarts T3 after failure.
Inspect it for the service command and environment; use `t3 service status` and `t3 connect status` for status.

Setup decisions and repair history: [installation journal](Neis-MacBook-Pro.journal.md).
