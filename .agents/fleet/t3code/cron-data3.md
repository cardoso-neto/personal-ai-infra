# T3 Code on `cron-data3`

Last verified: 2026-09-04.

## Model

This persistent Ubuntu VM runs one private T3 Code instance for `cardoso-neto`. T3 Connect exposes it through `app.t3.codes`; no inbound application port is open.

Do not share the instance. T3 Code does not isolate users. Give each colleague a separate Linux user, service, home, workspace, port, and T3 Connect link.

## Access

Use T3 Connect for normal work. Use Teleport only for operator maintenance from a trusted workstation:

```sh
tsh ssh cardoso-neto@cron-data3
```

Agents inside T3 must not use `tsh`.

## Layout

| Item | Value |
| --- | --- |
| Linux user | `t3-cardoso-neto` (UID `992`) |
| Home | `/var/lib/t3code/cardoso-neto` |
| T3 state | `/var/lib/t3code/cardoso-neto/t3` |
| Workspace | `/srv/t3code/cardoso-neto` |
| Repository | `/srv/t3code/cardoso-neto/src/QuorumUS/actacollecta` |
| T3 runtime | `/var/lib/t3code/cardoso-neto/t3/runtime/versions/0.0.38` |
| Service | `t3code.service` (systemd user unit) |
| Service log | `/var/lib/t3code/cardoso-neto/t3/userdata/logs/boot-service.log` |
| Listener | `127.0.0.1:3773` |
| Codex home | `~/.codex` |
| VM instructions | `~/agents/AGENTS.md` |

`~/.codex/AGENTS.md` links to `~/agents/AGENTS.md`. Start a new Codex session after an instruction change.

## Service

```sh
sudo -u t3-cardoso-neto env \
  HOME=/var/lib/t3code/cardoso-neto \
  XDG_RUNTIME_DIR=/run/user/992 \
  DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/992/bus \
  systemctl --user status t3code.service

sudo tail -n 200 /var/lib/t3code/cardoso-neto/t3/userdata/logs/boot-service.log
```

T3 manages the unit at `~/.config/systemd/user/t3code.service`, the stable launcher, versioned runtimes, update state, and database rollback snapshots.
The `t3code.service.d/tools.conf` drop-in sets only the user-tool `PATH` and rootless `DOCKER_HOST` required by this VM.
Linger is enabled, so the service starts at boot without an interactive login.

## Tools and authentication

Installed tools include Git, GitHub CLI, Codex, `uv`, Python 3.14, `shub`, Git Annex, rclone, AWS CLI, Docker, and Compose. User tools are in `~/.local/bin`.

GitHub CLI and Codex are authenticated for `t3-cardoso-neto`. Git rewrites GitHub SSH clone URLs to HTTPS for the T3 repository picker. Do not print or copy credentials. Do not inspect `~/t3/userdata/secrets/` during routine maintenance.

## Rootless Docker

Do not add the T3 user to the host `docker` group. A separate rootless daemon uses `/run/user/992/docker.sock`; T3 inherits it through `DOCKER_HOST`.

- User unit: `~/.config/systemd/user/docker.service`
- Storage: `~/.local/share/docker`
- Subordinate UID/GID range: `362144-427679`
- AppArmor profile: `/etc/apparmor.d/var.lib.t3code.cardoso-neto..local.bin.rootlesskit`
- Linger: enabled

```sh
sudo -u t3-cardoso-neto env \
  HOME=/var/lib/t3code/cardoso-neto \
  XDG_RUNTIME_DIR=/run/user/992 \
  DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/992/bus \
  systemctl --user status docker.service
```

## Repository

Dependencies and hooks are installed:

```sh
cd /srv/t3code/cardoso-neto/src/QuorumUS/actacollecta
uv sync --all-packages
uv run pre-commit install --hook-type pre-push --hook-type pre-commit
uv run pre-commit run --all-files
```

Git Annex is initialized as `cardoso-neto-cron-data3`. Web remotes supplied 82 of 84 objects. These objects still require the `q-gdrive` rclone remote:

```text
spiders/tests/regulations/minnesota/fixtures/2025/vol49_num29_2025-01-13.pdf
spiders/tests/regulations/minnesota/fixtures/2025/vol50_num11_2025-09-15.pdf
```

Follow `docs/git-annex-setup.md` for Google Drive. Configure AWS only when a task needs it; follow `docs/cluster-access-setup.md`.

## Maintenance rules

- Prefer the client's **Update server** action. The launcher installs exact versions, trials them, and restores the database and previous version after a failed update.
- For local repair, run `t3 service update --base-dir /var/lib/t3code/cardoso-neto/t3` as `t3-cardoso-neto`, not as root.
- Do not edit the generated `t3code.service`. Put required local environment values in `t3code.service.d/tools.conf`.
- Upgrade user tools as `t3-cardoso-neto`, not as root.
- Verify the T3 service, T3 Connect, Docker, GitHub, Codex, and repository status after maintenance.
