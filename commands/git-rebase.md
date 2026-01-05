---
description: git fetch, git rebase, get push.
argument-hint: [branch]
---
# git-rebase

1. `git fetch origin master:master -p`
2. `git rebase origin/$1`
   1. Assume `git rebase origin/master` if no branch is providers as an argument above.
3. if conflicts arise, fix them.
   1. Keep in mind you shouldn't undo changes coming from master when fixing conflicts.
   2. Unless they're what the commits being rebased aim to update.
   3. `git add file-path-1 ...`
   4. `git rebase --continue`
4. `git push --force-with-lease`
