---
name: file-pr
description: Use when the user asks to file, open, or create a PR.
---
# File PR

- Check whether the branch already has a PR.
  - If not, based on its full diff, include work related to the original goal.
- Follow the repository's PR template and infer title conventions from recent merged PRs.
- Write a concise, human-readable title about the result or why it matters, not an inventory of changed code.
  - Bad: `Update retry logic and tests`
  - Good: `Retry Vermont RSS outages patiently`
- Open the description with the problem in terms of the user's request, then briefly explain the solution.
  - No implementation inventory.
  - Keep the description lean.
  - Include material constraints, risks, or omissions; omit details evident from the diff.
  - State the verification actually performed, preferably with a command reviewers can rerun.
  - Link the originating issue or conversation when it provides useful context.
- Do not create a draft unless the user asks for one.
- Add appropriate labels.
- Set currently logged in user as the assignee.
- Reference relevant issues.
