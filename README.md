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
  - Codex's global instruction link.
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
  - The archive currently has no git-annex remote, so it still needs an off-device copy.
  - Keep every destination private because transcripts contain client source code.

## Principles

- Keep shared material harness-neutral.
- Keep harness directories thin.
- Version declarative configuration, not runtime state.
- Maintain one canonical copy of each instruction or resource.
