---
name: gh
description: GitHub CLI access for reading repositories and, when explicitly requested, creating append-only branches, commits, pushes, issues, and pull requests.
---

# GitHub CLI

Rule ids `A1`-`L4` → `~/.agents/GLOBAL_RULES.md` (pi appends it to the system prompt; other harnesses read it).

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

Global J1 covers history immutability (also `git replace`, `git filter-branch`, `git filter-repo`, ref overwrite, tag movement). Deletion = new commit recording deletion.

GitHub-side, never without separate explicit confirmation:

- merge or close PRs
- delete branches, issues, releases, or repositories
- modify secrets, variables, permissions, or workflows

Before write: verify tests → J3 staged paths → J4 secret scan → J2 feature branch → return URLs + commit SHAs.
