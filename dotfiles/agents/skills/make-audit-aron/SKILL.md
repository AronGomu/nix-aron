---
name: make-audit-aron
description: Audit project code autonomously with read-only agent swarms, open one GitHub issue per validated finding, plan fixes, implement serially, open PRs to main. Use for full codebase audit-to-PR execution.
disable-model-invocation: true
argument-hint: "[project-path]"
---

# make-audit-aron

Project in → swarm audit → validated GitHub issues → autonomous plans → serial impl → PR per issue.

## Pre-flight

Read fully:

- `~/.agents/skills/caveman/SKILL.md`
- `~/.agents/skills/_shared/orchestration.md`
- `~/.agents/skills/make-plan-aron/SKILL.md`
- `~/.agents/skills/make-aron/SKILL.md`
- `~/.agents/roles/planner.md`

Conflict override:

- Outer job = audit queue, one plan per finding. Core single-plan loop applies inside each finding through `make-aron`.
- Invocation grants GitHub issue/branch/PR writes. Core unasked-publish ban does not apply to those writes.
- Whole run autonomous. Skip grill, plan approval, mid-run prompts. Required human action/secret/account → affected finding `blocked_user`; never ask. Core hard stops remain.
- `make-plan-aron` output limited to Markdown index/ticket files. Skip HTML/ADR/architecture docs plus `xdg-open` unconditionally.
- Deep-tier knob unavailable → highest available model/effort, record mismatch in `PROGRESS.md`, continue without prompt.
- Parent owns orchestration, state, issue/PR publish. Children own audit, plan, code writes.

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
| PR body | `{state-root}/F{n}_{slug}_PR.md` |
| Worktree root | `/tmp/make-audit-aron-{run-id}/` |
| Branch | `audit/{issue-number}-{slug}` |
| PR base | `main` |
| Audit tier | `deep` |
| Plan tier | `deep` |
| Impl tier | `standard`; risky/repair → `deep` |

Never stage `{state-root}`. Remove worktrees after terminal finding. Keep state files for resume.

## Process

1. **Gate repo** — resolve absolute path. Run `git fetch origin --prune`, `git rev-parse --verify origin/main`, `gh auth status`, `gh repo view --json nameWithOwner,visibility`. Failure → hard stop before external write. Record repo, visibility, `origin/main` SHA, dirty local state. Audit `origin/main`, not dirty cwd.
2. **Resume/init** — load `PROGRESS.md` for same Run ID. Reuse issue/branch/PR IDs. Never duplicate external objects. Missing state → create status table, success checks, scope, assumptions, log.
3. **Snapshot** — create detached worktree from `origin/main` at `{worktree-root}/audit`. Existing matching worktree → reuse after SHA check. SHA mismatch → remove temp worktree, recreate; unsafe path/remove fail → hard stop.
4. **Audit swarm** — launch fresh-context read-only children in parallel. Every prompt starts `Read ~/.agents/roles/reviewer.md. Follow it.` Tier `deep`; set frontier model/high effort through spawn knobs. Pass Scope In = tracked first-party code/tests/config/docs at snapshot; Scope Out = vendored/generated/build outputs/submodules/style-only; Success = concrete dimension-specific failure with evidence. Explicit role report extension per finding: `Trigger`, `Proof/repro`, `Fix scope`, `Validation cmd`. One dimension each:
   - correctness, runtime failures, data integrity
   - security, trust boundaries, auth, secrets, deps
   - tests, error handling, concurrency, reliability
   - perf, resource leaks, algorithmic hot paths
   - maintainability, concrete refactors, dead paths, duplication
   - API/UX contracts, config, CI, deploy behavior

   Target = audit worktree. Require path:line, trigger, impact, proof/repro, smallest fix scope, validation cmd. Style taste/no concrete failure → no finding. Await whole swarm. Child fail → retry once. Dimension still missing → hard stop before issue writes.
5. **Validate findings** — normalize, dedupe, merge same root cause. Launch independent fresh `reviewer` children, tier `deep`, read-only, one candidate each; use candidate category as review dimension. Pass Scope In = candidate failure/fix boundary; Scope Out = unrelated findings/style; Success = independently prove/disprove same failure. Request reproduction/static proof plus attempted disproof inside role report `Failure:` field. `Verdict: clean` → drop. Same concrete failure returned under `findings` → validate. Severity map: proven immediate RCE/auth bypass/secret exposure/destructive data loss + `blocker` → `critical`; other `blocker` → `high`; `should-fix` → `medium`; actionable `note` → `low`. Categorize `bug|security|refactor|perf|test|ops`. Cosmetic refactor/no measurable outcome → drop. Build dep DAG, topo order. Write `AUDIT.md` plus finding specs. Zero findings → record clean audit, jump to step 9.
6. **Security gate** — private repo → normal flow. Public repo plus exploit-ready `critical|high` security finding → do not publish issue, branch, code, plan, payload, secret, PR. Mark `blocked_user`; retain evidence only under `{state-root}`; continue safe findings. Exact human action: authorize private advisory/disclosure path. Low-risk hardening may proceed only when issue/PR text leaks no exploit/secret.
7. **Create GitHub tickets** — serially create/reuse one issue per validated safe finding.
   - Fingerprint = SHA-256 of `{origin-main-sha}|{category}|{primary-path}|{symbol}|{normalized-summary}`, first 16 hex.
   - Marker = `<!-- make-audit-aron:{fingerprint} -->`.
   - Search all issues: `gh api --paginate "repos/{owner}/{repo}/issues?state=all&per_page=100" --jq '.[] | select((.body // "") | contains("{marker}")) | [.number,.html_url] | @tsv'`.
   - Marker match → reuse. No match → `gh issue create --title "[audit][{category}] {summary}" --body-file {issue-body}`.
   - Create fail → retry once. Payload validation fail → finding `blocked_user`; continue queue. Auth/permission fail → mark remaining writes `blocked_user`; jump to step 9.
   - Capture issue number/URL immediately in `PROGRESS.md`.
   - Issue body must carry marker, severity, evidence, trigger/repro, impact, scope, acceptance checks, deps, snapshot SHA. Never assume repo labels exist.
8. **Process issue queue** — topo-serial. One writer/worktree only. Next issue starts only after prior issue reaches `pr_open|failed|blocked_user`. Blocked prerequisite → `blocked_dep`; continue unrelated issue.
   1. **Choose source** — no code dep → latest `origin/main`. One open dep → `origin/{dep-branch}`. Multiple deps → choose latest dep head only if `git merge-base --is-ancestor` proves every other dep head included. No containing head → `blocked_dep` until deps merge. PR target stays `main`.
   2. **Create branch/worktree** — `git worktree add -b audit/{issue-number}-{slug} {worktree-root}/issue-{issue-number} {source-ref}`. Existing matching branch/worktree → verify SHA, reuse. Name collision/mismatched history → `blocked_user`; never overwrite.
   3. **Plan** — spawn fresh writer child; native registry → `planner`, otherwise any writable child. Prompt first line: `Read ~/.agents/roles/planner.md. Follow it.` Tier `deep`; set frontier model/high-effort knobs. Pass Job spec = `{finding-spec}`; Repo/worktree = issue worktree; Scope In = finding fix boundary; Scope Out = other findings/app-wide cleanup; Publish policy = local commit. Load `~/.agents/skills/make-plan-aron/SKILL.md`; caller mode `autonomous`; Markdown plan/ticket files only. Write one plan index plus self-contained ticket files in issue worktree. Scope = this issue only. Commit plan artifacts locally as `docs(audit): plan issue #{issue-number}`. No push. Child fail → one retry; still fail → `blocked_user`.
   4. **Validate plan** — fresh read-only `reviewer` fanout, tier `deep`: `scope/correctness`, `executability/TDD/deps`, `security/regression`. Pass Scope In = issue plan artifacts; Scope Out = app impl/unrelated findings; Success = exact, self-contained, compile-green executable plan for issue. Require exact paths, symbols, tests, cmds, dep outputs, compile-green slices, zero unresolved design choice. Blocker → one planning repair child, tier `deep`, then re-review. Still bad → `blocked_user`; comment blocker on issue; no impl.
   5. **Implement** — invoke `make-aron` with validated plan path. Use its `Caller override`: autonomous; supplied workspace/current audit branch/base ref from step 8.1; one issue scope; publish = commit/push audit branch, no PR inside `make-aron`. Required human interaction from first/any plan ticket → finding `blocked_user`, no question. Keep its serial ticket loop, TDD, checkboxes, reviewers, one repair limit, evidence gates. Never implement another audit finding discovered during work; queue it for later validation.
   6. **Open PR** — only after `make-aron` reports complete plus all validation passes. Search via `gh pr list --state all --head {branch} --json number,url,headRefName`; exact head match → reuse. Else run `gh pr create --base main --head {branch} --title "{type}: {issue-summary}" --body-file {pr-body}`. Type map: bug→`fix`, security→`security`, perf→`perf`, refactor→`refactor`, test→`test`, ops→`chore`. Body includes `Closes #{issue-number}`, source snapshot, plan path, change summary, test evidence, manual checks, risks, dependency PRs. Open ready PR, not draft. Record URL.
   7. **Failure** — impl/push/PR transient fail → one retry. Auth/protection/exhausted repair → `blocked_user`; comment exact blocker plus human action on issue. No success PR. Continue unrelated queue.
   8. **Cleanup** — remove terminal issue worktree. Never delete remote branch, issue, PR, state.
9. **Final validate** — reconcile GitHub state against progress. Every safe validated finding has issue. Every `pr_open` row has plan, branch, commits, passing evidence, PR base `main`. No duplicate fingerprints. No secret in issue/PR/diff. Write final evidence to `AUDIT.md`. State-only drift → repair state. External mismatch → mark affected row `blocked_user`.
10. **Report** — return compact table: finding, severity, issue, source branch, state, PR, proof/blocker. Never merge PRs.

## Output

`AUDIT.md` = snapshot, six-dimension coverage, candidate disposition, final issue/PR table, blocked rows, residual risk.

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

`F{n}_{slug}_PR.md`:

```md
Closes #{issue-number}

## Fix
- Snapshot: `{sha}`
- Plan: `{path}`
- Changes: ...

## Validation
- `{cmd}` → {proof}
- Manual: ...

## Dependencies
- {PR URL | none}

## Risk
- {risk/residual risk}
```

`PROGRESS.md`:

```md
# Audit progress: {repo}

- Snapshot: `{origin-main-sha}`
- Visibility: public|private
- Started: {iso}
- Updated: {iso}

## Status

| ID | Finding | Severity | Depends | Issue | Source | Branch | Plan | State | PR | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

States: discovered|validated|issue_open|planning|plan_valid|implementing|pr_open|failed|blocked_user|blocked_dep|skipped

## Assumptions

- ...

## Log

- {iso} {event} — {evidence}
```

## Rules

- Serial issue impl. Audit/validation fanout read-only only.
- One validated root cause → one GitHub issue → one plan → one branch → one PR.
- PR base always `main`. Branch source may be `origin/main` / prerequisite PR head.
- No auto-merge, force-push, history rewrite, issue close, branch delete.
- No fabricated findings. Evidence absent → drop candidate.
- No unbounded cleanup. Refactor/perf ticket needs observable gain plus validation.
- Existing issue/PR marker/branch → resume, never duplicate.
- External write result recorded immediately.
- Secret/credential/PII never enters state, issue, plan, commit, PR, output.
- Hard stop one finding when possible; continue independent queue.

## Done when

- Swarm covered all six dimensions against recorded `origin/main` SHA.
- Every candidate independently validated/dropped with reason.
- Every safe validated finding has reusable GitHub issue.
- Every implemented issue used validated `make-plan-aron` plan plus `make-aron` evidence loop.
- Every complete issue has distinct audit branch plus ready PR targeting `main`.
- Queue terminal; blocked rows carry exact human action.
- `AUDIT.md` plus `PROGRESS.md` match GitHub state.

## Assumptions

- “Ticket” means GitHub issue.
- One audit issue may contain multiple internal plan tickets/commits; still one PR.
- “Onto main” means PR base `main`.
- Dependent branch may start from open prerequisite PR head; PR still targets `main`.
- PR creation requested; PR merge not requested.
- Pure style findings excluded.

## Caller override

Caller may set project path, narrower path/category scope, existing Run ID. Missing → `Inputs`/`Const` defaults. Log scope exclusions. Explicit caller override wins except security gate, serial writer rule, evidence bar, hard stops. Skill stays autonomous unless user explicitly requests interactive mode.
