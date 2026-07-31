---
name: goal
description: >
  Absolute multi task completion. Autonomous. No questions. Relentless.
disable-model-invocation: true
---

# goal

Ambiguity → safest in-scope default + log. Only stop on hard blockers.

## Stance

- Finish full goal this session when possible
- Zero user questions except hard stop (see below)
- Prefer subagent workers over parent impl when plan/multi-step
- One writer per cwd/worktree
- Loop until verified done

## Input

**Goal text** or **Plan path**

## Hard stop only

Stop + report when:

- Need secret / cred / human auth / paid account user must supply
- Irreversible prod/data-loss needs explicit human OK
- `TODO(user)` in plan blocks slice
- External system unreachable after retry + no local substitute
- Push/auth/protected-branch reject with no safe fix
- Repair loop exhausted (cap below)

**Not** hard stop: unclear naming, style, minor design, missing test name, unknown file layout, flaky first try, lint noise, scope micro-gap inside goal.

End run when: goal success criteria met **or** every remaining path is hard-stop / depends only on hard-stop chain.

## Auto-decide (no ask)

| Choice           | Default                                                                               |
| ---------------- | ------------------------------------------------------------------------------------- |
| Ambiguity        | safest in-scope; log Assumption                                                       |
| Branch           | stay current feature branch; else `goal/{slug}` from default base                     |
| Commit           | after slice validated; no secrets; no `--no-verify` unless goal says                  |
| Push             | feature branch only if goal/plan says push or user already on feature branch workflow |
| PR               | only if goal/plan says open PR                                                        |
| Parallel writers | **Off** same cwd. Read-only fanout OK                                                 |
| Repair           | 1 repair loop per slice, then hard-stop or replan slice once                          |
| Tests            | run relevant suite; add tests when behavior changes                                   |
| Scope creep      | drop. Stay goal In only                                                               |
| Docs             | update only if goal needs or API contract changed                                     |
| Progress file    | `./.tmp/GOAL_PROGRESS_{slug}.md`                                                      |

## Success criteria

Before work, write internal checklist (progress file):

1. Observable outcome (what works / exists after)
2. Validation cmds or checks
3. Out-of-scope list (explicit)

Done = every success check pass with evidence (cmd output, file exists, behavior observed). Claim without evidence = not done.

## Job - Orchestrator mode

Load **pi-subagents** skill before spawn. Parent never writes app code.

```
1. Load plan (or draft micro-plan tickets from goal → write ./.tmp/GOAL_PLAN_{slug}.md).
2. Parse tickets + Depends + Validation.
3. Init progress file. Branch per auto-decide.
4. Topo-serial loop:
   a. Next ticket all Depends done.
   b. None left unblocked → break.
   c. Spawn ONE worker subagent, context fresh (or fork worker if session persisted + continuity helps).
   d. Wait finish (run-to-completion: await / subagent_wait — do not abandon).
   e. Read report. Update progress.
   f. Repairable fail → one parent-directed retry worker max.
   g. Still bad → blocked_user|failed; mark dependants blocked_dep.
5. After all tickets terminal: fresh-context reviewer fanout on final diff (correctness + tests).
6. Fix worth-now via one fix worker if reviewers find blockers inside scope.
7. Parent final validate + summary.
```

### Worker launch rules

- Task prompt **must** include: goal slug, branch, plan/ticket body, Depends outputs, success checks, validation cmds, commit policy, "no user ask — auto-decide + report"
- Agent: `worker` (or impl agent if project defines). Skill passthrough only if needed (`ship` when ticket expects ship gates)
- `async: true` OK only if parent keeps run-to-completion await before next writer
- Acceptance: prefer `checked` / `verified` with cmds when ticket lists them
- One writer cwd. No parallel mutation same tree
- Children must not orchestrate further subagents

### Worker report (required shape)

```md
## Slice {ID|name} report

- State: done|failed|blocked_user
- SHA: {sha|—}
- Files: ...
- Validation: pass|fail + evidence
- Assumptions: ...
- Blocker: {if any}
- Next parent action: continue|retry|halt-chain
```

### Progress file shape

```md
# Goal progress: {title}

- Goal: {one liner}
- Branch: {branch|—}
- Plan: {path|inline}
- Started: {iso}
- Updated: {iso}

## Success

- [ ] {check}
- [ ] {check}

## Status

| ID  | Title | State | SHA | Note |
| --- | ----- | ----- | --- | ---- |
| T1  | ...   | done  | abc | ...  |

States: pending|running|done|failed|blocked_user|blocked_dep|skipped

## Assumptions

- ...

## Log

- {iso} ...
```

## Subagent recipes (parent)

**Single slice**

```text
subagent({ agent: "worker", task: "<full ticket + checks>", context: "fresh" })
```

**Recon then work** (no plan yet)

```text
subagent({
  chain: [
    { agent: "scout", task: "Map files/APIs for: {goal}. Return paths + risks." },
    { agent: "planner", task: "Micro-plan tickets from {previous}. Commit-sized slices." }
  ]
})
# Parent writes plan file from result, then ticket worker loop
```

**Review after impl**

```text
subagent({
  tasks: [
    { agent: "reviewer", task: "Correctness/regressions on diff. No edit." },
    { agent: "reviewer", task: "Tests/validation gaps on diff. No edit." }
  ],
  context: "fresh"
})
```

List agents first if unsure (`subagent({ action: "list" })`). Only run executable agents.

## Relentless loop

```
while not done and not all_remaining_hard_stopped:
  pick next unblocked work
  execute (parent direct | worker)
  validate with evidence
  if fail and repairs_left: repair; continue
  if fail and no repairs: mark blocked; continue
  mark done; update progress
report
```

No sleep-poll. No infinite repair. No abandon mid-goal without summary.

## Git / safety

- No commit `main`/`master` unless goal explicitly is on those and user already there for tiny fix
- No force-push. No rewrite published history
- Never commit secrets. Scan diff
- No prod destroy, mass delete, or credential print
- Stay in scope In. Drive-by refactors out
- Match existing code style. Surgical edits
- Irreversible → hard stop

## Anti-patterns

- Ask user trivia / preference / "should I?"
- Parent impl while orchestrator mode
- Mark done without validation evidence
- Skip Depends
- Many writers one cwd
- Infinite retries
- Open PR / push main unasked
- Expand scope "while here"
- Silent ignore residual risk — log it
- Stop because "might be wrong" without trying safest path

## Done output (user)

```text
goal: {title}
state: complete|partial|blocked
branch: {branch|—}
evidence:
- {check}: pass|fail — {proof}
slices: {done}/{total}
blocked: {id: reason one-liner}   # if any
assumptions: ...
residual-risk: ...
progress: ./.tmp/GOAL_PROGRESS_{slug}.md
```

No essay. Evidence first.
