---
name: run-local-forks
description: Run locally modified forks of open source projects using worktree hubs.
---
# Run Local Forks

## structure

- The worktree hub is usually named `<project>-worktrees/`.
- `bare/` inside the hub is the central bare repo.
- Checked-out worktrees are sibling directories under the hub.
- Long-lived branches may use short role names:
  - `prod` -> production branch, i.e.: code runs from this one.
    - My fork's default branch.
  - `dev` -> development branch, staging area to try things out before merging to `prod`.
  - `upstream` -> upstream/default branch, often `master` or `main`.
- Topic branches map to directory names by replacing `/` with `-`:
  - `feature/something` -> `feature-something`

## example

- `~/upstream/openclaw-worktrees/` is the worktree hub.
  - `bare/` is the central bare repo.
  - `prod/` is the production branch worktree, where the code is run from.
  - `feature-<something>/`
  - `fix-<something>/`

## workflow

- from the dev worktree, you'd run `git merge feature/something fix/something` to octopus merge all the topic branches into dev.
  - if everything works, do not merge dev into prod, but instead merge the topic branches directly into prod.
  - this prevents git history from being polluted with long-lived branches being merged everywhere (not meaningful).
