---
name: make-plan-v2
description: Break goal into Markdown TDD ticket flowchart, then 1 dedicated Fable-low writer child per ticket writes each ticket at spec level 5 (interface contract) with atomic main-step/sub-step impl plan.
disable-model-invocation: true
model: opus
thinking: high
---

# make-plan-v2

Take goal in -> 1 markdown plan, 1 html plan, X ADR Records, X Architecture Design HTML Documents

## Pre-flight

If not already, read :
`~/.agents/skills/caveman/SKILL.md`

Lazy — read only when needed :
`~/.agents/skills/grill-me-aron/SKILL.md` — only if ambiguity left **and** caller did not say autonomous. Pass **target spec level 5**.
`~/.agents/skills/_shared/probes.md` — only when a probe triggers during decomposition (step 2). Canned scout briefs: surface parity, runtime trace, sibling convention.
`~/.agents/skills/make-html-aron/SKILL.md` — only at step 7 / 9 (html plan, architecture docs).
`~/.agents/skills/_shared/ADR.md` — only at step 8 (ADR records). Owns what is / is not an ADR, the durable-never-links-to-ephemeral rule, status lifecycle.

## Job

1. Parse goal. Scope clear. Ambiguity → grill (load grill-me-aron, model **Fable, thinking high**) with **target spec level 5** — grill-me-aron owns that bar, this skill only sets N. Caller said autonomous → safest in-scope default + log under `## Assumptions`. No silent assume either way.
2. Decompose goal → sequential tickets that build onto predecessors.
   Probe triggers hit here → read `~/.agents/skills/_shared/probes.md`, spawn the scout child (model **Sonnet, thinking high**), fold the result into the affected rows. Trigger absent → no probe.
3. Each ticket = **1 commit-sized functional slice**. App **must compile successfuly** after ticket implementation.
4. Write **1 markdown plan index**. Caveman Ultra. Save `./artifacts/PLAN_{YYYY_MM_DD}_{title}.md`. Index holds **no ticket body** — only links.
   **Step 4.5 — plan red-team pass**, risk-gated (see `## Step 4.5 — plan red-team`). Attacks the decomposition against the real repo **before** you spend a writer child per row. Gate: no `BLOCKED` open, every `KILL` / `MERGE` / `AMEND` folded into the index before step 5.
5. **Ticket write pass**. Spawn **1 Fable-low ticket-writer child per ticket** (see `## Step 5 — ticket write pass`). Orchestrator writes **no ticket body**. Each child creates + writes its own `./artifacts/PLAN_{YYYY_MM_DD}_{title}/T{n}_{ticket-slug}.md`, whole file, spec level 5.
   Ticket dir = plan filename minus `.md`. Zero-pad nothing: `T1_`, `T2_`, … `T10_`.
6. **Coherence review pass**. Every ticket written → spawn **1 fresh-context reviewer child** over the whole set (see `## Step 6 — coherence review pass`). It proves the tickets chain. Findings → **you** arbitrate + patch. Gate: no `blocker` open before step 7.
7. Write **1 html plan**. Use **make-html-aron** (model **Sonnet, thinking medium**) effort=high verbosity=lite. Save `./artifacts/PLAN_{YYYY_MM_DD}_{title}.html`.
8. Write **X ADR Records markdown doc** (model **Sonnet, thinking medium**) about decisions from investigation. Caveman Lite. Save `./docs/ADR/XXX_ADR_{title}.md`.
   Read `~/.agents/skills/_shared/ADR.md` now and follow it fully.
   **Durable never links to ephemeral.** ADR must not link `./artifacts/**`, `./.tmp/**`, plan, ticket, progress or feedback file — implementation deletes them. Cite commit SHA, tag, or tracked file, and inline the cited fact.
9. Write, update, delete **X Architecture Design HTML Documents**. Caveman Lite. Save `./docs/{title}.html`.
10. Open every HTML doc written in steps 7 and 9 in the default browser (`xdg-open {file}.html`).

**DO NOT START IMPLEMENTATION**

## Step 4.5 — plan red-team (fresh context, read-only, index-level)

Step 6 checks the tickets against **each other** — closed world. This checks the plan against the **repo and reality** — open world. A ticket set can chain perfectly and still build a thing that already exists, break an unchanged consumer, or land a migration in the wrong order. Nothing else in this skill catches that.

Runs **here**, not after step 5, because `KILL` and `MERGE` delete rows and every deleted row is one Fable-low child never spawned. The gate pays for itself in the most expensive phase.

**Gate — run it when any holds:** data migration or schema change · authz / auth surface · external API or paid service · touches more than one subsystem · deploys to prod · more than 6 tickets · caller asked for it. None hold → skip, log the skip under `## Assumptions`. A 4-ticket local plan does not need an adversary.

Spawn **1 reviewer child**: `Read ~/.agents/roles/reviewer.md. Follow it.` + dimension `plan-red-team` + target = index + repo root.

- Model: **Fable, thinking high**.
- **Fresh context, never fork.** Your reasoning for the decomposition is the thing under test.
- **Read-only.** Reports; never patches the index.
- Hand it: index, goal + success def, Scope In / Out, assumptions, locked user decisions, every repo fact you already found, base SHA if available. Missing input → it reports a coverage gap, it does not invent.
- Material is the order table, not ticket bodies — those don't exist yet. Verdicts are **per row**.

After it returns, **you** arbitrate:

- `KILL` / `MERGE` → delete or fold the row, fix `Depends` on every row pointing at it, redraw the flowchart.
- `AMEND` → patch the row. Ordering amendment → re-topo-sort.
- `BLOCKED` → user-owned decision. Autonomous → safest in-scope default + `## Assumptions`. Not autonomous → ask, then patch.
- `UNVERIFIED` that cannot change the decomposition → log under `## Assumptions`, proceed.

No re-review. One pass, arbitrate, move on — the index is cheap to fix and step 6 backstops the result. Verdicts that change a contract must reach the writer briefs in step 5; that is the whole point of running before the fanout.

## Step 5 — ticket write pass (Fable low, 1 child per ticket)

Once decomposition is done (index order table written, step 4), spawn **1 ticket-writer child per row**. One ticket = one dedicated child, from blank file to finished spec. No draft-then-detail two-pass.

- Prompt: `Read ~/.agents/roles/ticket-writer.md. Follow it.` + target ticket file path + ticket row + ticket file template + repo root + orchestrator brief (below).
- Model: **Fable, thinking low** (e.g. `claude-opus-5:low`). Unavailable → strongest frontier at low thinking, tell user.
- Fresh context each child. Parallel OK — each child writes **its own ticket file only**.
- Child inspects codebase itself: exact paths, symbols, signatures, test harness, build cmds by **inspection**, never memory.
- Child fills **every** template section, `## Interface contract` at level 5, `## Impl steps` = main steps + atomic sub-steps.

**Contracts are frozen before spawn.** Children run in parallel and cannot negotiate with each other. Every signature, schema, route, error code, env var, table column crossing a ticket boundary → **you decide it now**, verbatim, in both the producer's and the consumer's brief. Undecided shared contract at spawn time = plan defect, not child's job.

**Orchestrator brief** — inline in each child prompt, per ticket. Child cannot read your head:

- Plan goal + success def
- Scope In / Out + this ticket's fence
- Assumptions in force
- Every design decision you made touching this ticket (relevant ADR content verbatim)
- Cross-ticket contracts this ticket consumes or produces — signatures / schemas verbatim, binding
- Repo facts you already found (paths, symbols, cmds) — child verifies, not re-discovers

After children return: read each ticket-writer report. Decisions / brief-vs-codebase conflicts / `TODO(user)` reported → fold into affected ticket files + `## Assumptions` in index **before step 6**. Two children reporting contracts that disagree → **you** arbitrate and patch the losing ticket file yourself; never re-spawn both to haggle.

## Step 6 — coherence review pass (fresh context, read-only, whole set)

Ticket writers run in parallel and cannot see each other. A ruling you issue mid-pass reaches only the tickets written **after** it. So the set is **presumed broken until proven chained** — never assume your own arbitration propagated.

Spawn **1 reviewer child**: `Read ~/.agents/roles/reviewer.md. Follow it.` + dimension `cross-ticket coherence` + target = index + every ticket file + repo root.

- **Fresh context, never fork.** A fork inherits your belief that you already ruled correctly — that belief is the thing under test. Child re-derives every contract from the files.
- **Read-only.** Reports; never patches a ticket.
- Model: **Fable, thinking medium**. **One** child, not a fanout — findings are relational, so the whole set must sit in one head.

Child proves all six. Each failure is a `blocker`:

- **1. Declaration uniqueness** — every symbol / file / table / route / migration declared by **exactly one** ticket. Two tickets creating the same thing = compile error.
- **2. Producer ⇄ consumer verbatim** — each `Consumes` byte-matches the `Produces` of the ticket it depends on: name, type, nullability, ordering, units, error-code spelling. Paraphrase = break.
- **3. Handoff continuity** — ticket N's `## Validation` + `## Outputs` must not contradict ticket N+1's `## Inputs` + `## Context`. **The state N promises to leave is the state N+1 expects to find.** N ends "old endpoint deleted", N+1 opens "call old endpoint" → blocker.
- **4. Depends ⇄ index** — each ticket's `**Depends:**` header matches the index order table, both directions.
- **5. DAG** — acyclic, topologically valid. No ticket consumes a symbol a **later** ticket produces.
- **6. Green every commit** — no ticket deletes, renames or re-keys something a later ticket still uses unless that ticket owns the update.

Report = `reviewer.md` shape + one line per broken pair: `T{a} produces X — T{b} consumes Y`.

After it returns: **you** arbitrate every blocker and patch the **losing** ticket file yourself. **Producer owns the name; consumer bends.** Re-review **once** after patching. Still blockers → stop, report blocker + exact next human action. No third loop.

Clean first pass is a real result on a small plan. On a large one expect findings — that is the step paying for itself.

## Spec level — tickets ship at level 5

Detail ladder, vague → exhaustive: 0 intent · 1 brief · 2 PRD/acceptance criteria · 3 functional spec · 4 tech design (RFC/ADR) · **5 interface contract** · 6 executable spec (tests) · 7 formal spec · 8 the code itself.

Agent-driven coding sweet spot = **2 + 5 + 6**: acceptance criteria give the goal, contract gives the shape, tests give the verify loop. This skill writes all three, with **5 as the hard floor**.

Per ticket:

| Level | Section | Content |
| --- | --- | --- |
| 2 | `## Requirements`, `## TDD` | Given/When/Then, testable, impl-agnostic |
| 5 | `## Interface contract` | type sigs, OpenAPI/JSON Schema/protobuf/SQL DDL, error codes, invariants — machine-checkable, verbatim |
| 6 | `## Test plan`, `## Validation` | exact test names, exact assertions, exact cmds + expected output |

Level 5 test: could a codegen tool or a type checker consume it? "Returns the user" fails. `def get_user(uid: UserId) -> User | None` + `User` field list passes.

Cost is superlinear — level 7 (TLA+/proofs) only if the plan touches consensus, money, or safety. Not by default.

## Granularity bar — write for a cheaper reader

Every ticket file must be executable by a mid-tier model with **zero design decisions left**:

- Exact paths for every file created or edited. No "the config file", no "the handler".
- Exact symbol names: functions, classes, types, endpoints, env vars, CLI flags, DB columns.
- Exact test names + exact assertions + exact run cmd.
- Exact cmds to run, copy-pasteable, with expected output or exit code.
- Every boundary the slice creates or touches written as a **contract**, not prose: sigs, schemas, status codes, error strings, invariants (level 5).
- Impl steps = **main steps + sub-steps**. Main step = 1 functional outcome. Sub-step = **one action each**: 1 edit in 1 file at 1 location, or 1 cmd. "Wire up auth" is not a sub-step. "Add `require_user` dep to `POST /api/notes` in `api/notes.py`" is.
- Any choice with more than one reasonable answer → **you decide it here** and write the decision down. Never leave it to the worker.
- New instance of a recurring family (modal, endpoint, CLI subcommand, migration, test file) → inventory 2-3 existing siblings (`probes.md` P3), write the convention into the ticket as a decision. "Match existing conventions" is not a decision.
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

**Plan:** `./artifacts/PLAN_{YYYY_MM_DD}_{title}.md`  
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

## Interface contract (level 5)

Machine-checkable shapes this slice produces or consumes. Verbatim, copy-pasteable. No prose paraphrase.

- **Produces:** {type sigs / fn sigs / class shape / route + method + request schema + response schema + status codes / JSON Schema / protobuf / SQL DDL + migration name / CLI flags / env vars + defaults}
- **Consumes:** {same, verbatim as the predecessor produced it — binding, do not redesign}
- **Errors:** {exact type / code / message per failure path}
- **Invariants:** {pre/post conditions, nullability, ordering, idempotency, units}
- **Integration links** (only if this slice crosses a process / host / library boundary): trigger `{path:line}` → dispatch `{exact endpoint / channel / queue / file path + auth + env}` → receive `{handler + payload validation}` → observe `{DB row / log line / cache invalidation / external resource}`. Link not locatable → `MISSING`, never guessed. No observe link → this ticket's done is unprovable; add one.

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
- [ ] no silent-failure swallow on a path this slice adds — `|| true`, empty catch, `>/dev/null 2>&1`, fire-and-forget with no error path. List each site kept + why, or `none`
- [ ] app functional — no broken path from this slice
- [ ] commit msg draft: `{type}({scope}): {why}`
```

## Rules

- First ticket **must frontload** every user interactions (e.g. package installation, account creation, linking API key, etc...).
- **TDD mandatory** each ticket. No "test later".
- **1 dedicated ticket-writer child per ticket**, always. Orchestrator never writes a ticket body itself — it writes the index, the brief, and the frozen contracts.
- **Level 5 mandatory** each ticket. No ticket ships with prose-only boundaries or flat Impl steps.
- Cross-ticket contract undecided at spawn time → decide it before spawning. Never let parallel children invent the same signature twice.
- Maximize building deterministic tests and validations.
- Ticket no testable behavior → merge.
- Prefer vertical slice over layer cake (no "all models then all UI").
- Paths, cmds, API names = exact. No fluff.
- Ref existing specs/ADRs by path. No dupe.
- 1 ticket = 1 file. Never two tickets in one file, never a ticket body in the index.
- Ticket file self-contained. Cross-ticket ref → inline the fact instead.

## Done when

- `./artifacts/PLAN_{YYYY_MM_DD}_{title}.md` index written (path returned to caller)
- `./artifacts/PLAN_{YYYY_MM_DD}_{title}/T{n}_{slug}.md` exists for **every** row of the order table, link resolves both ways
- index = goal + scope + assumptions + flowchart + order table + links only
- **every** ticket written by its own ticket-writer child — `## Impl steps` = main steps, each with atomic sub-steps, writer report folded back
- **every** ticket has `## Interface contract` at level 5 — sigs/schemas verbatim, producer's shape == consumer's shape
- each ticket file = full template, self-contained, `- [ ]` on every Impl main step, sub-step + Validation line
- **red-team ran or was skipped on an evidenced gate** (step 4.5), every `KILL` / `MERGE` / `AMEND` folded into the index, zero `BLOCKED` open
- **coherence review ran** (step 6), **zero `blocker` open** — declarations unique, consumer shape byte-matches producer, ticket N's Validation/Outputs never contradict ticket N+1's Inputs/Context, `Depends:` matches index, graph acyclic
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
