---
name: markdown
description: Always use this skill when writing or editing markdown files!
---
# markdown

- Write like you're explaining to a competent peer, not selling to a novice (no handholding).
  - State facts directly and cut everything that doesn't add information.
  - Assume the reader is smart enough to infer context and figure things out.
- Use ATX-style headings (i.e., `# Heading 1`, `## Heading 2`, etc.) instead of Setext-style (`Heading 1\n=========`).
- Use `markdownlint` to lint markdown files.
  - `markdownlint --disable MD013 -- <somefile.md>`
  - if not installed, install with `npm install -g markdownlint-cli`
  - `markdownlint --disable MD013 --fix <somefile.md>` to auto-fix issues.
- Nest supplementary details.
  - When a list item has supplementary information that extends the line or interrupts the main point, move it to a nested list item.
  - Main point stays short and scannable.
    - Supporting details, examples, clarifications, conditions, or caveats go here.
    - Lines never grow too long.
- Use only characters present on the keyboard.
  - e.g.: ñ, é, ->, =>, >=, etc. are all fine.
  - Fancy quotes, dashes, etc. are not.

## numbered lists should be contiguous

- Do not attempt to continue numbered lists across titles; examples below.

```md
### title 1

1. thing
2. thing

### title 2
<!-- this does not work; it should start on 1 again -->
3. other thing
4. other thing
```

## represent folder hierarchies with bulletpoints

Avoid using code blocks with tree structures; they're hard to edit and maintain.

```txt
project/
├── src/
│   ├── task.py
│   └── config.py
└── pyproject.toml
```

Prefer bulletpoint lists; they're more easily editable by humans.

- project/
  - src/
    - task.py
    - config.py
  - pyproject.toml
