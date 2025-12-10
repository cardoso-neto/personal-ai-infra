# Personal AI Context Repository

A software engineering-focused context system for coding agents, (loosely) inspired by Daniel Miessler's [Personal AI Infrastructure](https://danielmiessler.com/blog/personal-ai-infrastructure).

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
