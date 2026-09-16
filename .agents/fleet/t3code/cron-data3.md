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
- Personal agent configuration: `~/.agents`, linked to its source checkout.
- VM instructions: `~/agents/AGENTS.md`
  - Also embedded in `~/.codex/config.toml`; keep these aligned when editing VM guidance.
- User executables: `~/.local/bin`
- T3 state: `~/t3/`
- T3 logs: `~/t3/userdata/logs/`
- User service units and overrides: `~/.config/systemd/user/`
- Scheduled maintenance: the user's `crontab -l`; scripts in `~/.local/bin/`, logs in `~/.local/state/`.

## Services

`t3code.service` and `docker.service` are systemd user services owned by `t3-cardoso-neto`.
For service commands from an administrator session, set `XDG_RUNTIME_DIR=/run/user/992` and `DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/992/bus` after switching users.

T3 listens on `127.0.0.1:3773`; T3 Connect provides remote access.
Docker is rootless, using `DOCKER_HOST=unix:///run/user/992/docker.sock`.

Use T3's **Update server** action for upgrades.
Put service environment overrides in `t3code.service.d/` rather than editing the generated unit.

Setup decisions and history: [installation journal](cron-data3.journal.md).
