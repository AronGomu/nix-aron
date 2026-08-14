---
name: gh
description: GitHub CLI access for reading repositories and, when explicitly requested, creating append-only branches, commits, pushes, issues, and pull requests.
---

# GitHub CLI

Use raw `gh` for GitHub operations.

Read operations may run whenever needed.

Write operations require explicit user request. Allowed:

- `git checkout -b`
- `git add` and new `git commit`
- normal `git push` to feature branches
- `gh pr create`
- `gh pr edit`
- `gh issue create` and `gh issue edit`

## Append-only Git history

Never modify local or remote Git history. Existing commits/refs = immutable.

Every content add/update/deletion → working-tree change → **new commit** → normal push. Deletion means new commit recording deletion; never erase prior commit.

Forbidden local + remote:

- `git commit --amend`
- `git rebase`, interactive rebase
- `git reset` of any mode
- `git cherry-pick`
- `git revert`
- commit squash/fixup/drop/reorder
- `git replace`, `git filter-branch`, `git filter-repo`
- force-push, `--force-with-lease`, ref overwrite
- branch/tag deletion or movement
- any cmd/API that removes, replaces, or rewrites existing history

Mistake in commit → add corrective commit. Divergence → stop + report; never repair by rewriting history.

Never without separate explicit confirmation:

- push to `main` or `master`
- merge or close PRs
- delete branches, issues, releases, or repositories
- modify secrets, variables, permissions, or workflows
- expose credentials

Before write:

1. Verify tests.
2. Check staged paths.
3. Scan for secrets.
4. Use feature branch.
5. Return URLs and commit SHAs.
