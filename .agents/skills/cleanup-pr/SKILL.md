---
name: cleanup-pr
description: Use when the user asks to clean up, rewrite, squash, reorder, split/stack a PR or its commit history.
---
# Cleanup PR

- Inspect the complete diff and commit graph before changing history.
  - If it contains unrelated work, propose options to the user on how to address it.
- Prefer rewriting branch history over splitting it into a stack, unless instructed.
- Make each commit a coherent unit.
  - Squash fixup noise and other adhoc effort.
  - Order prerequisites before dependents.
- Do not split by size alone.
  - Create a stack or separate commits only when the parts have clear conceptual boundaries.
- Tell the user about any deliberate changes you made.
- Create a recoverable backup before rewriting and use force-with-lease when updating a published branch.
- Use `file-pr` to update GitHub metadata if needed.
