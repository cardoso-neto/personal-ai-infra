# Cron Data 3

Persistent Ubuntu VM with a private T3 Code instance for `cardoso-neto`, accessed through T3 Connect at `app.t3.codes`.

## Access

For maintenance from the MacBook or desktop:

```sh
ssh cron-data3
```

The client alias connects as the local `nei` administrator with a dedicated key and sends TCP port 22 through `tailscale nc`.
It therefore does not depend on MagicDNS, the corporate VPN's DNS, or its routes.

Teleport remains available as a fallback:

```sh
tsh ssh cardoso-neto@cron-data3
sudo -Hu t3-cardoso-neto /bin/bash
```

The `cron-data3` SSH alias runs as `nei`, which has passwordless `sudo` for maintenance.
Teleport sessions run as the synthesized `cardoso-neto` account.
T3 sessions run as `t3-cardoso-neto`.
Do not use `tsh` inside them.

### Production AWS access through the minion

From the MacBook or desktop, run `ssh ansible-tower-prod`.
The alias uses `ProxyJump cron-data3` over Tailnet, then connects to `AnsibleTowerMinionProd` at `10.1.3.139` as `nei`.
It needs neither the corporate VPN nor a Teleport session.

The minion account has a locked password and no sudo membership.
It accepts each client's `~/.ssh/id_ed25519_cron_data3` public key only from cron-data3's private IP, `10.1.3.84`; private keys stay on the clients.
The minion's ED25519 host key is pinned under `HostKeyAlias ansible-tower-prod` (fingerprint `SHA256:KtU3oRn5X4nFqjEgkxDr2TsQgX3M6V+bvrRhSi+k+GQ`).

Run `aws sts get-caller-identity` on the minion to verify role `AnsibleTowerMinion` in account `596070161069`; use `--region us-east-1` for EC2 commands.
Instance: `i-0a31dbb209e9b1ce8`.
Fallback: `tsh ssh <github-user>@AnsibleTowerMinionProd` over the VPN.

### VS Code from the MacBook or desktop

T3's Open in VS Code action uses `cron-data3-agent.tailb524d8.ts.net`.
Both clients' `~/.ssh/config` map that hostname and `cron-data3-agent` to `t3-cardoso-neto` at `100.114.70.83`, using each client's own `~/.ssh/id_ed25519_cron_data3`.
The ProxyCommand is `/opt/homebrew/bin/tailscale nc %h %p` on the MacBook and `/usr/bin/tailscale nc %h %p` on the desktop (`mp600-4tb`).
This bypasses MagicDNS and preserves `ssh cron-data3` as the `nei` maintenance login.
Other clients need the equivalent SSH configuration.

```sh
ssh cron-data3-agent.tailb524d8.ts.net
```

The T3 account uses `/bin/bash` and accepts both clients' dedicated SSH public keys in `~/.ssh/authorized_keys`.
Its password remains locked; SSH password and keyboard-interactive authentication are disabled on the server.
VS Code runs as the repository owner and shares files, Git state, tools, and credentials with T3 agents.
Coordinate edits and Git operations with running agents.

## Locations

Paths beginning with `~` refer to the T3 user's home.

- Home: `/var/lib/t3code/cardoso-neto`
- Direct SSH administrator home: `/home/nei`
- Repositories: `/srv/t3code/cardoso-neto/src/<org>/<repo>`
  - The scheduled `~/.local/bin/fetch-repos` fetches and prunes remote refs; it does not update checkouts.
- Shared project data: `~/data/<project>/`
  - Use this location for reusable generated data that must be available to every project worktree.
  - Keep the data outside repositories and worktree hubs.
  - Store Slack channel dumps in `~/data/<project>/slack-dumps/<channel>/`.
    For example: `~/data/actacollecta/slack-dumps/agent-as-a-service/`.
- Personal agent configuration: `~/.agents`, linked to its source checkout.
- VM instructions: `~/agents/AGENTS.md`
  - Also embedded in `~/.codex/config.toml`; keep these aligned when editing VM guidance.
- User executables: `~/.local/bin`
- T3 state: `~/t3/`
- T3 logs: `~/t3/userdata/logs/`
- User service units and overrides: `~/.config/systemd/user/`
- Scheduled maintenance: the user's `crontab -l`; scripts in `~/.local/bin/`, logs in `~/.local/state/`.

## Trajectory backups

The `t3-cardoso-neto` account archives Codex, Claude, and Grok sessions hourly at minute 7.
The repository is `/srv/t3code/cardoso-neto/src/cardoso-neto/agent-logs`, with this host's captures under `data/hosts/cron-data3`.
The cron log is `~/.local/state/agent-logs/agent-logs-sync.log`.

The desktop's `agent-logs-mp600.timer` runs at minute 27 and exchanges git-annex payloads with this VM in both directions.
Its `cron-data3` Git remote connects as the T3 account through `cron-data3-agent.tailb524d8.ts.net`.
The desktop also exchanges payloads with the MacBook.
GitHub receives Git history and annex metadata only (`remote.origin.annex-ignore=true`).

Captures preserve files removed from live agent directories and use locked annex links to avoid duplicate working copies.
Grok's transient `*.lock` files are excluded.
The VM needs no outbound SSH access to the personal machines; the existing Tailnet restriction remains in place.

The first historical seed runs on the desktop as `agent-logs-seed-cron-data3.service`.
It resumes interrupted transfers, checks the packed archive's SHA-256, and runs a full annex integrity check on the VM.
During seeding, the desktop temporarily sets `remote.cron-data3.annex-ignore=true` so routine backups do not compete with the initial transfer.
The seed service restores it to `false` after verification and starts the normal sync service.
Progress is in the desktop's `~/.local/state/agent-logs/cron-data3-seed.log`; successful completion creates `cron-data3-seed-complete` in the same directory.
The service uses the Mac's existing VPN route for the initial transfer when available and falls back to Tailnet.
Normal hourly replication uses Tailnet directly with SSH compression.

## Google Drive

Configured and verified on 2026-09-24 for `nei.cardoso@quorum.us` (Nei Cardoso, Quorum).

- Client: `rclone`, remote `employer-drive:`.
- Linux user: `t3-cardoso-neto`.
- Scope: full Google Drive access (`drive`), subject to the account's file permissions.
- Root: the account's My Drive; no specific Shared Drive is configured.
- Credentials: `/var/lib/t3code/cardoso-neto/.config/rclone/rclone.conf`, mode `0600`.
  - Contains the OAuth access and refresh tokens; keep its contents out of Git and chat.
  - Agents and commands running as this Linux user share the connection independently of ChatGPT authentication.
  - Credentials persist across sessions and VM restarts; rclone refreshes access automatically while the Google grant remains valid.

Verify access without printing file names:

```sh
rclone lsf employer-drive: --max-depth 1 --dirs-only >/dev/null
```

Setup verification also queried Google Drive's account metadata to confirm the email above.
File listing succeeded; no write test was performed.

If Google revokes the grant, run `rclone config reconnect employer-drive:` on the VM and answer `n` to automatic browser configuration.
Run the displayed `rclone authorize` command on the Mac, sign in with the work account, and paste the complete result into the VM's `config_token>` prompt.
Paste only the token between the output markers, without terminal escape characters; answer `n` to Shared Drive to retain the current root.

## Storage

Instance `i-0efffc16d12632a34` in `us-east-1` uses a 512 GiB gp3 root volume, `vol-0f24b1c05971a68f8`, with ext4 on `/dev/nvme0n1p1`.
The videos directory, `/webapps/quorum-site/quorum_data/videos`, is on the root filesystem (`quorum_user:webapps`, `0755`); its former secondary EBS volume was deleted on 2026-09-16.

## Services

CLIProxyAPI runs as a separate user service for shared Claude/OpenAI routing.
See [CLIProxyAPI operations and subscription logins](cliproxyapi.md).
The persistent five-minute [subscription recovery check](cliproxyapi.md#automatic-subscription-recovery) detects early quota resets and clears verified stale cooldowns; its source and systemd units are in [scripts/cliproxyapi-recovery](../../../scripts/cliproxyapi-recovery/).
CPA Usage Keeper, its usage dashboard, runs beside it as `cpa-usage-keeper.service`; see [Usage keeper](cliproxyapi.md#usage-keeper).

`t3code.service` and `docker.service` are systemd user services owned by `t3-cardoso-neto`.
For service commands from an administrator session, set `XDG_RUNTIME_DIR=/run/user/992` and `DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/992/bus` after switching users.

T3 listens on `127.0.0.1:3773`; T3 Connect provides remote access.
Docker is rootless, using `DOCKER_HOST=unix:///run/user/992/docker.sock`.

Use T3's **Update server** action for upgrades.
Put service environment overrides in `t3code.service.d/` rather than editing the generated unit.

Setup decisions and history: [installation journal](cron-data3.journal.md).

## Tailscale

Tailscale 1.102.4 is installed from its official Ubuntu repository, and `tailscaled` is enabled and running.
The VM is enrolled in the tailnet; regular OpenSSH is used through Tailscale rather than Tailscale SSH.
MacBook-to-VM and desktop-to-VM access are verified.

As of 2026-09-28, the device uses `tag:cron-data3`, administered by `nei.cardoso.neto@gmail.com`.
Tailnet grants block Cron Data 3 from initiating TCP port 22 connections to Nei's personal devices while retaining its other TCP, UDP, and ICMP access to them.
Nei's personal devices retain full access to Cron Data 3 and each other.
Cron Data 3 and Genesis have unrestricted access to each other, and Cron Data 3 has no grant to Martin's personal devices.
The grants identify servers by tags and personal devices by user identity; embedded tests also cover the current IPv4 and IPv6 addresses.
See [Genesis's tailnet policy notes](genesis.md#tailscale) for the shared policy and verification.

The earlier `quorum-agent` account remains unprivileged, has no sudo grant, and is not used for the direct SSH path.
