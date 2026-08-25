---
name: grill-me-aron
description: Relentless interview. Map goal as design tree, ask whole frontier per round as 1 HTML doc, loop until frontier empty and shared understanding reached.
triggers:
  - "grill me"
  - "ask questions to user"
  - "interview about"
  - "vague goal, help clarify"
---

# grill-me-aron

In : Take vague goal -> out: shared understanding out. Nothing silently assumed.

Model goal as **design tree** : every decision branches into related decisions.
**Frontier** = every open decision whose prerequisites are settled — question you can ask **without guessing** missing info.

## Restrictions

**CANNOT** be run in autonomous / non-interactive mode.

## Inputs

1. **Goal** — text, file path, or ongoing conversation. Missing -> ask user for it, then start.
2. (Optional) **out dir**. Not given -> `Const` default.
3. (Optional) **caller mode** — see [Caller override](#caller-override).
4. (Optional) **target spec level** — 0-8, see [Spec level target](#spec-level-target). Not given -> `Const` default.

## Const

| name        | value                                                           |
| ----------- | --------------------------------------------------------------- |
| Template    | `assets/round-template.html` (this skill dir)                   |
| Reference   | `assets/reference-round.html` (this skill dir)                  |
| Out dir     | `./artifacts/GRILL_{YYYY_MM_DD}_{title}/`                    |
| Round doc   | `{out dir}/round-{n}.html` — `round-1`, `round-2`, … `round-10` |
| Answer log  | `{out dir}/ANSWERS.md`                                          |
| Scout role  | `~/.agents/roles/scout.md`                                      |
| Max answers | 4 recommended answers per question, best -> worst               |
| Spec level  | default **2** — acceptance criteria. Caller may raise           |

## Process

Loop steps 2-6 per round. Round `n` starts at `n = 1`.

1. **Seed tree** — parse goal. Write root node + first-level branches. No file yet.
2. **Compute frontier** — list every open decision with settled prerequisites.
   Decision depending on another **open** decision belongs to a _later_ round. Drop it from this round.
   Decision "settled" in prose but **not writable at target spec level** -> still open. Ask the missing precision.
   Frontier empty -> jump to step 7.
3. **Resolve facts, don't ask them** — every frontier question needing environment fact (filesystem, deps, versions, API shape, tool output) -> dispatch `scout` child :
   `Read ~/.agents/roles/scout.md. Follow it.` Read-only, parallel OK.
   **Do not block.** Running scout = unsettled prerequisite -> its downstream question waits for next round. Ask rest of frontier now.
4. **Write round doc** — 1 HTML file, whole frontier, `{out dir}/round-{n}.html`. Shape per [Output](#output).
5. **Hand off** — give user the absolute path. State how many questions, which tree branches this round covers. Open file in the default browser (`xdg-open {out dir}/round-{n}.html`).
6. **Wait** — user answers whole round (pasted summary, edited file, or chat). Then :
   - append answers to `{out dir}/ANSWERS.md`
   - fold answers into tree : settled decisions push frontier outward, unblock dependants
   - fold in any scout report that landed
   - `n = n + 1`, back to step 2
7. **Close** — frontier empty **and** every settled decision writable at target spec level. Every branch visited. Write final `## Shared understanding` block to `ANSWERS.md` : goal, settled decisions, assumptions, out-of-scope.
   Present it. **Wait for user confirm.**

**DO NOT IMPLEMENT.** This skill produces understanding only.

## Spec level target

Stop condition = **"I can now write the spec at level N"**, not question count. Caller sets N.

Detail ladder, vague -> exhaustive : 0 intent · 1 brief · 2 PRD/acceptance criteria · 3 functional spec · 4 tech design (RFC/ADR) · 5 interface contract · 6 executable spec (tests) · 7 formal spec · 8 the code.

| N | Grill must extract | Round stops asking when |
| --- | --- | --- |
| 1 | who, pain, why now, success metric | goal + metric agreed |
| 2 (default) | user stories, Given/When/Then per story, edge cases | every story testable |
| 3 | screens, flows, states, error copy, permissions | every state reachable + named |
| 4 | architecture, data model, deps, alternatives rejected, rollout | every component + failure mode named |
| 5 | every boundary shape : type sigs, API routes + schemas, error codes, invariants, env/CLI names | nothing left where two implementers would pick different names or shapes |
| 6+ | verification strategy : which behaviors get property/contract/golden tests | every invariant has a check |

Level N implies every level below it. Cost is superlinear — never grill past the level the caller asked for.

**Caller conditions :**

- Caller states a level -> use it.
- Caller is `make-plan-v2` -> **level 5**. Tickets ship as interface contracts, so a naming or shape decision left open here becomes a parallel writer child inventing it. Grill it out now.
- Caller is `make-plan-aron` or unstated -> level 2.
- Level >= 5 : "backend decides" / "whatever fits" / "standard REST" are **not** settled answers. Push for the actual name, shape, or code. User genuinely has no preference -> you propose the concrete shape as a ranked answer and get it confirmed. Never leave it implicit.
- Level >= 5 : shape that is lookup-able (existing schema, lib signature, framework convention in the repo) -> **scout it**, do not ask.

## Output

### Round doc

Use `assets/round-template.html` as **exact document shell**. Replace every `{{PLACEHOLDER}}` :

| placeholder              | content                                                                 |
| ------------------------ | ----------------------------------------------------------------------- |
| `{{ROUND_TITLE}}`        | what this round decides, short                                          |
| `{{ROUND_LABEL}}`        | `Round {n} · {branch theme}`                                            |
| `{{ROUND_INTRO}}`        | 1-2 sentences : which decisions, why now, how to answer                 |
| `{{TREE_NODES}}`         | `.node` spans, `.active` on this round's nodes, `.arrow` between levels |
| `{{TECHNICAL_VISUALS}}`  | 1-2 `<figure>` with **inline SVG** — frontier graph + domain diagram    |
| `{{QUESTION_FIELDSETS}}` | 1 `<fieldset data-question="…">` per frontier question                  |

Constraints — non-negotiable :

- Preserve CSS, accessibility structure (`role="img"`, `aria-labelledby`, `<title>`, `<desc>`), summary JS.
- Single file, zero dependency, zero network fetch. Dark mode default.
- Emphasize human readability : heavy styling, graphs over prose. // for style replace this line by ref to make-html-aron skill in medium
- `data-question` unique per fieldset — summary JS keys on it.
- `assets/reference-round.html` = reference output. Match its density, not its content.

### Question fieldset

```html
<fieldset data-question="{question}">
  <legend>{n}. {question}</legend>
  <p class="why">{why this decision matters, 1 sentence}</p>
  <div class="choices">
    <label class="choice"
      ><input type="checkbox" value="{answer}" /><span
        ><b>{answer}</b><span class="rank">Recommended</span
        ><span class="detail">{tradeoff, 1 sentence}</span></span
      ></label
    >
    <!-- ranks: Recommended, Second, Third, Fourth -->
  </div>
  <label class="precision"
    >Precision or custom answer<textarea placeholder="{hint}"></textarea>
  </label>
</fieldset>
```

- 1 to 4 answers, ordered **best -> worst**. Never 0 answers.
- Checkbox, not radio — user may pick several or none.
- Empty selection is valid : textarea then **is** the answer.

### Copy summary

Template JS already emits, on `Copy answer summary` click :

```text
{ROUND_LABEL} — {ROUND_TITLE}

1. {question}
- {selected answer}
Precision: {textarea}
```

Keep it working. Never strip the button or the clipboard fallback.

### ANSWERS.md

```md
# Grill: {title}

## Round {n} — {branch theme}

| #   | Question | Answer | Precision |
| --- | -------- | ------ | --------- |
| 1   | ...      | ...    | ...       |

## Facts (scout)

- {fact} — source: {path|cmd}

## Shared understanding <!-- final round only -->

- Spec level: {N} — target reached
- Goal: ...
- Settled: ...
- Contracts: {sigs / schemas / routes / error codes, verbatim} <!-- level >= 5 only -->
- Assumptions: ...
- Out of scope: ...
```

## Rules

- **Whole frontier in 1 round.** Never dribble questions one at a time.
- **Target spec level is the stop condition.** Not round count, not question count. Below target -> keep going. At target -> stop, do not gold-plate.
- **1 round = 1 HTML doc.** Never 2 docs per round, never 2 rounds in 1 doc.
- **Facts are your job, decisions are user's.** Anything lookup-able -> scout it. Never ask user what you can read.
- Question you cannot ask without guessing missing info -> not frontier. Defer.
- Never assume silently. Unasked assumption -> write it in `ANSWERS.md` Assumptions.
- Never widen scope past the goal. Interesting-but-out-of-scope branch -> log, don't ask.
- No question already answered in a previous round. Check `ANSWERS.md` before writing round `n`.
- Wait for full round answers before recomputing frontier. No partial-round advance.

## Done when

- `{out dir}/round-{n}.html` exists for every round run, each opens standalone, each button copies
- `{out dir}/ANSWERS.md` holds every round's answers + scout facts
- frontier empty — every design-tree branch visited or explicitly logged out-of-scope
- every settled decision writable at target spec level — level >= 5 → `Contracts` block filled, verbatim
- `## Shared understanding` written, presented, and **user confirmed**
- caller has out dir path

## Early Stop

If user inputs : "stop grill" :

1. Auto answer all current and future questions with first recommended choice.
2. Finalize outputs document with updated answers.
3. Terminate grill session.
