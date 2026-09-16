# Nei's MacBook Pro

## Access

Sign in to [app.t3.codes](https://app.t3.codes) as `nei.neto@hotmail.com` and select `Nei's MacBook Pro` (shown with a typographic apostrophe).
T3 Connect provides remote access; the server listens on `127.0.0.1:3773`.
T3 and its agents run as `neicardosoneto`.
Keep the Mac logged in and awake for access.

LAN SSH from `mp600-4tb` works with its existing SSH key:

```sh
ssh neicardosoneto@Neis-MacBook-Pro.local
```

Use the mDNS name rather than a saved DHCP address.
The Mac reports its hostname as `Neis-MBP`.
Administrator commands require a password; unattended SSH does not provide sudo access.

SSH to Cron Data 3 through Tailscale, independently of the corporate VPN:

```sh
ssh cron-data3
```

The alias uses `~/.ssh/id_ed25519_cron_data3` and `/opt/homebrew/bin/tailscale nc`.

## Tailscale

Tailscale 1.102.4 was installed through Homebrew on 2026-09-13.
The system service `sh.brew.tailscale` is running, and the machine is enrolled in the tailnet.
Access to `cron-data3` through Tailscale is verified.
Do not also install the graphical Tailscale client while using this daemon.

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
