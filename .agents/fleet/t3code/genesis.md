# Genesis

Neurohive's first server, running NixOS as `nei` with home `/home/nei`.
Hostname: `genesis`; full hostname: `genesis.neurohive.dev`.
Verified on 2026-09-28.

## Access

From the MacBook through Tailscale:

```sh
ssh genesis
```

- The MacBook's `~/.ssh/config` maps `genesis`, `genesis.neurohive.dev`, and `genesis.tailb524d8.ts.net` to `nei@100.94.104.65` with `~/.ssh/id_ed25519` and `IdentitiesOnly yes`.
  `ProxyCommand /opt/homebrew/bin/tailscale nc %h %p` uses Tailscale directly without depending on system DNS or routes.
  `HostKeyAlias 192.168.15.73` reuses the SSH host key already pinned during LAN setup.
- LAN fallback: `ssh genesis-lan` or `ssh nei@192.168.15.73`.
- Current LAN address: `192.168.15.73/24`, interface `enp39s0`.
  A DHCP reservation or static address has not been verified.
- SSH key login from the MacBook is verified using `~/.ssh/id_ed25519`.
  Its public key is installed in `/home/nei/.ssh/authorized_keys` on Genesis, outside the declarative NixOS configuration.
- SSH ED25519 host-key fingerprint: `SHA256:TvCspPnk6xihEZbCn7/jDDSlm0v06lWC26/m9vTpfDs`.
- `nei` and `martin` belong to `wheel`; sudo requires a password.
- DNS for `genesis.neurohive.dev` has not been configured as part of this setup.
  The MacBook's SSH alias for this name uses the Tailscale IP directly and does not require DNS.
  Other clients can use the Tailscale IP or MagicDNS name below.

## T3 Code

Installed on 2026-09-28 for `nei` using T3's official standalone installer, stable release `0.0.42`.
Running `0.0.45` as of 2026-10-03.
This distribution includes its runtime and does not require a separate Node/npm installation.

- Command: `/home/nei/.local/bin/t3`.
- Runtime: `/home/nei/.t3/runtime/versions/<version>/t3`.
- State: `/home/nei/.t3/userdata`.
- Settings: `/home/nei/.t3/userdata/settings.json`.
- Logs: `/home/nei/.t3/userdata/logs/boot-service.log`.
- Service: user unit `/home/nei/.config/systemd/user/t3code.service`, enabled and running as `nei`.
- Listener: `127.0.0.1:3773`.
- Environment label: `genesis`.
- Environment ID: `8625de6b-c4e8-4fd8-867a-bd54a2cb0810`.
- Private HTTPS endpoint: `https://genesis.tailb524d8.ts.net`, served by Tailscale Serve to `http://127.0.0.1:3773`.
  The background Serve mapping persists across restarts; no public Funnel route is enabled.
- T3 Connect account: `nei.neto@hotmail.com`, linked in `--publish-only` mode for notifications and Live Activities.
  Verified `authenticated=true`, `linked=true`, and `publishAgentActivity=true` after restarting the service.
  This does not provision a managed tunnel or consume one of the account's three managed-tunnel slots.
- Relay client: cloudflared `2026.5.2` remains installed from initial setup but is not running or used for connectivity.

On 2026-09-28, switched the pending managed link to `t3 connect link --publish-only --headless`, reusing the existing account authorization, then restarted T3.
The service confirmed link reconciliation and enabled activity publishing.
Configured HTTPS with `sudo tailscale serve --https=443 --bg http://127.0.0.1:3773`; changing Serve configuration requires sudo for `nei`.
Initial TLS requests waited for certificate issuance; HTTPS with certificate validation subsequently passed from the MacBook and returned the expected environment ID with `agentActivityPublishing=true`.

To pair another client, connect it to the tailnet and run this on Genesis:

```sh
t3 pair --tailscale --label my-device
```

Paste the resulting one-time URL into the client's Add environment flow.
On mobile, use Settings > Environments and keep Tailscale connected for interactive access.
Sign in to the same T3 Connect account and enable Device Notifications in Settings > Notifications for push alerts.
To keep Serve unchanged and limit the link's lifetime, use `t3 auth pairing create --ttl 15m --label <device> --base-url https://genesis.tailb524d8.ts.net` instead.
Pairing tokens are not stored in fleet docs.

Verified clients:

- MacBook desktop app, paired 2026-09-28.
- Pixel 10 Pro (`pixel-10-pro`), paired 2026-10-03.
  - Replaces the 2026-09-28 Android pairing, whose session was revoked.
  - The phone must be signed in to Tailscale as `nei.cardoso.neto@gmail.com`; otherwise pairing fails with a transport error.
- Push notifications reached the Pixel on 2026-10-03.
  - Genesis logged `push_notification` publishes; the phone showed "Done" alerts while T3 was in the background.
  - Push goes through T3 Connect, not the tailnet, so it works without Tailscale on the phone.
  - Opening the thread by tapping an alert was not verified.

Caveats:

- Paired sessions expire 30 days after pairing and do not renew.
  - Re-pair each client before expiry; `t3 auth session list` shows dates.
  - Upstream: [pingdotgg/t3code#13055](https://github.com/pingdotgg/t3code/issues/13055).
- The mobile app's T3 Connect list also shows `genesis`, because of the publish-only link.
  - That entry cannot connect (`endpoint_provider_not_managed`).
  - Keep it switched off: the app stores one entry per environment ID, and enabling it replaces the working direct entry.
  - Do not deregister it; that stops push notifications.
  - Upstream: [pingdotgg/t3code#6568](https://github.com/pingdotgg/t3code/issues/6568).

NixOS enables `programs.nix-ld` for the standalone Linux executable and `environment.localBinInPath` for the CLI.
`users.users.nei.linger = true` keeps the user service running after logout and starts it at boot.
The provider settings use `/run/current-system/sw/bin/claude` and `/run/current-system/sw/bin/codex`, with the existing user home and proxy credentials.
Both provider checks reported `ready` after service startup.

Use `t3 service status` and `t3 connect status` to inspect the installation.
Updates should follow latest stable releases, including new major versions; exclude beta, alpha, nightly, and preview builds.
Automatic update jobs are deferred.

Martin's Linux account is provisioned; his separate T3 installation is pending.
It can also use the label `genesis` in his T3 account, with its own service, credentials, state, and listening port.
The tailnet policy reserves TCP `8443` for his future T3 HTTPS endpoint; nothing is serving it yet.

## Martin's account

Created declaratively in `/etc/nixos/configuration.nix` on 2026-09-28 and applied with `nixos-rebuild switch`.

- Login: `martin`, UID `1001`, primary group `users`.
- Home: `/home/martin`, mode `0700`; `.ssh` also has mode `0700`.
- Shell: Bash; member of `wheel`, with password-authenticated sudo matching Nei's permissions.
- `users.users.martin.linger = true` starts his user service manager at boot and keeps it running after logout.
- A random temporary password was set interactively and marked for mandatory change at first login.
  SSH authentication and the forced-change prompt were verified; the password is not stored in these docs or the Nix configuration.
- SSH: `ssh martin@genesis.tailb524d8.ts.net` over Tailscale, or `ssh martin@192.168.15.73` over the LAN.
- His account can run the system Claude, Codex, and Git binaries.
  User homes and provider configuration remain separate; Martin's provider credentials, SSH public key, and T3 service are not configured yet.
  Both users have administrative access through sudo.

The configuration before this change is backed up at `/etc/nixos/configuration.nix.before-martin-20260928`.
Nei's T3 service remained active after the rebuild.
Added `extraGroups = [ "wheel" ]` on 2026-09-28 at Nei's request and rebuilt successfully.
Verified that `sudo -l -U martin` and `sudo -l -U nei` grant identical `(ALL : ALL) SETENV: ALL` access.
The preceding configuration is backed up at `/etc/nixos/configuration.nix.before-martin-sudo-20260928`.

## DNS

Public DNS uses Cloudflare `1.1.1.1` and `1.0.0.1` through NetworkManager.
Tailscale DNS remains enabled for private names and forwards public queries to those upstreams.

The persistent NetworkManager profile is `Wired connection 1`, UUID `bca68246-65ac-3801-8639-5a17ece00719`, on `enp39s0`.
Its IPv4 and IPv6 `ignore-auto-dns` settings are both `yes`; IPv4 `dns` contains the Cloudflare addresses.
Address assignment still uses DHCP/IPv6 autoconfiguration.
These settings are saved in the NetworkManager profile, outside `/etc/nixos/configuration.nix`.

On 2026-09-28, direct packet inspection found malformed EDNS replies from the router at `192.168.15.1` and its advertised IPv6 resolvers.
Replies placed the OPT additional record before the address answer, contrary to their section counts; glibc rejected them.
Tailscale forwarded the malformed replies, while direct Cloudflare replies were correctly ordered.
Queries without EDNS also succeeded against the router.

Changing upstream DNS fixed the failures.
`nmcli device reapply` retained an old DHCPv6 DNS address; reactivating the same connection cleared it.
Repeated public/private lookups, HTTPS downloads, and private proxy reachability were verified afterward.

## Tailscale

- Tailnet: `nei.cardoso.neto@gmail.com` (`tailb524d8.ts.net`).
- MagicDNS name: `genesis.tailb524d8.ts.net`.
- IPv4: `100.94.104.65`.
- IPv6: `fd7a:115c:a1e0::2632:6842`.
- Device ID: `6734720334439123`; stable node ID: `nJpJzcgAbu11CNTRL`.
- Device identity: `tag:genesis`, administered by `nei.cardoso.neto@gmail.com`.
- Package: Tailscale `1.98.10`, managed by NixOS.
- Service: system `tailscaled.service`, enabled at boot and active without a user login.
- Persistent identity and state: `/var/lib/tailscale`, root-owned with mode `0700`.
- Device-key expiry is disabled for unattended operation.
- Access uses regular OpenSSH with the existing SSH key, over Tailscale.
  Tailscale SSH, exit-node service, and subnet routing were not enabled.

Enrollment used a single-use, non-ephemeral, preauthorized key on 2026-09-28.
The key was consumed, and temporary copies were removed from both provisioning machines.
No enrollment secret is stored in the NixOS configuration or these docs.

On 2026-09-28, replaced the broad tailnet grants with directional access rules before inviting Martin.
All devices remain in Nei's existing personal tailnet; no account switching is required.

- Members can connect to their own untagged devices through `autogroup:self`.
- Nei's personal devices can reach Genesis and Cron Data 3 on all ports and protocols.
- Genesis and Cron Data 3 can reach each other on all ports and protocols.
- Genesis cannot initiate Tailscale connections to personal devices.
- Martin (`martinduartemore@gmail.com`) can reach Genesis on TCP `22` and `8443`, with no access to Nei's personal devices, Cron Data 3, or Nei's T3 endpoint on TCP `443`.
- Nei's personal devices have no grant to Martin's personal devices.
- Cron Data 3 retains access to Nei's personal devices except TCP `22`; it has no grant to Martin's devices.
- LAN access and host firewall settings remain unchanged by request.

The API sent Martin a `member` invitation on 2026-09-28 at 15:49:33 UTC.
Acceptance and live checks from Martin's devices remain pending.
His [Linux account](#martins-account) is provisioned separately; T3 credentials and service setup remain pending.

All 16 embedded policy tests passed before application, including IPv4 and IPv6 cases.
Live SSH probes from Genesis to the MacBook and desktop succeeded before application and timed out afterward over both address families.
MacBook access to Genesis HTTPS and Cron Data 3 SSH, Genesis access to Cron Data 3 SSH and proxy HTTPS, and the running T3 service were verified afterward.
Policy backups, the candidate, and the applied policy are on the desktop under `~/.local/state/tailscale-policy/20260928-martin/`.
API credentials and the invitation link remain outside the repository.

SSH through Tailscale and the LAN fallback were verified after restarting `tailscaled`.
The service retained its identity and reported `Running` with no health errors.

## System

- NixOS: `26.05.10620.f5c082a40f75` (Yarara), `x86_64`.
- CPU: AMD Ryzen 9 5900X, 12 cores / 24 threads.
- Memory: approximately 32 GB installed; Linux reports 31 GiB usable.
- Storage: PNY CS3140 1 TB NVMe SSD (`/dev/nvme0n1`).
  - Root: approximately 921.7 GiB, ext4, `/dev/nvme0n1p2`.
  - EFI boot: 1 GiB, vfat, `/dev/nvme0n1p1`.
  - Swap: approximately 8.8 GiB, `/dev/nvme0n1p3`.
- Network management: NetworkManager.
- Desktop: GNOME with GDM.
- Time zone: `America/Sao_Paulo`.

## Power management

Suspend, hibernation, hybrid sleep, and suspend-then-hibernate are disabled through `systemd.sleep.settings.Sleep` in `/etc/nixos/configuration.nix`.
This keeps the server available when the desktop is idle.
Applied on 2026-09-28 after an unattended suspend from 02:41 to 10:49 local time.
Systemd's `CanSuspend` and `CanHibernate` checks both returned `no` after activation.

## Claude Code and Codex

Installed as NixOS system packages on 2026-09-28:

- Claude Code `2.1.283`: `claude`.
- Codex CLI `0.146.0`: `codex`.
- Git and ripgrep are installed alongside them.

Both run as `nei` and default to [CLIProxyAPI on Cron Data 3](cliproxyapi.md) over private Tailscale HTTPS.
No local SSH tunnel is required on Genesis.

- Claude settings: `/home/nei/.claude/settings.json`.
  - Base URL: `https://cron-data3-agent.tailb524d8.ts.net`.
  - Default model: `claude-opus-5-5[1m]`.
  - `apiKeyHelper` reads the private client key; inherited Anthropic API/auth and Claude OAuth token variables are cleared by the settings.
- Codex settings: `/home/nei/.codex/config.toml`.
  - Provider: `cliproxyapi`, base URL `https://cron-data3-agent.tailb524d8.ts.net/v1`.
  - Default model: `gpt-6-astra`, medium reasoning effort.
  - Responses over HTTP/SSE; command-backed authentication reads the private client key.
- Gateway credentials: `/home/nei/.config/cliproxyapi/client.key`, `client.json`, and `client.env`.
  - Dedicated Genesis inference key; directory mode `0700`, files `0600`.
  - Provider credentials and management credentials stay on Cron Data 3.

Claude uses a manifest override in `/etc/nixos/configuration.nix`, pinned to official release `2.1.283` and its published Linux x64 SHA-256.
The channel's original `2.1.223` package was too old for Opus 5.5, which requires at least `2.1.280`.
The override retains NixOS's binary patching and runtime wrapper.
Update its version and checksum together when upgrading Claude; Codex follows the NixOS package set.
Package updates require a NixOS rebuild.
Use the NixOS packages rather than the CLIs' self-updaters.
Both CLIs completed live response checks through the proxy using their saved configuration.

During installation, the [router DNS issue](#dns) required downloading the Claude archive using its independently resolved address with TLS verification.
The archive passed the official SHA-256 check before it was added to the Nix store and rebuilt.
The DNS issue was subsequently diagnosed and fixed.

## Configuration

The authoritative configuration is on the server:

- `/etc/nixos/configuration.nix`
- `/etc/nixos/hardware-configuration.nix`

Relevant settings:

```nix
networking.hostName = "genesis";
networking.domain = "neurohive.dev";
services.openssh.enable = true;
services.tailscale.enable = true;
services.tailscale.openFirewall = true;
```

The NixOS firewall remains enabled.
OpenSSH's default `openFirewall = true` opens its port.
`system.stateVersion` is `26.05`; keep it unchanged during routine upgrades.

After editing the configuration, apply it on Genesis:

```sh
sudo nixos-rebuild switch
```

## Setup history

On 2026-09-28, enabled SSH access with the MacBook's public key and renamed the fresh installation from `nixos` to `genesis`.
The NixOS rebuild succeeded.
The live hostname still reported `nixos` after activation, so `sudo hostnamectl --transient set-hostname genesis` applied the name without a reboot.
A new SSH session verified `hostname -f` returned `genesis.neurohive.dev` and `sshd` was active.

The pre-rename configuration is backed up on the server at `/etc/nixos/configuration.nix.before-genesis-20260928-022009`.

The fleet naming theme is cosmic origins; possible future names include `nebula`, `pulsar`, and `quasar`.
