---
name: make-prototype-aron
description: Create, iterate, validate visual UI/UX prototypes as HTML. Use when user asks to prototype UI/UX for web or non-web tech.
disable-model-invocation: true
---

# make-prototype-aron

Feature description → validated HTML prototype, decision log, fixed prototype, impl spec.

## Pre-flight

Read `~/.agents/skills/caveman/SKILL.md` for style rules.
Lazy — read only when req stays ambiguous: `~/.agents/skills/grill-me-aron/SKILL.md`.

## Inputs

1. **Feature** — visual UI/UX feature description. Missing → STOP, ask for it.
2. (Optional) **Project root** — path. Missing → current dir. No project found → STOP, ask for valid path.
3. (Optional) **Caller mode** — see [Caller override](#caller-override).

## Const

| name              | value                                                          |
| ----------------- | -------------------------------------------------------------- |
| Working prototype | `{project_root}/ai-artifacts/PROTOTYPE_{feature_name}.html`    |
| PDDR              | `{project_root}/docs/feature/PDDR-{feature_name}.md`           |
| Fixed prototype   | `{project_root}/docs/feature/PROTOTYPE_{feature_name}.html`    |
| Final spec        | `{project_root}/ai-artifacts/PROTOTYPE_SPEC_{feature_name}.md` |
| Validation phrase | `prototype approved`                                           |

## Process

1. **Resolve scope** — identify target UI, user flow, adjustable params, mocked behavior, target tech. Ambiguity remains → run 1 `grill-me-aron` round, max 4 questions. Caller says autonomous → use safest defaults, record assumptions.
2. **Create dirs** — create `{project_root}/ai-artifacts/` and `{project_root}/docs/feature/`. Creation fails → STOP, report exact error.
3. **Build working prototype** — write standalone HTML to `Working prototype`. Represent target UI faithfully even when target tech is native, terminal, embedded, game, or other non-web tech. HTML fails standalone open → fix before continuing.
4. **Add toolbar** — expose every adjustable evaluation param. Missing adjustable param → add control before review.
5. **Start PDDR** — write initial decisions to `PDDR`, including `CHOSEN` and `NOT CHOSEN`. Decision lacks rationale → add it before review.
6. **Present** — open working prototype, provide both paths, ask for feedback or exact validation phrase. Open fails → provide absolute path for manual open.
7. **Iterate** — apply feedback to working prototype, update PDDR, preserve all current param values where compatible. Req unclear → ask focused question before edit.
8. **Validate params** — list final param names, values, units, ranges, states. Any variable unsettled → reject approval, identify unresolved vars, return to step 7.
9. **Accept approval** — continue only after user sends `prototype approved` and all vars are fixed. Phrase absent → remain in iteration loop.
10. **Freeze prototype** — copy accepted state to `Fixed prototype`; remove toolbar, drag handle, collapse btn, copy btn, debug UI. Visual or behavior mismatch → fix fixed file against accepted working state.
11. **Write final spec** — write `Final spec` from accepted prototype + PDDR. Missing reproducibility detail → add exact dimensions, states, behavior, assets, tokens, transitions, edge cases, accessibility, target-tech mapping.
12. **Verify outputs** — open both HTML files, check standalone behavior, verify docs exist. Any check fails → fix, rerun check.

## Working HTML

- Single standalone `.html`; inline CSS + JS; zero required network fetch.
- Prototype visual UI/UX, not production impl.
- Mock backend, device API, native runtime, or unavailable integration explicitly.
- Floating toolbar: 1+ rows, draggable, collapsible to draggable btn.
- Controls: sliders, toggles, inputs, selects, or exact control matching each adjustable param.
- Final toolbar row: `Copy parameters` btn, right aligned.
- Copy btn writes every param name + current value + unit/state to clipboard. Clipboard failure → show selectable text fallback.
- Param controls update prototype immediately.
- Keyboard use, visible focus, semantic labels, sufficient contrast.

## PDDR

Use Caveman Lite. Append; never erase decision history.

```md
# PDDR: {feature_name}

## Decision {n}: {topic}

- CHOSEN: {choice}
- WHY: {reason}
- NOT CHOSEN: {alternatives + reason}
- PARAMS: {exact values, ranges, units, states}
- DATE: {YYYY-MM-DD}
```

## Final spec

Include:

1. Scope + out-of-scope
2. Target tech mapping
3. Screens, components, hierarchy
4. Exact layout, dimensions, spacing, typography, colors, assets
5. Interaction + state transitions
6. Fixed param table
7. Mocked vs production behavior
8. Responsive/adaptive behavior
9. Accessibility
10. Edge/error/empty/loading states
11. PDDR decision refs
12. Impl acceptance checks

## Rules

- Prototype file always HTML, regardless of target tech.
- Never claim native/runtime behavior is implemented when HTML only simulates it.
- Never freeze while adjustable vars remain unresolved.
- Never treat approximate visual approval as exact param approval.
- Touch only prototype artifacts unless user requests project impl.

## Done when

- Working prototype opens standalone; toolbar controls every adjustable param.
- PDDR records all chosen + rejected options with rationale.
- User sent exact `prototype approved` phrase.
- Every param has fixed value/state; none unresolved.
- Fixed prototype matches approved state, contains no toolbar/debug UI.
- Final spec makes target-tech impl reproducible.
- All 4 output paths exist.

## Caller override

Caller may set **autonomous**. Then no grill or user confirm. Use safest defaults, append `## Assumptions` to PDDR, substitute internal approval after params fixed. Never implement production feature without explicit req.

Caller override wins over this file.
