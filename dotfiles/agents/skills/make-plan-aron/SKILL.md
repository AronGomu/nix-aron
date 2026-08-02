---
name: make-plan-aron
description: >
  Break goal into TDD functionnal and commitable ticket flowchart. Write full plan as markdown.
disable-model-invocation: true
---

# make-plan-aron

Take goal in -> 1 markdown plan, 1 html plan, X ADR Records, X Architecture Design HTML Documents

## Job

1. Parse goal. Scope clear. Ambiguity → ask **before** write plan, follow `grill-me-aron`. No silent assume. User validates every assumption.
2. Decompose goal → **ticket graph**. Edges = hard deps. Flow indicates tickets that can be parallelized.
3. Each ticket = **1 commit-sized functional slice**. App still works after ticket. No half-wire.
4. Write **1 markdown plan**. Save `./.tmp/IMPLEMENTATION_PLAN_{title}.md`. Caveman Ultra.
5. Write **1 html plan**. Emphasis human readability. Heavy use of styling and graphs. Caveman Lite. Save `./.tmp/IMPLEMENTATION_PLAN_{title}.html`.
6. Write **X ADR Records markdown doc** about decisions from investigation. Caveman Lite. Save `./docs/ADR/XXX_ADR_{title}.md`.
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

1. **Red** — write failing test(s) first. Name each test. Assert behavior not impl.
2. **Green** — min code pass test.
3. **Refactor** — only if needed. Keep green.

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
- Flowchart shows real deps only. No fake order.
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

## grill-me-aron

Interview user relentlessly until reach shared understanding. Map this as **design tree**: every decision branches into related decisions.

Work tree in **rounds**. **Frontier** is every decision without settled prerequisites — ask only questions you can ask without guessing missing information.
Ask whole frontier in 1 round.
Write 1 html doc with all questions.
Use `assets/round-template.html` as exact document shell. Replace every `{{PLACEHOLDER}}`; repeat documented question fieldset. Preserve CSS, accessibility structure, summary JS, and dependency-free single-file output. Save generated round beside working context unless user specifies path. `assets/reference-round.html` is reference output.
For each question : Present question, from 1 to 4 recommended answers from best to worst. Answers are checkbox. Under, have textarea "precisions".
At end doc, add copy summary button => copy in clipboard summary of all selected answers and related "precisions".
User can choose not to select anything, textarea act as custom answer.
Html doc must emphasis human readability. Heavy use of styling and graphs. Default to dark mode.

Wait for user answers all questions before next round.

Each round user answers reshapes tree — settled decisions push frontier outward and unblock questions that depended on them.
Recompute frontier and ask the next round.
Questions whose answer depends on another still open question belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's.
When frontier question needs fact from the environment (filesystem, tools, etc.), dispatch sub-agent to find it — don't ask user for anything you could look up yourself.
Don't block on it: running exploration is unsettled prerequisite. Only questions downstream wait for sub-agent to report — ask rest of frontier now.
_Decisions_ are user's — put each to them and wait.

Session done when frontier empty: every branch of design tree visited, nothing left silently assumed.
Do not act on it until user confirms you have reached shared understanding.
