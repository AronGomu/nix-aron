---
name: make-aron-v2
description: Implement tickets through a deterministic gate gauntlet
disable-model-invocation: true
---

# make-aron-v2

Ticket(s) in -> verified commit per ticket, or hard stop naming one gate id.

Rule ids `A1`-`L4` -> `~/.agents/GLOBAL_RULES.md`.

**Self-contained.** Reads nothing outside `~/.agents/skills/make-aron-v2/`.

## Pre-flight

Read now, both:

- `~/.agents/skills/make-aron-v2/GATES-FORMAT.md` — gate contract, thresholds, config schema, budgets.
- `~/.agents/skills/make-aron-v2/ADVISORS-FORMAT.md` — advisor dispatch matrix, fix policy.

## Inputs

1. **Ticket|plan path(s)**. Zero args -> **STOP**.

## Const

| name               | value                                                                                  |
| ------------------ | -------------------------------------------------------------------------------------- |
| Skill dir          | `~/.agents/skills/make-aron-v2/`                                                       |
| Roles              | `{skill dir}/roles/{specifier,coder,cleaner,hardener-auditor,test-writer,qa,fixer}.md` |
| Advisors           | `{skill dir}/advisors/*.md` — 18 files                                                 |
| Gate runner        | `{skill dir}/gates/run.sh <gate-id>`                                                   |
| Bootstrap          | `{skill dir}/bootstrap/detect.py`                                                      |
| Project config     | `./.make-aron/gates.json` — committed                                                  |
| Layer rules        | `./.make-aron/layers.json` — committed, optional                                       |
| Ledger             | `./.make-aron/runs/{run-id}.md` — gitignored                                           |
| Branch             | `feat/{first-ticket-slug}`                                                             |

## Process

1. **Bootstrap** — `./.make-aron/gates.json` absent -> `python3 {skill dir}/bootstrap/detect.py`. Every resolved cmd verified by running it once. Any cmd unresolvable -> **STOP**, print missing tool + install cmd. Never proceed with a gate disabled.
2. **Ledger** — write `./.make-aron/runs/{ISO}-{rand}.md` per `GATES-FORMAT.md#ledger`. Record base SHA. Update at every role and gate transition. Never reconstruct from memory.
3. **Flake guard** — `gates/run.sh G10`. Fail -> **STOP**. Suite non-deterministic -> every downstream gate lies: a random failure reads as a real failure, a random pass as real coverage. This stops on first run against most existing repos. Correct, not a bug.
4. **Branch** — clean tree check, `git checkout -b feat/{slug}`, `git push -u origin HEAD`.
5. **Per ticket, in order** — run the chain in `## Chain` below. One writer at a time, never parallel.
6. **Final report** — per `## Output`.

Parent orchestrates. Parent never edits. Children write.

## Chain

Fresh context per step. Step dies after its report. Spawn line is always:

```
Read ~/.agents/skills/make-aron-v2/roles/{role}.md. Follow it fully.
```

Model + effort are **hard-set in each role file frontmatter**. Set them on the spawn when the harness allows; always restate them in the prompt. Never downgrade to save tokens.

| #   | Step                 | Role file                   | Model          | Writes            | Exit gate            |
| --- | -------------------- | --------------------------- | -------------- | ----------------- | -------------------- |
| 1   | specifier            | `roles/specifier.md`        | sonnet / xhigh | tests + QA script | `G0` spec is RED     |
| 2   | coder                | `roles/coder.md`            | sonnet / xhigh | source            | `G1` `G2` `G8`       |
| 3   | cleaner              | `roles/cleaner.md`          | sonnet / xhigh | source            | `G3`                 |
| 4   | hardener-auditor     | `roles/hardener-auditor.md` | opus / high   | **nothing**       | report only          |
| 5   | test-writer          | `roles/test-writer.md`      | sonnet / xhigh | tests             | `G11`                |
| 6   | qa                   | `roles/qa.md`               | sonnet / high  | nothing           | `G9`                 |
| 7   | final candidate gate | parent                      | —              | —                 | `G1`-`G9`, recursive |
| 8   | advisor fanout       | `advisors/*.md`             | see file       | **nothing**       | findings ledger      |
| 9   | fixer                | `roles/fixer.md`            | opus / high   | source + tests    | back to step 7       |
| 10  | commit + push        | parent                      | —              | git only          | —                    |

**Step 3 and steps 4-5 never share a context.** Cleaner's goal is fewer branches; the cheapest way to close a test gap is often to add one. One agent holding both oscillates or satisfies neither. Cleaner first, always, including at the tail.

**Step 4 writes nothing.** Read-only auditor is the guard against closing a gap by deleting the construct under test or asserting on the very line the case was meant to pin.

**Step 7 is recursive.** Any fix that mutates code -> re-run from `G1`. A fix may not certify itself. Budget `B4` = 3 recursions.

## Gates

9 gates, all scripts, `exit 0` pass / `exit 1` fail / `exit 2` cannot run. Full contract + thresholds in `GATES-FORMAT.md`.

`exit 2` is never a pass. A missing tool reads as blocked, not clean.

| id    | checks                                    | blocks           |
| ----- | ----------------------------------------- | ---------------- |
| `G0`  | acceptance test exists and **fails**      | coder start      |
| `G1`  | typecheck + lint + build                  | all              |
| `G2`  | full suite green                          | all              |
| `G3`  | coverage on changed lines                 | cleaner exit     |
| `G6`  | dep-rules / module layering               | commit           |
| `G7`  | secrets, merge markers, debug residue     | commit           |
| `G8`  | the `G0` test now passes                  | commit           |
| `G9`  | executable system test                    | commit           |
| `G10` | suite run 2x, identical                   | run start        |
| `G11` | each new test fails against reverted impl | test-writer exit |

## Rules

- **Gates block. Advisors advise.** Only advisor `CRITICAL` / `HIGH` earn a fix pass. `MEDIUM` / `LOW` logged, shipped.
- **Zero user question.** Hard stop list only: secret/credential only user has · irreversible or prod action · gate `exit 2` · budget exhausted · push rejected on protected branch.
- Ambiguity -> safest in-scope default -> log in ledger `## Assumptions`.
- Every threshold is a number in `./.make-aron/gates.json`. Zero numeric thresholds in prose anywhere in this skill.
- `.make-aron/gates.json` and `layers.json` are **committed**. Thresholds are code, reviewed like code. Only `runs/` is gitignored.
- Never `--no-verify`, never `# type: ignore`, never skipped test, never commented assertion to pass a gate. Root cause or stop.
- Ticket missing a fact -> **plan defect**. Step reports `failed: plan defect — {fact}`. Parent inlines it into the ticket file, retries once.
- Commit only after step 7 green **and** ticket Validation pass. 1 commit per ticket minimum.
- Push every successful ticket commit to `origin` feature branch.

## Output

Per ticket, appended to ledger and to the final report:

```
T{n} {slug}  {done | blocked_gate:{id} | blocked_user | blocked_dep}
  G0  pass   `pytest tests/acceptance/test_t3.py` -> 1 failed (expected)
  G3  pass   changed-line coverage 1.0 over 7 changed fns
  G11 fail   2 new tests still pass against the reverted impl
  ...
  SHA: {sha}
  advisors: {n} run, {c} CRITICAL, {h} HIGH -> fixed | logged
```

Final message:

```
STATUS: [COMPLETE | INCOMPLETE]

| Ticket | State | SHA | Gate |
| ------ | ----- | --- | ---- |

Assumptions:
- ...

Residual risk:
- ...

@ if INCOMPLETE:
BLOCKING: {gate id} — {exact output, verbatim}
REQUIRED USER ACTION: {one line}
```

Every gate line carries the exact command and its real output. No paraphrase (`A3`).

## Done when

- Every ticket terminal before final report
- Every gate result in the ledger carries cmd + verbatim output
- Feature branch on remote carries every successful ticket commit
- `./.make-aron/gates.json` committed; every gate resolvable (`gates/run.sh {id}` never `exit 2`)
- `./.make-aron/runs/{run-id}.md` complete; scratch removed, ledger kept
- Each hard stop carries exact next human action, one line
