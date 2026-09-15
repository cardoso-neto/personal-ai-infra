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

Direct SSH sessions run as `nei`, which has passwordless `sudo` for maintenance.
Teleport sessions run as the synthesized `cardoso-neto` account.
T3 sessions run as `t3-cardoso-neto`.
Do not use `tsh` inside them.
The account has a `nologin` shell, so maintenance requires an explicit shell.

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
