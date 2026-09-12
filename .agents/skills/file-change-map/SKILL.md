---
name: file-change-map
description: Plan file changes as a compact, rearrangeable Markdown bullet map.
---
# File change map

1. Inspect the relevant repository structure to locate affected files.
2. Output Markdown bullets grouped by directory; one file per line: `path (add|modify|delete|move): intended change`.
3. Include only affected files, mark tentative changes, and note ordering dependencies inline. Keep each bullet self-contained for rearranging in an editor.
