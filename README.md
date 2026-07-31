# Personal AI Context Repository

Software engineering context system for coding agents, (loosely) inspired by Daniel Miessler's [Personal AI Infrastructure](https://danielmiessler.com/blog/personal-ai-infrastructure).

## install

`curl -fsSL https://raw.githubusercontent.com/cardoso-neto/personal-ai-infra/master/gitless-install.sh | bash`

## file structure

### AGENTS.md vs CLAUDE.md

- [agents.md](https://agents.md) works across most coding agent implementations (Auggie, Gemini CLI, Codex, etc.).
- CLAUDE.md is Claude Code-specific.
  - Ours just points to AGENTS.md (maintaining a single source of truth).
  - Claude Code doesn't natively support the AGENTS.md yet.

## transcripts

`projects/` holds every Claude Code session transcript as jsonl.
It is gitignored because it is large and full of proprietary work, not because it is disposable.

- Never delete old transcripts.
  - They are agent trajectories: complete records of how problems were actually diagnosed and solved, including the dead ends.
  - Age makes them more valuable, not less; the old ones are the only record of decisions nobody wrote down.
  - `cleanupPeriodDays: 99999` in `settings.json` is deliberate. Do not "fix" it.
  - `/cc-convo-explorer` mines them, so pruning silently degrades that skill.
- Never let a disk-cleanup pass touch `projects/`.
  - Prune `shell-snapshots/`, `jobs/`, `plugins/cache/`, `file-history/`, and `todos/` instead; all regenerate.
  - Those are ~110M combined, which is the entirety of the reclaimable space that matters.
- Keep them backed up off this disk.
  - `./backup-transcripts.sh` mirrors them gzipped, incrementally, deleting nothing.
    - Destination defaults to `~/claude-transcript-backups`; override with `CLAUDE_TRANSCRIPT_BACKUP_DIR`.
    - 1.1G of transcripts compresses to 329M. First run takes ~4 min, later runs ~3s.
  - The default destination is the same physical disk, which protects against `rm -rf` but not against disk loss.
    - Point it at an external drive or sync the result off-machine to get real durability.
  - Whatever the destination, it must be private; transcripts contain source code from client work.

## philosophy

- Prevent common AI failure modes
- Software engineering best practices
- Easily share and version control AI instructions

## roadmap

- document how to use write repo-specific instructions
- create an auto-updating thing
  - can't rely on git alone
- what about people who'll install in a project instead of their $HOME?
- some sort of "approval" system for skills (e.g.: "Anthropic approved this skill.")
