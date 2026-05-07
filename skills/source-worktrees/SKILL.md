---
name: source-worktrees
description: Use this skill when working with software installed or run from local source checkouts that use git worktree hubs.
---
# Source Worktree Layout

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

## cleanup

- `git fetch -p` from `bare/` prunes deleted `origin/*` refs and reveals dead worktrees.
- a branch is safe to delete when `git log <branch> ^origin/master` is empty.
  - squash-merged branches need `branch -D` (`-d` rejects with "not fully merged" because squash made different commits).
- when using git-annex, `git worktree remove` fails (`'.git' is not a .git file`) because `.git` is a symlink.
  - manual fallback: `rm -rf <worktree> bare/worktrees/<name>; git worktree prune -v`.
    - make sure no unstaged changes are lost before deleting.
    - this is destructive and cannot be undone, so double-check before running and ask for approval.
