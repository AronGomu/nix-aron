---
name: make-audit-aron
description: Audit project code autonomously with read-only agent swarms, open one GitHub issue per validated finding, plan fixes, then implement tickets sequentially on main with additive commits only. Use for full codebase audit-to-main execution.
disable-model-invocation: true
argument-hint: "[project-path]"
---

# make-audit-aron

Rule ids `A1`-`L4` → `~/.agents/GLOBAL_RULES.md` (pi appends it to the system prompt; other harnesses read it).

Project in → swarm audit → validated GitHub issues → autonomous plans → serial impl directly on `main`.

## Pre-flight

Read fully:

- `~/.agents/skills/caveman/SKILL.md`
- `~/.agents/skills/_shared/orchestration.md`
- `~/.agents/skills/make-plan-aron/SKILL.md`
- `~/.agents/skills/make-aron/SKILL.md`
- `~/.agents/roles/planner.md`

Conflict override:

- Outer job = audit queue, one plan per finding. Core single-plan loop applies inside each finding through `make-aron`.
- Invocation grants GitHub issue writes plus additive commit/push writes to `main`. Core unasked-publish ban does not apply to those writes.
- Whole run autonomous. Skip grill, plan approval, mid-run prompts. Required human action/secret/account → affected finding `blocked_user`; never ask. Core hard stops remain.
- `make-plan-aron` output limited to Markdown index/ticket files. Skip HTML/ADR/architecture docs plus `xdg-open` unconditionally.
- Deep-tier knob unavailable → highest available model/effort, record mismatch in `PROGRESS.md`, continue without prompt.
- Parent owns orchestration, state, issue publish, main synchronization. Children own audit, plan, code writes.
- J1 holds throughout: history append-only, additive commits only.

## Inputs

1. **Project path** — Git repo path. Missing → current cwd.
2. GitHub remote must be `origin`.
3. Target branch = `main`. Missing `origin/main` → hard stop.

## Const

| Name | Value |
| --- | --- |
| Run ID | `{YYYY_MM_DD}_{repo}_{origin-main-sha12}` |
| State root | `{project}/.tmp/MAKE_AUDIT_{run-id}/` |
| Progress | `{state-root}/PROGRESS.md` |
| Audit report | `{state-root}/AUDIT.md` |
| Finding spec | `{state-root}/F{n}_{slug}.md` |
| Issue body | `{state-root}/F{n}_{slug}_ISSUE.md` |
| Worktree root | `/tmp/make-audit-aron-{run-id}/` |
| Implementation branch | `main` |
| Audit tier | `deep` |
| Plan tier | `deep` |
| Impl tier | `standard`; risky/repair → `deep` |

Never stage `{state-root}`. Keep state files for resume. Implementation uses project’s existing `main` worktree only; never create ticket branches/worktrees.

## Process

1. **Gate repo** — resolve absolute path. Run `git fetch origin --prune`, `git rev-parse --verify origin/main`, `git rev-parse --abbrev-ref HEAD`, `git status --porcelain`, `gh auth status`, `gh repo view --json nameWithOwner,visibility`. Require current branch `main`, clean worktree, local `main` equal `origin/main`. Any mismatch → hard stop; never reset/rebase/merge away mismatch. Record repo, visibility, snapshot SHA. Audit `origin/main`.
2. **Resume/init** — load `PROGRESS.md` for same Run ID. Reuse issue IDs plus committed ticket state. Never duplicate external objects or commits. Missing state → create status table, success checks, scope, assumptions, log.
3. **Snapshot** — create detached read-only audit worktree from `origin/main` at `{worktree-root}/audit`. Existing matching worktree → reuse after SHA check. SHA mismatch → hard stop; never remove or overwrite existing worktree.
4. **Audit swarm** — launch fresh-context read-only children in parallel. Every prompt starts `Read ~/.agents/roles/reviewer.md. Follow it.` Tier `deep`; set frontier model/high effort through spawn knobs. Pass Scope In = tracked first-party code/tests/config/docs at snapshot; Scope Out = vendored/generated/build outputs/submodules/style-only; Success = concrete dimension-specific failure with evidence. Explicit role report extension per finding: `Trigger`, `Proof/repro`, `Fix scope`, `Validation cmd`. One dimension each:
   - correctness, runtime failures, data integrity
   - security, trust boundaries, auth, secrets, deps
   - tests, error handling, concurrency, reliability
   - perf, resource leaks, algorithmic hot paths
   - maintainability, concrete refactors, dead paths, duplication
   - API/UX contracts, config, CI, deploy behavior

   Target = audit worktree. Require path:line, trigger, impact, proof/repro, smallest fix scope, validation cmd. Style taste/no concrete failure → no finding. Await whole swarm. Child fail → retry once. Dimension still missing → hard stop before issue writes.
5. **Validate findings** — normalize, dedupe, merge same root cause. Launch independent fresh `reviewer` children, tier `deep`, read-only, one candidate each; use candidate category as review dimension. Pass Scope In = candidate failure/fix boundary; Scope Out = unrelated findings/style; Success = independently prove/disprove same failure. Request reproduction/static proof plus attempted disproof inside role report `Failure:` field. `Verdict: clean` → drop. Same concrete failure returned under `findings` → validate. Severity map: proven immediate RCE/auth bypass/secret exposure/destructive data loss + `blocker` → `critical`; other `blocker` → `high`; `should-fix` → `medium`; actionable `note` → `low`. Categorize `bug|security|refactor|perf|test|ops`. Cosmetic refactor/no measurable outcome → drop. Build dep DAG, topo order. Write `AUDIT.md` plus finding specs. Zero findings → record clean audit, jump to step 9.
6. **Security gate** — private repo → normal flow. Public repo plus exploit-ready `critical|high` security finding → do not publish issue, code, plan, payload, secret, or commit. Mark `blocked_user`; retain evidence only under `{state-root}`; continue safe findings. Exact human action: authorize private advisory/disclosure path. Low-risk hardening may proceed only when issue/commit text leaks no exploit/secret.
7. **Create GitHub tickets** — serially create/reuse one issue per validated safe finding.
   - Fingerprint = SHA-256 of `{origin-main-sha}|{category}|{primary-path}|{symbol}|{normalized-summary}`, first 16 hex.
   - Marker = `<!-- make-audit-aron:{fingerprint} -->`.
   - Search all issues: `gh api --paginate "repos/{owner}/{repo}/issues?state=all&per_page=100" --jq '.[] | select((.body // "") | contains("{marker}")) | [.number,.html_url] | @tsv'`.
   - Marker match → reuse. No match → `gh issue create --title "[audit][{category}] {summary}" --body-file {issue-body}`.
   - Create fail → retry once. Payload validation fail → finding `blocked_user`; continue queue. Auth/permission fail → mark remaining writes `blocked_user`; jump to step 9.
   - Capture issue number/URL immediately in `PROGRESS.md`.
   - Issue body must carry marker, severity, evidence, trigger/repro, impact, scope, acceptance checks, deps, snapshot SHA. Never assume repo labels exist.
8. **Process issue queue** — topo-serial on current `main`. One writer only. Next issue starts only after prior issue reaches `implemented|failed|blocked_user`. Blocked prerequisite → `blocked_dep`; continue unrelated issue.
   1. **Sync gate** — before every issue run `git fetch origin`, require branch `main`, clean worktree, local `HEAD == origin/main`. Mismatch → `blocked_user`; never merge, rebase, reset, stash, or discard changes.
   2. **Plan** — spawn fresh writer child; native registry → `planner`, otherwise any writable child. Prompt first line: `Read ~/.agents/roles/planner.md. Follow it.` Tier `deep`; set frontier model/high-effort knobs. Pass Job spec = `{finding-spec}`; Repo/workspace = project `main` worktree; Scope In = finding fix boundary; Scope Out = other findings/app-wide cleanup; Publish policy = additive commits directly to `main`. Load `~/.agents/skills/make-plan-aron/SKILL.md`; caller mode `autonomous`; Markdown plan/ticket files only. Write one plan index plus self-contained ticket files in project worktree. Scope = this issue only. Child fail → one retry; still fail → `blocked_user`.
   3. **Validate plan** — fresh read-only `reviewer` fanout, tier `deep`: `scope/correctness`, `executability/TDD/deps`, `security/regression`. Pass Scope In = issue plan artifacts; Scope Out = app impl/unrelated findings; Success = exact, self-contained, compile-green executable plan for issue. Require exact paths, symbols, tests, cmds, dep outputs, compile-green slices, zero unresolved design choice. Blocker → one planning repair child, tier `deep`, then re-review. Still bad → keep the plan files on disk for resume/human review, mark `blocked_user`, comment blocker on issue; no impl.
   4. **Implement** — invoke `make-aron` with validated plan path. Use its `Caller override`: autonomous; supplied workspace/current branch = `main`; base ref = current `origin/main`; one issue scope; publish = additive commit(s) plus normal push to `origin/main`; no branch or PR creation. Required human interaction from first/any plan ticket → finding `blocked_user`, no question. Keep serial ticket loop, TDD, checkboxes, reviewers, one repair limit, evidence gates. Never implement another audit finding discovered during work; queue it for later validation.
   5. **Publish** — after all validation passes, verify every new commit descends from pre-issue `main` using `git merge-base --is-ancestor {pre-issue-sha} HEAD`; verify branch remains `main`; run `git push origin main` without force. Record commit SHA(s), push result, validation evidence. Comment issue with commit SHA(s) plus evidence; optionally close issue only when explicit caller policy allows it. Default: leave issue open.
   6. **Failure** — impl/push transient fail → one retry only when retry adds commits or repeats normal push. Auth/protection/exhausted repair → `blocked_user`; comment exact blocker plus human action on issue when safe. Never undo, alter, hide, or replace any commit. Stop queue if local `main` has unpublished commits; continuing could mix ticket state.
9. **Final validate** — reconcile GitHub issues, `main`, remote state, progress. Every safe validated finding has issue. Every `implemented` row has plan, additive commit SHA(s), passing evidence, plus commits reachable from `origin/main`. No duplicate fingerprints. No secret in issue/commit/diff. Write final evidence to `AUDIT.md`. State-only drift → repair state. External mismatch → mark affected row `blocked_user`.
10. **Report** — return compact table: finding, severity, issue, state, commit SHA(s), proof/blocker.

## Output

`AUDIT.md` = snapshot, six-dimension coverage, candidate disposition, final issue/commit table, blocked rows, residual risk.

`F{n}_{slug}.md`:

```md
# F{n}: {summary}

- Fingerprint: {hex16}
- Category: bug|security|refactor|perf|test|ops
- Severity: critical|high|medium|low
- Depends: F? | none
- Evidence: `{path}:{line}` — {proof}
- Trigger: {input/state}
- Impact: {wrong result/harm}
- Fix scope: {smallest boundary}
- Validation: `{exact cmd}` → {expected}
```

`F{n}_{slug}_ISSUE.md` = marker, severity/category, problem, evidence, repro, impact, scope, acceptance checklist, deps, snapshot SHA.

`PROGRESS.md`:

```md
# Audit progress: {repo}

- Snapshot: `{origin-main-sha}`
- Visibility: public|private
- Started: {iso}
- Updated: {iso}

## Status

| ID | Finding | Severity | Depends | Issue | Plan | State | Commits | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |

States: discovered|validated|issue_open|planning|plan_valid|implementing|implemented|failed|blocked_user|blocked_dep|skipped

## Assumptions

- ...

## Log

- {iso} {event} — {evidence}
```

## Rules

- Serial issue impl directly on `main`. Audit/validation fanout read-only only.
- Plan artifacts for an issue stay on disk until that issue reaches `implemented`; only `make-aron`'s post-success final cleanup may remove them. Never delete plans for `blocked_*`, `failed`, or unprocessed issues — they are the resume state.
- One validated root cause → one GitHub issue → one plan → additive commit(s) on `main`.
- J1: commit then normal push, never rewrite. Existing unrelated commits untouched. Dirty worktree or local/remote divergence → hard stop.
- No fabricated findings. Evidence absent → drop candidate.
- No unbounded cleanup. Refactor/perf ticket needs observable gain plus validation.
- Existing issue marker or recorded commit → resume, never duplicate.
- External write result recorded immediately.
- J4 extends to state files, issue bodies, and plan artifacts.
- Hard stop one finding when possible; continue independent queue only from clean synchronized `main`.

## Done when

- Swarm covered all six dimensions against recorded `origin/main` SHA.
- Every candidate independently validated/dropped with reason.
- Every safe validated finding has reusable GitHub issue.
- Every implemented issue used validated `make-plan-aron` plan plus `make-aron` evidence loop.
- Every complete issue has additive commit SHA(s) reachable from `origin/main`.
- Queue terminal; blocked rows carry exact human action.
- `AUDIT.md` plus `PROGRESS.md` match GitHub plus `main` state.

## Assumptions

- “Ticket” means GitHub issue.
- One audit issue may contain multiple internal plan tickets/commits; all land sequentially on `main`.
- “Directly onto main” means no feature branch, PR, merge commit, or history rewrite.
- “Only addition” means append-only commits; existing history plus commits remain unchanged.
- Pure style findings excluded.

## Caller override

Caller may set project path, narrower path/category scope, existing Run ID. Missing → `Inputs`/`Const` defaults. Log scope exclusions. Explicit caller override wins except security gate, serial writer rule, evidence bar, hard stops. Skill stays autonomous unless user explicitly requests interactive mode.
