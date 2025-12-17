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

### Directory Structure

- **context/**: all instructions and guidelines live here
  - `index.md`: Main index
  - **programming/**: all files here should be @ referenced by index.md, so they're auto-loaded by agents
    - `coding.md`
    - `markdown.md`
    - `python.md`

## Installation

`./install.sh`

## Philosophy

- Prevent common AI failure modes
- Software engineering best practices
- Easy sharing and version control of AI instructions

## roadmap

- document how to use write repo-specific instructions
- create an auto-updating thing
  - can't rely on git alone
- what about people who'll install in a project instead of their $HOME?
