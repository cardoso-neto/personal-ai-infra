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
