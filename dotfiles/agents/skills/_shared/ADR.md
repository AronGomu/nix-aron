# ADR reference

What is and is not an Architecture Decision Record. Read before writing one.

Shared by every skill that emits `./docs/ADR/`. Caller owns numbering + register. This file owns definition, linking rule, lifecycle, immutability.

Form is Michael Nygard's: context → decision → consequences. One decision per file. Written once, at the moment of deciding.

## Write one only when

Any of:

- Expensive to reverse — persistence format, wire contract, vendored dependency, storage ownership, public API shape.
- Constrains future work — a boundary, budget, ownership rule, dependency direction.
- A competent newcomer would undo it by accident. The thing that looks like a bug and is deliberate.
- It reverses or narrows an existing ADR.

Test: six months on, someone about to change this asks **"why on earth is it like this?"** → ADR.
No ADR: bug fix, refactor adding no constraint, anything code + tests already state plainly, any choice with exactly one reasonable answer.

Most work needs no ADR. An ADR nobody would have questioned is noise that hides the ones that matter.

Two decisions → two ADRs. Split.

## What an ADR is

Four things, all of them:

1. **Context** — the forces at the time. Numbers, constraints, what was already true. Enough that the decision looks forced, not chosen.
2. **Decision** — what was decided, present tense, numbered clauses so a later ADR can supersede §3 without touching §1.
3. **Consequences** — what follows, *including the ones you dislike*. An ADR with only upside is marketing.
4. **Alternatives rejected** — the options considered and why each lost. This is the half a future reader actually needs; without it they re-propose the rejected option.

Disliked consequences, stated plainly, from real ADRs:

> `dist` grows to ~66 MB … That is the price of "any deck you can build, you can play". — ADR-043 §3

> The 100-entry window covers less wall-clock time for a player who reorders a lot. That is the trade the feedback asked for. — ADR-044

> At 1366×768 no-EMZ, board ≈886×735 (95.7% viewport height) **is accepted**. — ADR-019 §8

That last one is the whole point of the genre: it looks like a bug, it is deliberate, and the ADR is the only thing stopping the next person from "fixing" it.

## What an ADR is not

| Not a… | Smell test |
| --- | --- |
| Plan | Tells you what to do next. Has an order, a dependency graph, ticket IDs. |
| Ticket | Has `Impl steps`, `Inputs`, `Validation`, a commit message draft. |
| Task list | Has `- [ ]`. An ADR has zero checkboxes. |
| Progress report | Has state — "T3 done", "blocked", "remaining". Records activity, not reasoning. |
| Design doc | Describes the whole system. An ADR describes **one decision** and the alternatives it beat. |
| Tutorial | Second person imperative — "run this", "now add". |
| Changelog | Ordered by time, lists what changed, never says why. |

Sharpest cut: **tells you what to do next → plan. Tells you why things are the way they are → ADR.**

Tense test: an ADR is past and present — "the catalog is fetched, not compiled". A plan is future and imperative — "fetch the catalog". Future tense in a Decision section means you wrote a plan.

## Hard rule — a durable document never links to an ephemeral one

ADRs are durable. They are the permanent record, read months later by the person about to change the decision.

Plans, tickets, progress files, grill records, feedback files are **ephemeral** — scratch paper. `make-aron` deletes the plan and its ticket dir on purpose when a round ends (`_shared/cleanup-implementation.md`, End cleanup).

So an ADR must **never** link:

- `./artifacts/**` — plan indexes, ticket files, grill records, prototype specs
- `./.tmp/**` — progress files, scratch, logs
- feedback / review / round files rewritten between rounds
- PR comments, chat logs, anything outside the repo

Real damage, both modes:

- **Dead.** `> Plan: [../../artifacts/PLAN_2026_08_13_feedback_follow_up.md]` (ADR-019). Deleted at end of round. Link to nothing.
- **Worse — silently wrong.** `> Feedback: [../../feedback-decks.md] — Deck Builder 13, 14` (ADR-043). That file is rewritten each round. The link still resolves, to *different* content than the ADR was written about. A dead link is a visible error; a link that resolves to the wrong thing is a lie that looks correct.

### Cite this instead, ranked

1. **Commit SHA** — `` `a3b422f` `` or the full 40. Content-addressed: resolves to exactly the bytes the ADR was written about, forever. Carries the diff and the commit message with it. Never moves.
2. **Git tag** — `restructure-complete`. Immutable by convention, readable by humans. ADR-022 does this:

   > Fork point: commit tagged `restructure-complete` (T21, 2026-08-15). All domain branches start from this commit.
3. **Tracked file that outlives the round** — source, test, config, another ADR. Weakest of the three: the path survives, the content underneath it may not.

Why a SHA beats a path: a path is a **name**, and its content is whatever `HEAD` says today. A SHA is the content. `tests/unit/decks/deck-catalog-performance.test.ts` tells a reader where to look now; `a3b422f` tells them what was actually true when the decision was made, and why — the commit message is part of the citation.

Ephemeral → durable is fine, always. A ticket may link an ADR. Only the reverse is banned.

## Self-containment

An ADR must survive the deletion of every document it links to.

Test: **delete every link. Does it still explain the decision?** No → the missing reasoning belongs inline.

Links are corroboration, never load-bearing. If a reader must open a link to learn *why*, quote the fact in the ADR and cite the SHA as the receipt:

> The packaged snapshot holds **14,794** cards: 2.7 MB of masks, 7.1 MB of text … the deck-editor budget is 201,250 bytes.

That paragraph (ADR-043) needs no link. The numbers are in it.

## Status lifecycle

Header block, immediately under the title:

```md
# ADR-0NN: {Title}

> Status: proposed | accepted | accepted; planned | superseded
> Decided: YYYY-MM-DD
> Owners: {area}
> Relates: ADR-0NN ({one-line why}), …
```

- `proposed` — written, not agreed. Rare; most ADRs are written at the moment of agreement.
- `accepted` — decided and in force.
- `accepted; planned` — decided, implementation has not landed. Add `> Implemented: YYYY-MM-DD — {evidence}` when it does.
- `superseded` — a later ADR replaced it. Add `> Superseded: YYYY-MM-DD`. Body stays as written.

### Supersession

Two edits, both one line, never more.

New ADR declares what it replaces:

```md
> Supersedes: ADR-003 shell/chrome/geometry decisions
> Amends: ADR-037 §3 (position-blind history), ADR-038 §3 (autosave log)
```

Old ADR gains **one** line and is otherwise untouched:

```md
> Amended by [ADR-044](044_ADR_autosave_records_every_command.md): `reorder`/`sort` now **do** append to the autosave log; the "append nothing" clause in §3 is superseded.
```

Worked examples: ADR-037 and ADR-039. Both keep their original bodies intact; each carries one back-pointer naming the clause that fell.

Partial supersession names the clause (`§3`). Whole-file supersession sets `Status: superseded`. Numbered Decision clauses exist so this stays surgical.

## Immutability

An accepted ADR is not edited to reflect a new decision. A new ADR supersedes it.

- Allowed: fix a typo, repair a broken path, correct a factual error, add the `Amended by` back-pointer, add `Implemented:`.
- Not allowed: change what was decided, delete a rejected alternative, quietly soften a consequence.

Test: **would a reader who acted on the old text have been wrong?** Yes → new ADR. No → it is a correction, edit in place.

Amending in place destroys the only thing an ADR is for: the record of what was believed *at the time*, which is what makes the reasoning legible later.

## File shape

`./docs/ADR/{NNN}_ADR_{snake_case_title}.md` — number monotonic, never reused, zero-padded to 3.

```md
# ADR-0NN: {Title}

> {header block, above}

## Context
## Decision
## Consequences
## Alternatives rejected
```

`Alternatives rejected` is not optional. Nothing considered → the decision was not a decision, and needs no ADR.

## Done when

- One decision, stated in present tense, in numbered clauses.
- Context carries the numbers/constraints that forced it, inline.
- Consequences include at least one you dislike.
- Every rejected alternative names why it lost.
- Zero links to `./artifacts/**`, `./.tmp/**`, plan, ticket, progress or feedback files.
- Every external claim cites a SHA, a tag, or a tracked file — and the claim itself is quoted inline.
- Delete-every-link test passes.
- Header block: Status, Decided, Owners. Plus Supersedes/Amends when it replaces something, and the back-pointer added to what it replaced.
