---
description: Rebase feature branch on master, fast-forward merge to master, push, and delete remote branch.
argument-hint: [branch]
---
# git-land

Land a feature branch onto master via fast-forward merge.

1. `git fetch origin`
2. `git rebase origin/master`
   - If no branch argument provided, rebase current branch.
   - If conflicts arise, fix them preserving master's changes unless the feature branch explicitly updates them.
   - `git add <files>` then `git rebase --continue`
3. `git switch master`
4. `git merge origin/master`
   - Update local master to match remote.
5. `git merge $1 --ff-only`
   - Use current branch name if no argument provided.
   - If fast-forward fails, abort and notify user (branch needs rebase).
6. `git push`
7. `git push origin :$1`
   - Delete the remote feature branch.
8. `git branch -d $1` to delete local branch.
