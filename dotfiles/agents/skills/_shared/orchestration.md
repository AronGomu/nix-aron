# Orchestration core

Shared machinery for make implementation skills.
Caller own: domain gate, artifact shape, publish rule, pre-flight.
This file own: stance, loop, state, checkboxes, evidence, stop rules.

Caller must read this whole file plus `~/.agents/skills/_shared/model-routing.md` and obey both. Conflict → caller section wins, and caller must say so explicitly.

## Stance

Two phases. Question budget differs.

- **Plan phase** (caller Step 0, no plan yet) — interactive. Grill user, confirm shared understanding, confirm plan. Ask freely.
- **Implementation phase** (plan exists → first ticket onward) — autonomous. **Zero user question** except hard stop. Never return to plan phase.

Boundary is one-way: plan confirmed (or plan supplied as Arg1) → autonomous from there, no re-confirm, no mid-run check-in.

- Finish whole job this session.
- Ambiguity in implementation → safest in-scope default + log Assumption. Never ask.
- Parent = orchestrator. Children do work. Parent never does the work itself.
- One writer per cwd/worktree. Read-only fanout OK.
- Loop until verified done, or every remaining path hard-stopped.

## Input

`Arg1 = plan path` — **optional**.
No plan → caller Step 0 generate one first. Never start work planless.

Plan is **index + one file per ticket**:

```
./artifacts/PLAN_{date}_{title}.md          # index: goal, scope, assumptions, flowchart, order table, links
./artifacts/PLAN_{date}_{title}/T1_{slug}.md  # full ticket body, self-contained
./artifacts/PLAN_{date}_{title}/T2_{slug}.md
```

Parent parses the **index**: Goal, Scope In/Out, Assumptions, ticket order table (ID / Depends / file path), dep flowchart.
Parent reads a ticket file only to check dep-output wiring or verify a report. Worker reads **only its own** ticket file.

Index has ticket bodies inline (old single-file plan) → parent splits it into the layout above **before** step 5, then proceeds.

## Success criteria — before any work

Global E1 + E2. Here they live in the **progress file**: observable outcome, exact validation cmds, out-of-scope list.

## Validation state

Every ticket **and** every step carry state:

`pending | running | done | failed | blocked_user | blocked_dep | skipped`

- `running` on spawn. Terminal only after report read + evidence checked.
- `failed` → 1 repair loop → still bad → `blocked_user`.
- Dependants of blocked → `blocked_dep`. Never silent skip.
- Progress file = ticket state truth. **Ticket file** boxes = step state truth. Both current each loop.

## Checkbox protocol — mandatory

Global E7 governs flipping + evidence. Orchestration adds:

1. Boxes live in the **ticket file**, on every step **and sub-step**. Index holds no boxes.
2. Add boxes only. No scope rewrite.
3. Failed / blocked step → leave unchecked + record state in progress Log.

Shape:

```md
- [ ] T2.3 wire handler — validate: `pytest tests/test_handler.py` green
  - [ ] red: test_handler_rejects_empty fails
  - [ ] green: min impl passes
  - [ ] refactor: suite still green
```

## Auto-decide — no ask

| Choice           | Default                                                                       |
| ---------------- | ----------------------------------------------------------------------------- |
| Ambiguity        | safest in-scope; log under Assumptions                                        |
| Order            | plan Depends hard. Never skip dep                                             |
| Parallel writers | **Off** same cwd. Read-only fanout OK                                         |
| Worker           | fresh-context writer child, route per shared model table, one at a time        |
| Fact lookup      | fresh-context read-only child, GPT-5.6 Luna low, parallel OK                    |
| Final review     | fresh-context read-only fanout, GPT-5.6 Luna high, one dimension each           |
| Repair           | 1 repair loop per step, GPT-5.6 Sol xhigh, then blocked                         |
| Scope creep      | drop. Stay Scope In only                                                      |
| Resume           | read progress; skip `done`; retry `failed` once; halt `blocked_user`          |
| Missing plan     | generate via caller Step 0, **interactive** — grill, confirm, then autonomous |
| User ping        | plan phase: as needed. Implementation: never, except hard stop                |
| Docs             | update only if plan needs it or contract changed                              |

Caller adds: branch, commit, push, PR, gate depth, artifact paths.

## Hard stop — only stop reasons

Global G1 list → ticket state `blocked_user`. Not-a-stop = G2.
Job-specific addition: `TODO(user)` in plan blocks the slice.

**End run when:** all tickets terminal, **or** every remaining ticket is `blocked_user` / depends only on blocked chain. Then report. Do not spin.

## Loop — parent

```
0. Plan exists? No → caller Step 0 (generate, interactive, user confirms). Yes → load.
   From here on: autonomous. No further user contact except hard stop.
1. Parse index order table + Depends. Verify every row's ticket file exists. Missing → split/write it now.
2. In each ticket file: add missing `- [ ]` boxes, steps + sub-steps. Add missing validation criteria.
3. Init progress file. Write success criteria.
4. Caller pre-flight (branch / workspace / clean tree).
5. Topo-serial:
   a. Next ticket with all Depends = done.
   b. None unblocked → break.
   c. Spawn ONE worker subagent, context fresh.
   d. Await finish. Run-to-completion — never abandon mid-worker.
   e. Read report → update progress state. Worker flips its own ticket-file boxes; parent verifies they match the evidence.
   f. Repairable fail → one parent-directed retry worker, max 1.
   g. Still bad → blocked_user; mark dependants blocked_dep.
6. All terminal → fresh-context read-only review fanout on final diff / artifact set, one dimension per child.
7. Review blocker inside scope → one fix worker. Out of scope → log residual risk.
8. Parent final validate + report.
```

Parent never edits the work product while in this loop.

## Worker launch rules

## Model routing

`~/.agents/skills/_shared/model-routing.md` is canonical for coding-task model + thinking selection.

Rules:

- Classify every ticket before spawn.
- Multiple matching rows → strongest model, then highest thinking.
- Pass exact `model` and `thinking` spawn overrides. Agent frontmatter is fallback only.
- Include required `Routing:` line in every worker prompt.
- Planning remains GPT-5.6 Sol high.
- Failed-ticket repair always routes GPT-5.6 Sol xhigh.
- Fact lookup routes GPT-5.6 Luna low. Code review routes GPT-5.6 Luna high unless a stronger matching risk row applies.

Child behavior comes from caller skill plus spawn prompt. No external agent or role file.

Worker prompt **must** carry:

- job type: ticket implementation; child writes, parent orchestrates
- tier line: `Tier: {deep|standard|cheap} — {model+effort if harness cannot set it}`
- job slug + workspace/branch
- **ticket file path** — the one file it may read for the job. Do not paste the body, do not pass the index.
- Depends outputs it needs — parent inlines them into the ticket file's `From Depends:` before spawn, if reality drifted from plan
- success checks + exact validation cmds
- checkbox duty: add `- [ ]` if missing, continuous `- [x]`, never check without evidence
- publish policy (caller-defined)
- `no user ask — auto-decide + log Assumptions + report`

Rules: fresh context, `async:false` or awaited, one writer per cwd, children never spawn further orchestration.
Worker needs a fact not in its ticket file → that is a **plan defect**. Worker reports it; parent inlines the fact into the ticket file and retries. Worker never reads sibling tickets to patch the gap.

## Worker report — required shape

```md
## Ticket {ID} report

- State: done|failed|blocked_user
- Evidence: {cmd output | file path | observed behavior}
- Artifacts: {files touched / produced}
- Boxes checked: {T2.1, T2.2, ...}
- Validation: pass|fail + proof
- Assumptions: ...
- Blocker: {if any}
- Next parent action: continue|retry|halt-chain
```

Caller may add fields (e.g. `SHA:`, `Ship terminal:`).

## Progress file shape

```md
# Progress: {title}

- Goal: {one liner}
- Plan index: {path}
- Tickets dir: {path}
- Workspace: {branch|dir}
- Started: {iso}
- Updated: {iso}

## Success

- [ ] {observable outcome} — validate: {cmd|check}
- [ ] ...

## Status

| ID  | Title | File             | State | Evidence         | Note |
| --- | ----- | ---------------- | ----- | ---------------- | ---- |
| T1  | ...   | `.../T1_slug.md` | done  | `pytest` 12 pass | ...  |

States: pending|running|done|failed|blocked_user|blocked_dep|skipped

## Assumptions

- ...

## Log

- {iso} T1 start
- {iso} T1 done — {evidence}
```

## Safety

Global J1-J5 (git), H3-H5 (destructive writes), G3 (irreversible), D1-D6 (scope + style) apply. Orchestration adds:

- Parent never edits the work product. Children write.
- Publish only per caller policy. Caller override never widens it.

## Anti-patterns

- Parent does the work instead of orchestrating
- Skip Depends
- Ticket body inline in the index, or two tickets in one file
- Hand worker the index / sibling tickets / a pasted body instead of its ticket file path
- Spawn a child without job type, route, scope, constraints, or report shape
- Review below shared routing-table selection to save tokens
- Plan breakdown at anything below `deep`, then pay for it in failed tickets
- Give any review or fact-finding child write access, or let it touch the work product
- Ticket file that says "see plan" / "see T2" instead of inlining the fact

## Done output — to user

```text
job: {title}
state: complete|partial|blocked
plan: {path}
workspace: {branch|dir}
evidence:
- {check}: pass|fail — {proof}
tickets: {done}/{total}
blocked: {id: reason + exact next human action}   # if any
assumptions: ...
residual-risk: ...
progress: {progress path}
```

No essay. Evidence first.
