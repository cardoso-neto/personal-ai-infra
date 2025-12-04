# markdown

- Use `markdownlint` to lint markdown files.
  - `markdownlint --disable MD013 <somefile.md>`
  - if not installed, install with `npm install -g markdownlint-cli`
  - `markdownlint --disable MD013 --fix <somefile.md>` to auto-fix issues.

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

```
project/
├── src/
│   ├── task.py
│   └── config.py
└── pyproject.toml
```

Prefer bulletpoing lists; they're more easily editable by humans.

- project/
  - src/
    - task.py
    - config.py
  - pyproject.toml
