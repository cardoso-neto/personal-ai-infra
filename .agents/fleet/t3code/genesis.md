# Genesis

> 🤖 gpt-6.1-sol via Codex on behalf of Nei Cardoso

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
  - Native network binding: `/home/nei/.config/systemd/user/t3code.service.d/network.conf` sets `T3CODE_HOST=0.0.0.0`.
  - Direct LAN and Tailscale access use the native listener; the `t3-lan-proxy` socket and service were removed.
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
- Mobile can connect directly over LAN or through Tailscale; the private HTTPS endpoint requires Tailscale on the client.
  - Check [session expiry](https://github.com/pingdotgg/t3code/issues/13055) and the [publish-only mobile entry issue](https://github.com/pingdotgg/t3code/issues/6568) when troubleshooting.
  - A publish-only T3 Connect link provides activity notifications; deregistering it stops those notifications.

## Updates and system maintenance

- User updater: `/home/nei/.local/bin/update-user`.
  - T3 release channel and user package upgrade commands live in this script.
  - Maintains nei's native Claude and user-local npm Grok installation.
  - Units: `/home/nei/.config/systemd/user/update-user.timer` and `update-user.service`.
  - Schedule/status: `systemctl --user cat update-user.timer` and `systemctl --user list-timers --all`.
  - Results: `journalctl --user -u update-user.service`.
- System updater: `/usr/local/bin/update-system`.
  - NixOS unit definitions: `/etc/nixos/maintenance.nix`.
  - Schedule/status: `systemctl cat update-system.timer` and `systemctl list-timers --all`.
  - Results and reboot requirements: `journalctl -u update-system.service`.
- Tailscale updater: `update-tailscale`, managed by `/etc/nixos/tailscale-updates.nix`.
  - Checks official stable releases hourly, with up to five minutes of delay and persistent catch-up.
  - Uses `/etc/nixos/tailscale-package.nix`, `tailscale-version.json`, and `update-tailscale.sh` to apply checksum-verified upstream binaries through NixOS.
  - Shares `/run/update-system.lock` with the system updater; rebuilds without upgrading the system channel.
  - Inspect: `systemctl status update-tailscale.timer`, `journalctl -u update-tailscale.service`, or `update-tailscale --check`.
  - Run now: `sudo systemctl start update-tailscale.service`.
  - Native `tailscale update` is unsupported on this NixOS installation.
- NixOS configuration: `/etc/nixos/configuration.nix` and its imports.
  - Hardware configuration: `/etc/nixos/hardware-configuration.nix`.
  - Shared source access: `/etc/nixos/src-access.nix`.
  - Apply configuration changes with `sudo nixos-rebuild switch`.
  - Keep `system.stateVersion` unchanged during routine upgrades.
- Package authority: inspect `/etc/nixos/configuration.nix`, `/usr/local/bin/update-system`, and `/home/nei/.local/bin/update-user` before upgrading a CLI.
- Shared checkouts: `/src`; helper scripts: `/usr/local/bin/add-src`, `update-src`, and `sudo-agent`.
- Sleep policy: `systemd.sleep.settings.Sleep` in `/etc/nixos/configuration.nix`.

## Agent log archive

- Runtime clone: `/src/work/cardoso-neto/agent-logs`.
  - Shared bare/reference copies remain under `/src/bare` and `/src/read`; capture runs from the writable runtime clone.
  - Git-annex is installed in nei's Nix profile: `/home/nei/.nix-profile/bin/git-annex`.
- Capture command: `/home/nei/.local/bin/sync-agent-logs-host`, linked to the runtime clone's `sync-agent-logs.sh`.
  - Archives nei's Codex, Claude, and Grok sessions under `data/hosts/genesis`.
  - Units: `agent-logs-genesis.service` and `agent-logs-genesis.timer` in `/home/nei/.config/systemd/user/`.
  - Inspect schedule/status with `systemctl --user cat agent-logs-genesis.timer` and `systemctl --user list-timers --all`.
  - Inspect results with `journalctl --user -u agent-logs-genesis.service`.
- Genesis and mp600 retain all annex history; laptop and Cron Data 3 receive their own sessions.
  - Both archive servers pull Cron Data 3; its agent account needs no outbound SSH key.
  - Inspect remotes with `git remote -v` and retention with `git annex wanted here` and `git annex required here` in each clone.
  - Genesis's `mp600` SSH alias uses the home LAN; its `cron-data3-agent` alias uses Tailscale.
  - Copy policy and transfer commands are in the archive repository's `README.md` and `sync-agent-logs.sh`.

## Network

- Tailscale: system `tailscaled.service`; identity/state in `/var/lib/tailscale`.
  - Inspect with `tailscale status`, `tailscale ip`, and `tailscale serve status`.
  - Tailnet access policy: [Tailscale admin console](https://login.tailscale.com/admin/acls).
- NetworkManager profiles: inspect with `nmcli connection show` and `nmcli device show`.
  - LAN addressing and DNS settings can live in NetworkManager profiles outside the NixOS configuration.
  - If public DNS fails, inspect the profile's upstream DNS settings; router-provided DNS has caused malformed EDNS replies here.

## Provider configuration

- Claude: `/home/nei/.claude/settings.json`.
  - Native binary: `/home/nei/.local/bin/claude`; versions: `/home/nei/.local/share/claude/versions/`.
  - T3 should use the user-owned native binary directly.
- Grok: `/home/nei/.local/bin/grok`.
  - npm settings: `/home/nei/.npmrc`; prefix `/home/nei/.local`, `allow-scripts=@xai-official/grok`.
  - Provider environment: `npm_config_prefix=/home/nei/.local`, `npm_config_allow_scripts=@xai-official/grok`.
- Codex: `/home/nei/.codex/config.toml`.
- Proxy client credentials: `/home/nei/.config/cliproxyapi/` (`client.key`, `client.json`, `client.env`).
- Since 2026-11-03, explicit proxy clients and T3 Claude/Codex use `https://shushingface.quorum.us` with Nei's `NEI` key.
  Existing shells must reload aliases with `. ~/.config/cliproxyapi/aliases.sh`; no retired tunnel unit is installed.
- Gateway, key ownership, and cutover evidence: [shared CLIProxyAPI access](cliproxyapi.md#retirement-on-2026-11-03).
  - Inspect the saved provider settings for base URLs and models.
  - Keep credential contents out of logs and fleet notes.
