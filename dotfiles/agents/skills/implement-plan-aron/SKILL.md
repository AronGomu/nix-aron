---
name: implement-plan-aron
description: >
  Orchestrate plan tickets (make-plan-aron). Parent reads plan, topo-order
  workers. Each worker /ship ticket → validate → commit → push feature branch →
  report. No user Q unless hard stop. User-invoked only.
argument-hint: "Path to plan md (default ./.tmp/IMPLEMENTATION_PLAN_*.md)"
disable-model-invocation: true
---

# implement-plan-aron

Plan in → feature branch → ticket workers (ship) → commit/push each → all done or hard-stop.

**Parent = orchestrator only.** No impl in parent. Children write code.

## Input

Arg1 = plan path. STOP if missing.

Parse: Goal, Scope, Ticket order table, each `### T{n}` block, flowchart deps.

## Auto-decide (no ask)

| Choice                                                    | Default                                                                                          |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| Branch                                                    | `plan/{slug}` slug=plan title kebab, lower, strip junk                                           |
| Base                                                      | current default remote HEAD (`main`/`master`)                                                    |
| Order                                                     | Ticket order table + **Depends** hard. Never skip dep                                            |
| Parallel                                                  | **Off.** One writer cwd. Serial tickets even if flowchart siblings                               |
| Worker                                                    | fresh-context impl agent; skill `ship` if installed else instruct load AgentSystemLabs ship      |
| Ship depth                                                | `balanced` default; `production` if ticket touches auth/pay/migrate/webhook/jobs/multi-subsystem |
| Commit                                                    | **after** ship terminal `locally-verified` + ticket Validation checks                            |
| Push                                                      | every successful ticket commit → `origin` feature branch                                         |
| PR                                                        | **no** open PR unless plan/user said open PR                                                     |
| Progress                                                  | `./.tmp/IMPLEMENT_PROGRESS_{slug}.md` update each ticket                                         |
| Resume                                                    | read progress; skip `done`; retry `failed` once; halt `blocked_user`                             |
| Ambiguity                                                 | pick safest in-scope option; log under Assumptions in progress. No user ping                     |
| `TODO(user)` / secret / prod destroy / missing credential | **hard stop** that ticket + any dependants                                                       |

## Hard stop (only stop reasons)

Stop ticket (mark `blocked_user`) when:

- plan `TODO(user)` blocks impl
- need secret/cred/API key/human auth
- irreversible prod/data loss needs human OK
- ship terminal `blocked` / `partial` after 1 repair loop still fail
- validation cmds fail after 1 repair loop
- push rejected (auth/protected branch) after no safe fix

**Execution end when:**

- all tickets `done`, **or**
- every remaining not-done ticket is `blocked_user` or depends only on blocked chain

Then report summary. Do not spin forever.

## Job — orchestrator (parent)

```
1. Load plan. Parse tickets + deps.
2. Ensure git clean enough start. Dirty unrelated → stash or stop only if cannot isolate.
3. Create/checkout branch `plan/{slug}` from base. Push `-u` if new.
4. Write/init progress file.
5. Loop topo-serial:
   a. Next ticket all Depends = done.
   b. None left unblocked → break.
   c. Launch **one** worker subagent (fresh). Wait finish.
   d. Read worker report. Update progress.
   e. Worker failed repairable → one parent-directed retry worker max.
   f. Still bad → mark blocked_user or failed; skip dependants as blocked_dep.
6. Final summary → user. List done / blocked / branch / commits.
```

Use **pi-subagents** single agent, `async:false` (or await), `context:fresh`. Parent never parallel writers same cwd.

### Progress file shape

```md
# Implement progress: {title}

- Branch: plan/{slug}
- Plan: {path}
- Started: {iso}
- Updated: {iso}

## Status

| ID  | Title | State        | SHA    | Note           |
| --- | ----- | ------------ | ------ | -------------- |
| T1  | ...   | done         | abc123 | ...            |
| T2  | ...   | blocked_user | —      | need API key X |

States: pending | running | done | failed | blocked_user | blocked_dep | skipped

## Log

- {iso} T1 start
- {iso} T1 done {sha}
```

## Job — ticket worker (child)

Worker task prompt **must** include: branch name, plan path, full ticket body, Depends outputs, ship rules, commit msg draft from ticket.

```
1. Checkout feature branch. git pull --ff-only if safe.
2. Read ticket only + needed Inputs paths. No scope creep.
3. Run **ship** (AgentSystemLabs/core):
   - Invoke ship skill / `/ship` on ticket goal.
   - Pass ticket Requirements + TDD + Test plan + Impl steps as spec.
   - mode=balanced|production per rules.
   - Ship **never** commit/push (ship design). Worker does git after.
4. TDD honor: red→green→refactor per ticket. Tests name from plan when given.
5. Validate ticket Validation checklist. Run listed cmds. App still functional slice.
6. If not locally-verified → repair once inside worker → re-validate.
7. Still bad → report failed/blocked + evidence. **No commit.**
8. Success:
   - git status/diff review own files only
   - stage relevant paths (no secrets, no .env)
   - commit msg = ticket draft or `feat({scope}): {commit outcome}`
   - `git push -u origin HEAD` feature branch
   - report done + sha + files + cmds run
```

### Worker report (return to parent)

```md
## Ticket {ID} report

- State: done|failed|blocked_user
- SHA: {sha|—}
- Ship terminal: locally-verified|partial|blocked|diagnosed|—
- Files: ...
- Validation: pass|fail + cmd evidence
- Blocker: {if any}
- Next parent action: continue|retry|halt-chain
```

## Ship integration

- Source: https://github.com/AgentSystemLabs/core — skill `ship`
- Prefer installed harness skill path (`ship` / agentsystem). Else tell worker: follow ship playbook classify→depth→playbook→verify; same gates.
- Overrides OK: `mode=fast` only pure docs/cosmetic tiny ticket.
- Production mode ship may want confirm — **auto-approve inside this skill** (user already invoked implement-plan). Log "auto-approve production ship".
- After ship: **worker** commits + pushes (override ship "no publish" — this skill owns publish to feature branch only).

## Git rules

- Branch only `plan/{slug}`. No commit `main`/`master`.
- One commit **per ticket** minimum (ticket = commit slice). Split only if ship forced extra clean commits — still push all.
- No force-push. No amend others. No rewrite published history.
- Pre-commit fail → fix or blocked; no `--no-verify` unless plan says.
- Never commit secrets. Scan diff.
- Push fail network → retry 1. Auth fail → blocked_user.

## Scope / safety

- Stay in plan Scope In. Out-of-scope drive-by → drop.
- No delete files unless ticket requires; prefer ticket Outputs list.
- match make-plan-aron: vertical slice, tests mandatory when ticket has TDD.
- Residual risk → note progress Log. Do not silent ignore.

## Done when

- Progress all tickets terminal state
- Feature branch on remote has all successful ticket commits
- User sees table: ID / state / sha / blockers
- Hard stops listed with exact next human action one-liner each

## Orchestrator anti-patterns

- Parent edits app code
- Skip Depends
- Many writers one cwd
- Infinite repair loops (>1 retry / ticket)
- Open PR unasked
- Ask user trivia / preference / style — auto-decide
- Mark done without validate cmds

```

```
