# Personal AI Infrastructure

Version-controlled instructions and reusable resources for agent harnesses.
The repository mirrors the managed parts of the home directory.

## Structure

- `.agents/`
  - Canonical harness-neutral instructions, user context, agents, and skills.
- `.claude/`
  - Claude Code settings, hooks, and status lines.
  - Relative links expose the canonical instructions, agents, and skills.
- `.codex/`
  - Codex's global instruction link and machine-specific declarative configuration.
- `.grok/`
  - Shared Grok configuration; instructions, skills, agents, and hooks use Claude compatibility.
- `.pi/agent/`
  - Pi's global instruction link.

Runtime state, credentials, sessions, caches, and machine-local settings are not versioned.

## Transcripts

`~/.claude/projects/` holds every Claude Code session transcript as JSONL.
It is excluded because it is large and contains proprietary work, not because it is disposable.

- Never delete old transcripts.
  - They are complete agent trajectories, including diagnoses, decisions, and dead ends.
  - Age makes them more valuable when unwritten context disappears.
  - `cleanupPeriodDays: 99999` in `.claude/settings.json` is deliberate.
  - `cc-convo-explorer` mines them, so pruning silently degrades the skill.
- Never let a disk-cleanup pass touch `~/.claude/projects/`.
  - Prune regenerable state such as `shell-snapshots/`, `jobs/`, `plugins/cache/`, `file-history/`, and `todos/` instead.
- Keep transcripts backed up off this disk.
  - `~/cardoso-neto/agent-logs/sync-agent-logs.sh` archives Claude and Codex trajectories hourly via cron at `:17`.
  - The Mac copies git-annex content to `mp600-4tb`; both machines sync Git history and annex metadata with the private GitHub repository.
  - Keep every destination private because transcripts contain client source code.

## Principles

- Keep shared material harness-neutral.
- Keep harness directories thin.
- Version declarative configuration, not runtime state.
- Maintain one canonical copy of each instruction or resource.

## Desktop and MacBook configuration

- `~/.agents` points to this repository's `.agents` directory.
- Claude instructions, agents, settings, hooks, and status lines link to the shared files.
- Each personal skill in `~/.claude/skills` links to its canonical `.agents/skills` directory.
  Claude-managed `synced` skills remain local to each machine.
- Codex instructions and `hooks.json` link to the shared files.
  `config.toml` links to `config.desktop.toml` or `config.macbook.toml`.
  Keep general preferences aligned; integrations, project paths, credentials paths, and hook trust keys remain machine-specific.
- Grok's `~/.grok/config.toml` links to the shared `.grok/config.toml`.
  It discovers shared instructions, skills, agents, and hooks through Claude compatibility.
- Claude, Codex, and Grok `PostToolUse` hooks append native shell commands, including subagent commands, to `~/.agents_eternal_history`.
  Codex also exposes `exec_command` and `shell_command` as Bash events.
  Grok maps the Bash matcher to `run_terminal_command`; the logger accepts both input field formats.
  This does not capture commands executed inside arbitrary external MCP servers.
- Runtime data and credentials stay in each machine's home directory.
  Replaced configurations are backed up under `~/.local/state/harness-backups`.
