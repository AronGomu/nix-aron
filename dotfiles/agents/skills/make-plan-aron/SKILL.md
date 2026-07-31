---
name: make-plan-aron
description: >
  Break goal into TDD ticket flowchart. Write full plan as markdown.
  Each ticket = commitable functional slice. User-invoked only.
argument-hint: "Goal to plan"
disable-model-invocation: true
---

# make-plan-aron

Take goal in -> 1 markdown plan, 1 html plan, X ADR Records, X Architecture Design HTML Documents

## Job

1. Parse goal. Scope clear. Ambiguity → ask **before** write plan `grill-me-aron`. No silent assume. User validates every assumptions.
2. Decompose goal → **ticket graph**. Edges = hard deps. Flow indicate tickets that can be parralelized.
3. Each ticket = **1 commit-sized functional slice**. App still works after ticket. No half-wire.
4. Write **1 markdown plan**. Save `./.tmp/IMPLEMENTATION_PLAN_{title}.md`. Caveman Ultra.
5. Write **1 html plan**. Emphasis human readability. Heavy use of styling and graphs. Caveman Lite. Save `./.tmp/IMPLEMENTATION_PLAN_{title}.html`.
6. Write **X ADR Records markdown doc** about decision from investigation. Caveman Lite. Save `./docs/ADR/XXX_ADR_{title}.md`.
7. Write, update, delete **X Architecture Design HTML Documents**. Caveman Lite. Save `./docs/{title}.html`.

**DO NOT START IMPLEMENTATION**

## Doc shape

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

| ID  | Title | Depends | Commit outcome |
| --- | ----- | ------- | -------------- |
| T1  | ...   | —       | ...            |

## Tickets

### T1: {title}

...
```

## Ticket template (every ticket)

### T{n}: {title}

**Depends:** T? / none  
**Commit outcome:** {one sentence — what works after commit}

#### Requirements

- ...

#### Inputs

- files / APIs / state / prior ticket outputs

#### TDD

1. **Red** — write fail test(s) first. Name each test. Assert behavior not impl.
2. **Green** — min code pass test.
3. **Refactor** — only if need. Keep green.

#### Test plan

| Test | Input | Expect |
| ---- | ----- | ------ |
| ...  | ...   | ...    |

#### Impl steps

1. ...
2. ...
3. ...

#### Outputs

- files touched
- public API / behavior change
- migrate / config if any

#### Validation

- [ ] tests pass (list cmds)
- [ ] manual check (if UI/CLI)
- [ ] app functional — no broken path from this slice
- [ ] commit msg draft: `{type}({scope}): {why}`

## Rules

- **TDD mandatory** each ticket. No "test later".
- Ticket too big for 1 commit → split.
- Ticket no testable behavior → merge or kill.
- Prefer vertical slice over layer cake (no "all models then all UI").
- Flowchart show real deps only. No fake order.
- Caveman ultra in plan body OK. Code/test names/cmds exact.
- Paths, cmds, API names = exact. No fluff.
- Unknown fact → mark `TODO(user)` or ask. No invent.
- Ref existing specs/ADRs by path. No dupe.

## Done when

- `./.tmp/PLAN_{title}.md` written
- flowchart + ordered tickets + full template each
- user can exec ticket top→bottom, commit each, ship functional app every step
- show list all files to delete

## Execution Rules

**NEVER DELETE FILES** => Let user do it
