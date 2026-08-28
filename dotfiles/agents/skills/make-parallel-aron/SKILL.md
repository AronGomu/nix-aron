---
name: make-parallel-aron
description: Make implementation.
disable-model-invocation: true
---

# make-parallel-aron

Rule ids `A1`-`L4` → `~/.agents/GLOBAL_RULES.md` (pi appends it to the system prompt; other harnesses read it).

Goal or plan in → ticket workers (ship) → commit + push each → done or hard-stop.

## Orchestration core

Read `~/.agents/skills/_shared/orchestration.md` now and follow it fully.
Read `~/.agents/skills/_shared/cleanup-implementation.md` now and follow it at implementation start + end.
Orchestration core defines stance, success criteria, validation state, checkbox protocol, auto-decide, hard stop, parent loop, worker rules, report shapes, safety, anti-patterns, done output.
Cleanup protocol defines passive artifact/temp cleanup. This file wins on conflict.

## Input

`Arg1 = plan path` — **optional**.
`Arg1 = goal text` or empty → Step 0.

## Step 0 — no plan? make one — **interactive**

1. Read `~/.agents/skills/make-plan-aron/SKILL.md` now and follow it, **interactive**, at tier `deep` (frontier model, high effort): grill until shared understanding, then write plan.
   Session is below `deep` → say so, raise effort if you can, else tell the user which knob to turn before continuing.
2. Skip make-plan-aron's HTML plan / ADR / architecture docs unless goal asks — they cost time, not needed to implement.
3. Plan index lands at `./artifacts/PLAN_{YYYY_MM_DD}_{title}.md`, one ticket file per ticket in `./artifacts/PLAN_{YYYY_MM_DD}_{title}/T{n}_{slug}.md`. Index as Arg1.
4. Show index path + ticket order + ticket file list. Wait for user OK.

Empty input and no goal text → **STOP.** Ask for goal.

## Autonomy boundary

Plan confirmed, **or** plan supplied as Arg1 → implementation phase starts.

Implementation grants standing authorization for every in-scope special action or tool approval. Auto-authorize immediately; never ask user to approve it; log action + result. Tool permission denial → retry through available authorized path, then hard stop only when external auth/credential is unavailable. This authorization does not expand Scope In, reveal secrets, permit destructive production/data-loss actions, or override publish policy.

If first ticket from _make-plan_ frontload user interaction : ask user to handle ticket.
If not, analyse plan/goal and identify all possible necessary user interaction (e.g. package installation, account creation, linking API key, etc...) and frontload them into first ticket.

Then, when no user interaction required :

- **Zero user question** except hard stop (core Hard stop list).
- Ambiguity → safest in-scope default, log under plan `## Assumptions`.
- Fact unknown + findable → `scout` child (`~/.agents/roles/scout.md`), read-only. Never ask user a lookup.
- Fact unknown + only user can supply (secret, account, business rule) → `TODO(user)` → ticket `blocked_user`.
- Never re-open the plan for approval. No mid-run check-in, no "shall I continue?".

## Plan contract

Index `PLAN_{date}_{title}.md` — parse: Goal, Scope In/Out, Assumptions, Ticket order table (ID / Depends / file), flowchart deps. No ticket bodies here.
Ticket file `PLAN_{date}_{title}/T{n}_{slug}.md` — parse: Context, Requirements, Inputs (+ From Depends), TDD, Test plan, Impl steps, Outputs, Validation.

Index carries ticket bodies inline (legacy single-file plan) → split into per-ticket files first, inline each ticket's context + dep outputs, then run. Never hand a worker the index.

## Auto-decide — code layer

| Choice                | Default                                                                                                                                                                                            |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Branch                | `plan/{slug}`, slug = plan title kebab                                                                                                                                                             |
| Base                  | current default remote HEAD (`main`/`master`)                                                                                                                                                      |
| Plan breakdown        | tier `deep` — frontier model, high effort (Opus 5 high / GPT-5.6 Sol high). Never cheaper                                                                                                          |
| Worker                | fresh-context child, role `~/.agents/roles/impl-worker.md`, tier `deep` — **Opus 5, effort `high`**, always; loads skill `ship` if installed, else AgentSystemLabs ship playbook                  |
| Worker escalation     | worker already at top model/effort — escalation buys no model change, only ship depth `production` when ticket touches auth / pay / migrate / webhook / jobs / multi-subsystem, **or** it is the one repair attempt |
| Reviewer              | fresh-context children, role `~/.agents/roles/reviewer.md`, tier `deep`, dimensions: correctness, security, scope-drift, tests                                                                     |
| Scout                 | fresh-context child, role `~/.agents/roles/scout.md`, **Sonnet 5, effort `high`**, read-only, for any unknown fact                                                                                |
| Ship depth            | `balanced`; `production` if ticket touches auth / pay / migrate / webhook / jobs / multi-subsystem                                                                                                 |
| Commit                | **after** ship terminal `locally-verified` **and** ticket Validation pass                                                                                                                          |
| Granularity           | 1 commit per ticket minimum                                                                                                                                                                        |
| Push                  | every successful ticket commit → `origin` feature branch                                                                                                                                           |
| PR                    | **no**, unless plan or user said open PR                                                                                                                                                           |
| Progress              | `./.tmp/MAKE_PROGRESS_{slug}.md`                                                                                                                                                                   |
| Manual test checklist | `./artifacts/manual_test_checklist.md` — every ticket worker appends/updates its entries, never overwrites others'                                                                              |
| Tests                 | run relevant suite; tests mandatory when ticket has TDD                                                                                                                                            |
| Sanity                | pre-commit hooks honored; no `--no-verify` unless plan says                                                                                                                                        |

## Pre-flight (core Step 4)

1. Run shared **Start cleanup**. Remove only prior impl artifacts proven obsolete by current goal/plan.
2. Git clean enough. Dirty unrelated → isolate; only stop if cannot.
3. Create/checkout `feat/{slug}` from base. `git push -u origin HEAD` if new.
4. Init progress file + success criteria.

## Ticket worker

Spawn with role line first: `Read ~/.agents/roles/impl-worker.md. Follow it.`
Then tier line, ticket file path, workspace/branch, publish policy = commit + push feature branch, `ship` depth.

Model per table above — Opus 5 at effort `high`, every ticket. Never downgrade.
Claude Code: subagent `impl-worker` (opus/high). Other harness: set model+effort if it can, and always state model + effort in the prompt.
Role file owns read scope, checkbox duty, evidence bar, report shape. Below is the code-specific overlay.

```
1. Checkout feature branch. `git pull --ff-only` if safe.
2. Read **own ticket file** + its Inputs paths only. Never the index, never sibling tickets. No scope creep.
   Fact missing from ticket file → report `failed: plan defect — {missing fact}`. Parent inlines it, retries.
3. In the ticket file: ensure Impl steps + sub-steps + Validation lines have `- [ ]`; add if missing.
   Each box gets a validation criterion (cmd | file | behavior).
4. Run **ship**:
   - invoke `ship` skill on ticket goal
   - pass Requirements + TDD + Test plan + Impl steps as spec
   - mode = balanced | production per table
   - ship never commits/pushes by design — worker does git after
5. TDD honored: red → green → refactor. Test names from ticket file when given.
6. Each Impl step done → flip its `- [x]` immediately. Continuous.
7. Run ticket Validation cmds. App still functional this slice. Pass → check those boxes.
8. Not `locally-verified` → 1 repair loop inside worker → re-validate.
9. Still bad → report failed|blocked + evidence. **No commit.** Failed boxes stay unchecked.
10. Success:
    - update `./artifacts/manual_test_checklist.md` (create with a one-line header if absent): append/update this ticket's manual test steps — what a human must click/run to verify the slice works, plain unchecked `- [ ]` boxes, grouped under a `## T{n} {slug}` heading. Never touch other tickets' sections. This file must stay current with the implementation — if a later ticket changes prior behavior, update the stale entries, don't just append.
    - review own diff only
    - stage intentional product paths + manual_test_checklist.md (no plan/ticket files, secrets, .env, .tmp)
    - ticket checkbox updates remain local run-state; final cleanup removes them
    - commit: ticket draft msg, else `feat({scope}): {commit outcome}`
    - `git push -u origin HEAD`
    - report per core shape + `SHA:` + `Ship terminal:`
```

## Ship integration

- Source: https://github.com/AgentSystemLabs/core — skill `ship`.
- Prefer installed harness skill. Else worker follows ship playbook: classify → depth → playbook → verify. Same gates.
- `mode=fast` only for pure docs/cosmetic ticket.
- Any implementation special action/tool confirmation → **auto-approve inside this skill** (user already invoked make-parallel-aron). Includes production ship confirmation. Log `auto-authorized special action: {action}`.
- Ship "no publish" is overridden **only** for the feature branch. Worker publishes there, nowhere else.

## Git rules — code layer

Global J1-J5. Code layer adds:

- Branch `plan/{slug}` only.
- J2 push failure on auth / protected → ticket state `blocked_user`.

## Final cleanup

After final validation + review repairs:

1. Capture ticket states/evidence needed for final report.
2. Run shared **End cleanup**.
3. Remove current plan index, matching ticket dir, progress file, impl scratch/temp/log files.
4. Preserve `./artifacts/manual_test_checklist.md`.
5. Commit + push tracked cleanup changes. No cleanup diff → no empty commit.
6. Final report lists removed paths; progress path = `removed after successful run`.

## Done when

- Every ticket reached terminal state before cleanup
- Feature branch on remote carries all successful ticket commits + tracked cleanup
- Ticket boxes validated before ticket files removed
- Every index order-table row resolved before plan removed
- Current + superseded impl plan/ticket artifacts absent
- Impl progress/scratch/temp files absent
- `./artifacts/manual_test_checklist.md` exists, covers every shipped ticket, current with final implementation
- User gets core Done output + table: ID / state / SHA / blocker + cleanup paths
- Each hard stop has exact next human action, one line

## FINAL MESSAGE STRUCTURE

When autonomous implementation is done, final message report follow this structure :

```
STATUS IMPLEMENTATION : [COMPLETE | INCOMPLETE]

| Ticket Name | STATUS |
| ----------- | ------ |
| {ticket name} | [COMPLETE | INCOMPLETE] |
...

Notes :
- {List of decisions made not initialy planned}
...

@ if (STATUS == INCOMPLETE) {
BLOCKING :

REQUIRED USER ACTIONS :
}
```

## Anti-patterns — code layer

Core list, plus:

- Parent edits app code
- Commit before ship terminal `locally-verified`
- Skip TDD when ticket defines it
- Pass worker the index or a sibling ticket instead of its own ticket file path
- Worker reads sibling tickets to fill a gap instead of reporting the plan defect
- Plan below `deep`, then burn `high` workers rescuing vague tickets
- Run worker, scout, or reviewer below the model/effort in the table to save tokens
- Ask user anything after implementation started (re-confirm plan, "continue?", preference, special-action approval)

## Caller override

Caller may supply existing workspace, branch, base ref, publish policy. Then:

- Core Step 4 branch pre-flight verifies supplied workspace/branch; skips branch creation/checkout.
- `Auto-decide — code layer` Branch/Base plus `Git rules — code layer` branch-name default yield to exact supplied refs.
- Worker stays on supplied branch. Branch switch → fail before write.
- Commit/push/PR behavior follows supplied publish policy.
- All safety, serial-writer, TDD, evidence, review gates remain.

Caller override wins where explicit.
