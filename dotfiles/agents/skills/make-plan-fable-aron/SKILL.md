---
name: make-plan-fable-aron
description: Break goal into Markdown TDD ticket flowchart, then Fable-xhigh detail pass expands each ticket into atomic main-step/sub-step plan.
disable-model-invocation: true
---

# make-plan-fable-aron

Take goal in -> 1 markdown plan, 1 html plan, X ADR Records, X Architecture Design HTML Documents

## Pre-flight

If not already, read :
`~/.agents/skills/caveman/SKILL.md`

Lazy — read only when needed :
`~/.agents/skills/grill-me-aron/SKILL.md` — only if ambiguity left **and** caller did not say autonomous.
`~/.agents/skills/make-html-aron/SKILL.md` — only at step 7 / 9 (html plan, architecture docs).

## Job

1. Parse goal. Scope clear. Ambiguity → grill (load grill-me-aron). Caller said autonomous → safest in-scope default + log under `## Assumptions`. No silent assume either way.
2. Decompose goal → sequential tickets that build onto predecessors.
3. Each ticket = **1 commit-sized functional slice**. App **must compile successfuly** after ticket implementation.
4. Write **1 markdown plan index**. Caveman Ultra. Save `./ai_artefacts/PLAN_{YYYY_MM_DD}_{title}.md`. Index holds **no ticket body** — only links.
5. Write **1 markdown file per ticket**. Caveman Ultra. Save `./ai_artefacts/PLAN_{YYYY_MM_DD}_{title}/T{n}_{ticket-slug}.md`.
   Ticket dir = plan filename minus `.md`. Zero-pad nothing: `T1_`, `T2_`, … `T10_`.
6. **Detail pass**. Spawn 1 **Fable-xhigh detailer child per ticket** (see `## Step 6 — detail pass`). Each child inspects codebase + rewrites its ticket's `## Impl steps` → main steps + atomic sub-steps. Fold child reports back into tickets.
7. Write **1 html plan**. Use **make-html-aron** effort=high verbosity=lite. Save `./ai_artefacts/PLAN_{YYYY_MM_DD}_{title}.html`.
8. Write **X ADR Records markdown doc** about decisions from investigation. Caveman Lite. Save `./docs/ADR/XXX_ADR_{title}.md`.
9. Write, update, delete **X Architecture Design HTML Documents**. Caveman Lite. Save `./docs/{title}.html`.
10. Open every HTML doc written in steps 7 and 9 in the default browser (`xdg-open {file}.html`).

**DO NOT START IMPLEMENTATION**

## Step 6 — detail pass (Fable xhigh)

After **all** step-5 ticket files exist, spawn **1 detailer child per ticket**:

- Prompt: `Read ~/.agents/roles/detailer.md. Follow it.` + ticket file path + repo root + orchestrator brief (below).
- Model: **Fable, thinking xhigh** (e.g. `claude-fable-5:xhigh`). Fable unavailable → strongest frontier at xhigh or high thinking, tell user.
- Fresh context each child. Parallel OK — each child writes **its own ticket file only**.
- Child inspects codebase itself: exact paths, symbols, signatures, test harness, build cmds by **inspection**, never memory.
- Child rewrites `## Impl steps` → main steps + atomic sub-steps (template shape below). Deepens `Inputs` / `Test plan` / `Validation` with inspected facts.

**Orchestrator brief** — inline in each child prompt, per ticket. Child cannot read your head:

- Plan goal + success def
- Scope In / Out + this ticket's fence
- Assumptions in force
- Every design decision you made touching this ticket (relevant ADR content verbatim)
- Cross-ticket contracts this ticket consumes or produces — signatures verbatim
- Repo facts you already found (paths, symbols, cmds) — child verifies, not re-discovers

After children return: read each detailer report. Decisions / brief-vs-codebase conflicts / `TODO(user)` reported → fold into affected ticket files + `## Assumptions` in index **before step 7**.

## Granularity bar — write for a cheaper reader

Every ticket file must be executable by a mid-tier model with **zero design decisions left**:

- Exact paths for every file created or edited. No "the config file", no "the handler".
- Exact symbol names: functions, classes, types, endpoints, env vars, CLI flags, DB columns.
- Exact test names + exact assertions + exact run cmd.
- Exact cmds to run, copy-pasteable, with expected output or exit code.
- Impl steps = **main steps + sub-steps**. Main step = 1 functional outcome. Sub-step = **one action each**: 1 edit in 1 file at 1 location, or 1 cmd. "Wire up auth" is not a sub-step. "Add `require_user` dep to `POST /api/notes` in `api/notes.py`" is.
- Any choice with more than one reasonable answer → **you decide it here** and write the decision down. Never leave it to the worker.
- Signatures for anything crossing a ticket boundary — the next ticket's file must quote them verbatim.

Test: could a competent implementer with **no context beyond this one file** execute it without guessing? No → keep splitting or keep specifying.

## Ticket file rule — self-contained

Worker reads **its ticket file only**. Never the index, never sibling tickets.
So every ticket file must carry, inline: goal context, scope-out fence, what predecessors produced (paths / API names / behavior it consumes), full template below.
Duplication across ticket files is **correct**. A ticket that says "see plan" or "see T2" is **broken**.

## Index shape

```md
# Plan: {title}

## Goal

{1-3 sentence goal + success def}

## Scope

- In: ...
- Out: ...

## Assumptions

- ...

## Ticket flowchart

mermaid
flowchart TD
T1[T1: ...] --> T2[T2: ...]
T1 --> T3[T3: ...]
T2 --> T4[T4: ...]
T3 --> T4

## Ticket order

| ID  | Title | Depends | Commit outcome | File                                     |
| --- | ----- | ------- | -------------- | ---------------------------------------- |
| T1  | ...   | —       | ...            | `PLAN_{YYYY_MM_DD}_{title}/T1_{slug}.md` |

## Tickets

- [T1: {title}](PLAN_{YYYY_MM_DD}_{title}/T1_{slug}.md) — depends: none
- [T2: {title}](PLAN_{YYYY_MM_DD}_{title}/T2_{slug}.md) — depends: T1
```

Index carries **no** ticket body. Links + order table + flowchart only.

## Ticket file template — `T{n}_{slug}.md`

```md
# T{n}: {title}

**Plan:** `./ai_artefacts/PLAN_{YYYY_MM_DD}_{title}.md`  
**Depends:** T? / none  
**Commit outcome:** {one sentence — what works after commit}

## Context (self-contained)

- Goal: {plan goal, 1-2 sentences — restated, not linked}
- This slice: {where it sits in the whole}
- Out of scope here: {fence — what worker must not touch}
- Assumptions in force: {the ones this ticket depends on}

## Requirements

- ...

## Inputs

- files / APIs / state to read
- **From Depends:** {exact paths + API names + behavior predecessor left. Spell them out — worker cannot read T{n-1}}

## TDD

1. **Red** — write failing test(s) first. Name each test. Assert behavior not impl.
2. **Green** — min code pass test.
3. **Refactor** — only if needed. Keep green.

## Test plan

| Test | Input | Expect |
| ---- | ----- | ------ |
| ...  | ...   | ...    |

## Impl steps

- [ ] 1. {main step — one functional outcome}
  - [ ] 1.1 {atomic sub-step: exact file, exact symbol, exact code or cmd}
  - [ ] 1.2 ...
- [ ] 2. {main step}
  - [ ] 2.1 ...

## Outputs

- files touched
- public API / behavior change
- migrate / config if any

## Validation

- [ ] tests pass (list cmds)
- [ ] manual check (if UI/CLI)
- [ ] app functional — no broken path from this slice
- [ ] commit msg draft: `{type}({scope}): {why}`
```

## Rules

- First ticket **must frontload** every user interactions (e.g. package installation, account creation, linking API key, etc...).
- **TDD mandatory** each ticket. No "test later".
- **Detail pass mandatory** each ticket, before html plan. No ticket ships with flat Impl steps.
- Maximize building deterministic tests and validations.
- Ticket no testable behavior → merge.
- Prefer vertical slice over layer cake (no "all models then all UI").
- Paths, cmds, API names = exact. No fluff.
- Ref existing specs/ADRs by path. No dupe.
- 1 ticket = 1 file. Never two tickets in one file, never a ticket body in the index.
- Ticket file self-contained. Cross-ticket ref → inline the fact instead.

## Done when

- `./ai_artefacts/PLAN_{YYYY_MM_DD}_{title}.md` index written (path returned to caller)
- `./ai_artefacts/PLAN_{YYYY_MM_DD}_{title}/T{n}_{slug}.md` exists for **every** row of the order table, link resolves both ways
- index = goal + scope + assumptions + flowchart + order table + links only
- **every** ticket passed detail pass — `## Impl steps` = main steps, each with atomic sub-steps, detailer report folded back
- each ticket file = full template, self-contained, `- [ ]` on every Impl main step, sub-step + Validation line
- user can exec ticket top→bottom, commit each, ship functional app every step

Ambiguity → **grill first**. Do not write plan until user confirms shared understanding.

## Caller override

Caller may set **autonomous**. Then: no grill, no user confirm, no wait.

- Ambiguity → safest in-scope default, log under `## Assumptions`.
- Fact unknown + findable → `scout` child: `Read ~/.agents/roles/scout.md. Follow it.` Read-only. Never ask user a lookup.
- Fact unknown + only user has it (secret, account, business rule, budget) → `TODO(user)` in that ticket.
- `Done when` last line does not apply.

Caller may skip outputs (html plan / ADR / architecture docs) and substitute template vocab
(e.g. TDD → acceptance check, Test plan → Check plan, commit msg → deliverable name).
Section slots stay. Caller override wins over this file.
