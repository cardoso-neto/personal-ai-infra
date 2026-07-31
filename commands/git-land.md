---
description: Land work onto master.
argument-hint: [branch] [no-ff] [squash]
---
# git-land

Land work onto master via fast-forward merge by default (creates merge commit if no-ff specified).

## Phase 0: branch + commit + PR (skip if they already exist)

1. If on master with uncommitted changes: `git fetch origin`, branch off master, `git add <files>` (never `-A`/`.`), commit.
2. If no PR: `git push -u origin <branch>`, then `gh pr create`.

## Phase 1: land

1. `git fetch -p origin master:master`
2. `git rebase origin/master`
   - Stash first if dirty; pop after.
   - On conflicts, preserve master's changes unless the branch explicitly updates them.
   - push force with lease and wait for CI to pass before continuing.
3. `git switch master`
4. `git merge origin/master`
5. `git merge $1 --ff-only`
   - Default to the just-rebased branch if no argument.
   - If ff fails, abort and notify user.
6. `git push`
   - Auto-closes the PR as merged.
7. `git push origin :$1`
   - `remote ref does not exist` is fine; GitHub auto-deletes on PR close.
8. `git branch -d $1`
9. `gh pr view --json state` -> expect `MERGED`.
