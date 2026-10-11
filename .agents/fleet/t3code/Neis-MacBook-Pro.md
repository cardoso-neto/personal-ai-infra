# Nei's MacBook Pro

## Access

- [app.t3.codes](https://app.t3.codes): account `nei.neto@hotmail.com`, environment `Nei's MacBook Pro` (shown with a typographic apostrophe).
- T3 and agents run as `neicardosoneto`.
  Keep the Mac logged in and awake for remote access.
- LAN SSH from `mp600-4tb`: `ssh neicardosoneto@Neis-MacBook-Pro.local`.
  Use mDNS rather than a saved DHCP address.
- SSH aliases, keys, and transports: `~/.ssh/config`.
  - `ssh cron-data3`: maintenance login over Tailscale, independent of the corporate VPN.
  - `ssh ansible-tower-prod`: production EC2 access through Cron Data 3; see [minion access](cron-data3.md#production-aws-access-through-the-minion).
- Administrator commands require a password; unattended SSH does not provide sudo access.
- Tailscale daemon: `/Library/LaunchDaemons/sh.brew.tailscale.plist`; CLI: `/opt/homebrew/bin/tailscale`.
  Do not also install the graphical client while using this daemon.

## T3

- Desktop app: `/Applications/T3 Code (Alpha).app`.
- CLI: `/opt/homebrew/bin/t3`.
- State: `~/.t3/userdata`; runtime: `~/.t3/runtime`.
- Service definition and environment: `~/Library/LaunchAgents/com.t3tools.t3code.service.plist`.
- Service log: `~/.t3/userdata/logs/boot-service.log`.
- Status: `t3 service status` and `t3 connect status`.

## Updates

- Script: [machine updater](../../../../super-system-stuff/hosts/mbp/bin/autoupdate.sh).
  Inspect it for update channels, power checks, and app restart behavior.
- Scheduler: `~/Library/LaunchAgents/local.nei.machine-autoupdate.plist`.
  Source installer: [autoupdate-install.sh](../../../../super-system-stuff/hosts/mbp/install/autoupdate-install.sh).
- Runner: `~/.local/bin/job-runner`; [source and logging commands](../../../../super-system-stuff/shared/job-runner/README.md).
- Logs: macOS Unified Logging, subsystem `local.nei.jobs`, job `machine-autoupdate`.
- Lock state: `~/Library/Caches/machine-autoupdate`.

## Other locations

- Personal repositories: `~/cardoso-neto/<repo>`; upstream: `~/upstream/<org>/<repo>`.
- Personal instructions and skills: `~/.agents`; follow its symlink to the source repository.
- Harness configuration: `~/.claude`, `~/.codex`, and `~/.grok`.
- Shared Claude/OpenAI access: [CLIProxyAPI commands, tunnel, and configuration](cliproxyapi.md).
- Grok: native install in `~/.grok/bin`; `~/.local/bin/grok` links to `~/.grok/bin/grok`.
  - Avoid the npm package `@xai-official/grok`; its postinstall changes `~/.grok/config.toml` to `installer = "npm"`.
- Muse: launcher, binary, and update state in `~/.local/opt/muse`; `~/.local/bin/muse` links to the launcher.
  - Its installer appends a `PATH` line for its working directory; remove that line from `.zshrc` after reinstalling.

Historical repairs: [installation journal](Neis-MacBook-Pro.journal.md).
