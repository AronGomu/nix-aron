---
name: make
description: Make implementation.
disable-model-invocation: true
---

# make

Goal or plan in → ticket workers (ship) → commit + push each → done or hard-stop.

## Orchestration core

Read `~/.agents/skills/_shared/orchestration.md` now and follow it fully.
It defines stance, success criteria, validation state, checkbox protocol, auto-decide, hard stop, parent loop, worker rules, report shapes, safety, anti-patterns, done output.
This file adds only the **code-specific** layer below. On conflict, this file wins.

## Input

`Arg1 = plan path` — **optional**.
`Arg1 = goal text` or empty → Step 0.

## Step 0 — no plan? make one — **interactive**

1. Read `~/.agents/skills/make-plan-aron/SKILL.md` now and follow it, **interactive**, at tier `deep` (frontier model, high effort): grill until shared understanding, then write plan.
   Session is below `deep` → say so, raise effort if you can, else tell the user which knob to turn before continuing.
2. Skip make-plan-aron's HTML plan / ADR / architecture docs unless goal asks — they cost time, not needed to implement.
3. Plan index lands at `./ai_artefacts/PLAN_{YYYY_MM_DD}_{title}.md`, one ticket file per ticket in `./ai_artefacts/PLAN_{YYYY_MM_DD}_{title}/T{n}_{slug}.md`. Index as Arg1.
4. Show index path + ticket order + ticket file list. Wait for user OK.

Empty input and no goal text → **STOP.** Ask for goal.

## Autonomy boundary

Plan confirmed, **or** plan supplied as Arg1 → implementation phase starts.

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

| Choice            | Default                                                                                                                                                                                            |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Branch            | `plan/{slug}`, slug = plan title kebab                                                                                                                                                             |
| Base              | current default remote HEAD (`main`/`master`)                                                                                                                                                      |
| Plan breakdown    | tier `deep` — frontier model, high effort (Opus 5 high / GPT-5.6 Sol high). Never cheaper                                                                                                          |
| Worker            | fresh-context child, role `~/.agents/roles/impl-worker.md`, tier `standard` (Sonnet 5 medium / Opus 5 low / GPT Terra medium); loads skill `ship` if installed, else AgentSystemLabs ship playbook |
| Worker escalation | tier `deep` when ticket touches auth / pay / migrate / webhook / jobs / multi-subsystem, **or** it is the one repair attempt. Same trigger as ship depth `production`                              |
| Reviewer          | fresh-context children, role `~/.agents/roles/reviewer.md`, tier `deep`, dimensions: correctness, security, scope-drift, tests                                                                     |
| Scout             | fresh-context child, role `~/.agents/roles/scout.md`, tier `cheap`, read-only, for any unknown fact                                                                                                |
| Ship depth        | `balanced`; `production` if ticket touches auth / pay / migrate / webhook / jobs / multi-subsystem                                                                                                 |
| Commit            | **after** ship terminal `locally-verified` **and** ticket Validation pass                                                                                                                          |
| Granularity       | 1 commit per ticket minimum                                                                                                                                                                        |
| Push              | every successful ticket commit → `origin` feature branch                                                                                                                                           |
| PR                | **no**, unless plan or user said open PR                                                                                                                                                           |
| Progress          | `./.tmp/MAKE_PROGRESS_{slug}.md`                                                                                                                                                                   |
| Tests             | run relevant suite; tests mandatory when ticket has TDD                                                                                                                                            |
| Sanity            | pre-commit hooks honored; no `--no-verify` unless plan says                                                                                                                                        |

## Pre-flight (core Step 4)

1. Git clean enough. Dirty unrelated → isolate; only stop if cannot.
2. Create/checkout `feat/{slug}` from base. `git push -u origin HEAD` if new.
3. Init progress file + success criteria.

## Ticket worker

Spawn with role line first: `Read ~/.agents/roles/impl-worker.md. Follow it.`
Then tier line, ticket file path, workspace/branch, publish policy = commit + push feature branch, `ship` depth.

Tier per table above — `standard` by default, `deep` on escalation.
Claude Code: subagent `impl-worker` (sonnet/medium) or `impl-worker-deep` (opus/high). Other harness: set model+effort if it can, and always state the tier in the prompt.
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
    - review own diff only
    - stage intentional paths + own ticket file checkbox updates (no secrets, no .env, no .tmp)
    - commit: ticket draft msg, else `feat({scope}): {commit outcome}`
    - `git push -u origin HEAD`
    - report per core shape + `SHA:` + `Ship terminal:`
```

## Ship integration

- Source: https://github.com/AgentSystemLabs/core — skill `ship`.
- Prefer installed harness skill. Else worker follows ship playbook: classify → depth → playbook → verify. Same gates.
- `mode=fast` only for pure docs/cosmetic ticket.
- Production ship may want confirm → **auto-approve inside this skill** (user already invoked make). Log `auto-approve production ship`.
- Ship "no publish" is overridden **only** for the feature branch. Worker publishes there, nowhere else.

## Git rules — code layer

- Branch `plan/{slug}` only. Never commit `main`/`master`.
- Push fail network → retry once. Auth / protected → `blocked_user`.
- New files must be `git add`-ed.
- Rest per core Safety.

## Done when

- Every ticket terminal in progress file
- Feature branch on remote carries all successful ticket commits
- Ticket-file boxes = ground truth, all checked steps have evidence
- Every index order-table row resolves to an existing ticket file
- User gets core Done output + table: ID / state / SHA / blocker
- Each hard stop has exact next human action, one line

## Anti-patterns — code layer

Core list, plus:

- Parent edits app code
- Commit before ship terminal `locally-verified`
- Skip TDD when ticket defines it
- Pass worker the index or a sibling ticket instead of its own ticket file path
- Worker reads sibling tickets to fill a gap instead of reporting the plan defect
- Plan at implementer tier, then burn `deep` workers rescuing vague tickets
- Review at `standard`/`cheap`, or escalate every ticket to `deep` "to be safe"
- Open PR unasked / push to `main`
- Ask user anything after implementation started (re-confirm plan, "continue?", preference)
