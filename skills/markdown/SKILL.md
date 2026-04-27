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
- Use only characters present on the US international keyboard.
  - e.g.: ñ, é, ->, =>, >=, etc. are all fine.
  - Fancy quotes, dashes, etc. are not.
- When writing text, use semantic linebreaks, after full stops.
  - Avoid hard-wrapping paragraphs at a fixed column-width.
  - It's painful to maintain; deleting one word forces every following line to shift.

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

## represent tables with bulletpoints

Whenever the one of the columns of a table is a key/indexing field, this works well.

| id | mission | market cap | 
|---|---|
| `apple` | to create technology that empowers people and enriches their lives. | $3.93T
| `meta` | to build the future of human connection and the technology that makes it possible. | $1.72T

They're easier to edit and less horizontally long.

- `apple`
  - to create technology that empowers people and enriches their lives.
  - $3.93T
- `meta`
  - to build the future of human connection and the technology that makes it possible.
  - $1.72T

- Always prefer to omit the column names as it'd lead to a lot of repetition.
- The above is a naive example of direct conversion.
- Design-wise, it could look better if:
  - columns with consistently shorter values came first.
  - columns with fixed short length to be inlined along with the "id" or some other short field
    - e.g.: "`meta` ($1.72T)"
