# Genesis

NixOS host.
Use the files and commands below for current configuration, versions, and service status.

## Access

- SSH: `ssh genesis` as `nei`, home `/home/nei`.
- SSH aliases and transport settings: `~/.ssh/config` on the MacBook or `mp600-4tb`.
  - `genesis` uses Tailscale; `genesis-lan` is the LAN fallback.
- Private hostname: `genesis.tailb524d8.ts.net`.
- SSH keys: `/home/nei/.ssh/authorized_keys`, managed outside the NixOS configuration.
- Other account: `martin`, home `/home/martin`.
  - Account definitions, group membership, and linger settings: `/etc/nixos/configuration.nix`.
  - User services and provider credentials belong to each user's home.
- Sudo policy: `sudo -l`; do not assume passwordless access.

## T3 Code

- CLI: `/home/nei/.local/bin/t3`.
- Runtime installations: `/home/nei/.t3/runtime/versions/`.
- State and settings: `/home/nei/.t3/userdata/`, especially `settings.json`.
- User service: `/home/nei/.config/systemd/user/t3code.service`.
  - Inspect its active runtime and listener with `systemctl --user cat t3code.service` and `t3 service status`.
- Service log: `/home/nei/.t3/userdata/logs/boot-service.log`.
- Private HTTPS endpoint: `https://genesis.tailb524d8.ts.net`.
  - Inspect the backend and persistent mapping with `tailscale serve status`.
  - Changing Serve configuration requires sudo.
- T3 Connect account/link state: `t3 connect status`.
- Pairing: `t3 pair --tailscale --label <device>`.
  - To use the existing HTTPS endpoint without changing Serve, use `t3 auth pairing create --ttl 15m --label <device> --base-url https://genesis.tailb524d8.ts.net`.
  - Sessions and expiry: `t3 auth session list`.
  - Keep pairing tokens out of these notes.
- Direct mobile access requires Tailscale on the client.
  - Check [session expiry](https://github.com/pingdotgg/t3code/issues/13055) and the [publish-only mobile entry issue](https://github.com/pingdotgg/t3code/issues/6568) when troubleshooting.
  - A publish-only T3 Connect link provides activity notifications; deregistering it stops those notifications.

## Updates and system maintenance

- User updater: `/home/nei/.local/bin/update-user`.
  - T3 release channel and user package upgrade commands live in this script.
  - Units: `/home/nei/.config/systemd/user/update-user.timer` and `update-user.service`.
  - Schedule/status: `systemctl --user cat update-user.timer` and `systemctl --user list-timers --all`.
  - Results: `journalctl --user -u update-user.service`.
- System updater: `/usr/local/bin/update-system`.
  - NixOS unit definitions: `/etc/nixos/maintenance.nix`.
  - Schedule/status: `systemctl cat update-system.timer` and `systemctl list-timers --all`.
  - Results and reboot requirements: `journalctl -u update-system.service`.
- NixOS configuration: `/etc/nixos/configuration.nix` and its imports.
  - Hardware configuration: `/etc/nixos/hardware-configuration.nix`.
  - Shared source access: `/etc/nixos/src-access.nix`.
  - Apply configuration changes with `sudo nixos-rebuild switch`.
  - Keep `system.stateVersion` unchanged during routine upgrades.
- Package authority: inspect `/etc/nixos/configuration.nix`, `/usr/local/bin/update-system`, and `/home/nei/.local/bin/update-user` before upgrading a CLI.
- Shared checkouts: `/src`; helper scripts: `/usr/local/bin/add-src`, `update-src`, and `sudo-agent`.
- Sleep policy: `systemd.sleep.settings.Sleep` in `/etc/nixos/configuration.nix`.

## Network

- Tailscale: system `tailscaled.service`; identity/state in `/var/lib/tailscale`.
  - Inspect with `tailscale status`, `tailscale ip`, and `tailscale serve status`.
  - Tailnet access policy: [Tailscale admin console](https://login.tailscale.com/admin/acls).
- NetworkManager profiles: inspect with `nmcli connection show` and `nmcli device show`.
  - LAN addressing and DNS settings can live in NetworkManager profiles outside the NixOS configuration.
  - If public DNS fails, inspect the profile's upstream DNS settings; router-provided DNS has caused malformed EDNS replies here.

## Provider configuration

- Claude: `/home/nei/.claude/settings.json`.
- Codex: `/home/nei/.codex/config.toml`.
- Proxy client credentials: `/home/nei/.config/cliproxyapi/` (`client.key`, `client.json`, `client.env`).
- Gateway and provider administration: [CLIProxyAPI on Cron Data 3](cliproxyapi.md).
  - Inspect the saved provider settings for base URLs and models.
  - Keep credential contents out of logs and fleet notes.
