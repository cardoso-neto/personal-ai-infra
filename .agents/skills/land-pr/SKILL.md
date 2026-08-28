---
name: land-pr
description: Use when the user asks to land or merge a PR.
---
# Land PR

- Treat an explicit request to land or merge as authorization.
- Check GitHub.
  - Use `refresh-pr` beforehand if the PR needs routine updates such as conflict or CI fixes.
- Prefer squashing.
  - Unless the commits will make sense as individual units in the eternal commit history.
- Landing does not imply deployment.
