---
name: refresh-pr
description: Rebase, address review feedback, fix CI, resolve conflicts, and make it ready-to-merge in general.
---

# Refresh PR

- Review bots are useful, but they often hallucinate.
  - Doublecheck their findings before changing code.
- Fix real findings and CI failures.
  - Distinguish repository failures from infrastructure flakes.
- Explain why when dismissing false positives.
- Rebase on latest master (or target branch) if it advanced.
- Use `cleanup-pr` if you dirtied up the commit history.
