# Personal AI Context Repository

A software engineering-focused context system for AI coding agents, inspired by Daniel Miessler's [Personal AI Infrastructure](https://danielmiessler.com/blog/personal-ai-infrastructure).

## File Structure Explained

### AGENTS.md vs CLAUDE.md

- **AGENTS.md**: Universal entry point that works across multiple AI agents (Auggie, Gemini, Codex, etc.). See [agents.md](https://agents.md) for the standard specification.
- **CLAUDE.md**: Claude Code-specific entry point since Claude Code doesn't natively support the AGENTS.md convention. Points to AGENTS.md to maintain a single source of truth.

This dual-file approach ensures compatibility across different AI platforms while keeping instructions in one place.

### Directory Structure

- **context/**: Core instruction set and coding guidelines
  - **programming/**: Language-specific and general coding standards
    - `coding.md`: General coding principles and testing guidelines
    - `markdown.md`: Markdown formatting conventions
    - `python.md`: Python-specific style and tooling preferences
  - `index.md`: Main index organizing all context sections

## Installation

To use this context repository for your own AI agents:

```bash
cd ~/.claude/
git init
git remote add origin <your-fork-url>
git pull origin main
```

Or start fresh with this as a template:

```bash
git clone <this-repo-url> ~/.claude/
```

## Customization

The context files are designed to be forked and personalized:

1. Fork this repository
2. Modify the files in `context/` to match your preferences
3. Add your own language-specific files in `context/programming/`
4. Keep pulling updates from upstream for improvements while maintaining your customizations

## Philosophy

This setup prioritizes:
- Software engineering best practices
- Language-specific tooling and conventions
- Consistency across AI interactions
- Easy sharing and version control of AI instructions

Unlike more general-purpose AI infrastructures, this focuses specifically on coding tasks, making it lighter and more targeted for software development work.
