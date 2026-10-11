# Fleet pointers

These guides locate access routes, files, services, maintenance scripts, and logs.
Read those sources for current versions, schedules, configuration, and health.
Keep installation and incident history in journals; dated observations do not establish current state.

- [MacBook](Neis-MacBook-Pro.md): macOS services and local tools.
- [mp600-4tb](mp600-4tb.md): Ubuntu desktop, T3 AppImage, and user services.
- [Genesis](genesis.md): NixOS configuration and maintenance.
- [Cron Data 3](cron-data3.md): Ubuntu VM, T3 service account, repositories, and production access.
- [CLIProxyAPI](cliproxyapi.md): shared inference gateway, credentials, tunnels, recovery helper, and usage dashboard.

## Check live state

- SSH aliases, destinations, and keys: inspect the client's `~/.ssh/config` or `ssh -G <alias>`.
- T3 version: inspect the running executable and runtime selection, not only a newly installed CLI.
- Linux services: `systemctl --user cat <unit>`, `systemctl --user status <unit>`, and `journalctl --user -u <unit>`.
  Cron Data 3 requires the service-account wrapper in its guide.
- Linux schedules: `crontab -l` and `systemctl --user list-timers --all`.
- macOS jobs: inspect `~/Library/LaunchAgents/` and `launchctl print gui/$(id -u)/<label>`.
- Hardware and storage: inspect the host or cloud inventory rather than recording a snapshot here.

Follow stable T3 releases unless the task requests another channel.
Review the updater before running it; service updates can interrupt agents and terminals.
