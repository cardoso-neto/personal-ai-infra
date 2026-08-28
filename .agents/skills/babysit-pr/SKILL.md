---
name: babysit-pr
description: Use when the user asks to monitor, watch, or babysit a PR.
---

# Babysit PR

- Use `refresh-pr`, then wait for new reviews or checks and repeat.
- Prefer harness monitoring when available; otherwise poll the PR.
- A refresh that pushes changes starts another cycle.
- Continue until the PR is ready to land, merged, closed, or requires a user decision.
