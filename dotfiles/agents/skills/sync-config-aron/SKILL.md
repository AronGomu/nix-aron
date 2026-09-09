---
name: sync-config-aron
description: >
  Invoke before and after any agent update to config managed by the portable
  dev-config repo: editor, agents, skills, shell, tools, desktop, apps, services,
  manifests, scripts, or setup docs. Capture portable changes, validate, commit,
  synchronize the approved remote branch, verify a clean worktree. Also use for
  explicit reconciliation of manual or GUI config changes.
disable-model-invocation: false
argument-hint: "Changed config or config repo (optional)"
---

# sync-config-aron

Managed config update → portable source → validation → commit → reversible remote sync → clean + synchronized proof.

## Pre-flight

- F1. Read active global rules, target repo `AGENTS.md`, `docs/deployment.md`, `docs/validation.md`. Global safety/publish rules win.
- F2. Use deployment map to identify owner repo, source file, runtime destination, install mode. Resolve current user/XDG conventions; no fixed username or checkout path.
- F3. Missing owner/map → report `blocked: config ownership not configured`; request setup of deployment map. Never guess arbitrary cwd as config repo.
- F4. Invoke once before edits, once after successful batch. Nested config work reuses outer sync transaction; no recursive self-invocation. Failure still produces state report.

## Inputs

- I1. Changed config paths or requested update. No arg → inspect mapped config changes in known owner repo.
- I2. Explicit manual/GUI reconciliation → compare mapped runtime prefs against repo source; preserve intentional portable changes only.
- I3. Repo guide must name authoritative bootstrap remote + branch. Unconfigured → request user-owned remote choice; never invent remote, create remote repo, or change remote URL.

## Process

- P1. Snapshot baseline: `git status --porcelain=v1 --untracked-files=all`, current branch, upstream, HEAD, staged paths. Do not print credential-bearing remote URLs or config values.
- P2. Existing staged/unstaged/untracked changes outside authorized batch → stop sync before new edits. Report paths only; user chooses separate handling or explicitly expands scope. Never stash, discard, mass-stage, hide files with ignore rules, or commit unrelated work to manufacture cleanliness. After-edit invocation without baseline treats uncertain ownership as blocked.
- P3. Fetch configured remote without pruning. Retry network failure once; auth failure → block. Inspect target remote branch and ancestry. Divergence → block; no rebase/reset/force-push. Remote ahead with clean worktree → explicit fast-forward only (`git merge --ff-only` against configured remote-tracking branch). Remote ahead after edits → preserve edits, block for reconciliation. Missing remote branch → create only when configured target + branch policy already authorize it; otherwise resolve target authorization first.
- P4. Follow branch policy. Feature branch default; never directly push main/master without explicit authorization. Before editing, establish whether authorized final target is bootstrap branch or feature branch. Feature-only push must report bootstrap branch still pending; never claim full bootstrap sync.
- P5. Update canonical repo files first. Runtime edit already happened → extract only mapped portable prefs. Copy real contents, not Nix-store symlinks. Keep secrets, tokens, machine trust, sessions, caches, logs, model weights, local paths outside Git. Native config owns exact behavior; installer guide owns target adaptation.
- P6. Update deployment map/tool deps/setup docs only when behavior requires it. Preserve runtime-writable seed/merge policy; never replace whole mixed secret/state files. Apply only permitted user-level config changes; system apply remains user-executed.
- P7. Run checks from `docs/validation.md`: syntax + changed workflow smoke checks. Run `git diff --check`. Failed checks → bounded repair, then `failed`; no commit/push of unvalidated change. Environment-blocked checks → `blocked`, name missing evidence.
- P8. Review intended diff through secret-safe inspection. Run configured secret scanner before staging; scanner missing or findings unresolved → block publication. Redact findings; never print secret values. Confirm no unexpected deletion, generated output, private data, or out-of-scope file. Never use `git add .` or `git add -A`.
- P9. Stage exact intentional paths. Review complete staged diff/path list; ensure no other contributor staged changes appeared. Run `git diff --cached --check`. Commit conventional why-focused message; honor hooks. No change → no empty commit. Existing unpushed commits require scope/content review too; never publish unknown history automatically.
- P10. Before push, verify reversibility locally + remotely. Review remote visibility, outgoing content, CI/deploy hooks, downstream effects. Recovery must preserve history via new corrective commits, not forbidden reset/revert/force-push. Secrets exposed or irreversible jobs triggered cannot be undone by corrective commit. Unknown effects/recovery → `blocked: reversibility unverified`; irreversible action → stop/report/wait. Normal validated config sync to configured authorized target proceeds without per-push confirmation under G3. No PR creation unless asked; local clean is not remote sync.
- P11. Reversible push uses explicit configured remote + destination, never force. Network failure → retry once. Auth/protected/non-fast-forward rejection → block, preserve commit. Never amend, rewrite history, auto-merge PR, or bypass hooks/protection.
- P12. Fetch remote again; verify HEAD equals intended remote branch tip. For full bootstrap sync, that branch must be configured bootstrap branch. Re-run `git status --porcelain=v1 --untracked-files=all`; any output → not clean. Verify no staged diff, no ahead/behind commits (`git rev-list --left-right --count HEAD...<remote>/<branch>` → `0 0`). Substitute inspected remote/branch, never run placeholder literally.

## Done when

- D1. Changed workflow validation passed; portable source accurately captures requested config.
- D2. Entire repo status empty, including untracked files. Ignored auth/runtime state remains outside cleanliness contract; never add ignore patterns to conceal pending config work.
- D3. Local HEAD equals fetched approved remote branch tip; ahead/behind `0 0`.
- D4. Authoritative bootstrap branch includes update. Feature branch clean + pushed alone → partial delivery, not full bootstrap sync.
- D5. No protected user data removed, unrelated changes committed, auth leaked, history rewritten, or system apply run.

## Output

- O1. State: `done | failed | blocked`; distinguish local clean, feature-branch pushed, bootstrap synchronized.
- O2. Evidence: changed source paths, checks/results, commit SHA, sanitized remote label/branch, status output count, ahead/behind counts.
- O3. Blocked → exact next user action: auth, resolve target authorization, establish safe recovery/downstream behavior, handle unrelated changes, reconcile remote divergence, or complete authorized branch integration. Never say “synced” without remote proof.

## Rules

- R1. One writer per repo. Detect concurrent changes → stop sync, preserve work.
- R2. Never monitor filesystem, install hooks, run background pushes, or upload entire home/config directories.
- R3. GUI/manual changes need explicit invocation or next agent task; skill alone cannot observe them.
- R4. Repo cleanliness is success criterion, not permission to destroy or hide state.

## Assumptions

- A1. Installer wires mandatory invocation into shared global rules + repo guide; all harnesses load shared rules. Skill description alone is not enforcement.
- A2. Agent-mediated updates are automatic trigger scope. G3 permits reversible in-scope remote sync without per-push confirmation; irreversible local/remote actions remain blocked. Existing branch authorization, secret protection, immutable history, system-apply rules remain effective.
