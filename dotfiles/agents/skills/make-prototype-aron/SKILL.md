---
name: make-prototype-aron
description: Create, iterate, validate throwaway logic/state or visual UI/UX prototypes. Use when user wants to test a state model, data shape, interaction, or UI direction before production implementation.
disable-model-invocation: true
---

# make-prototype-aron

Design question → runnable throwaway prototype → PDDR → approved fixed prototype → impl spec.

## Pre-flight

Read `~/.agents/skills/caveman/SKILL.md` for style rules.
Lazy — if ambiguous: `~/.agents/skills/grill-me-aron/SKILL.md`.

## Inputs

1. **Question/feature** — state-model, logic, data-shape, interaction, or visual UI/UX question. Missing → STOP, ask for it.
2. (Optional) **Project root** — path. Missing → current dir. No project found → STOP, ask for valid path.
3. (Optional) **Caller mode** — see [Caller override](#caller-override).

## Const

| name              | value                                                       |
| ----------------- | ----------------------------------------------------------- |
| Working prototype | `{project_root}/artifacts/PROTOTYPE_{feature_name}.html`    |
| PDDR              | `{project_root}/docs/feature/PDDR-{feature_name}.md`        |
| Fixed prototype   | `{project_root}/docs/feature/PROTOTYPE_{feature_name}.html` |
| Final spec        | `{project_root}/artifacts/PROTOTYPE_SPEC_{feature_name}.md` |
| Validation phrase | `prototype approved`                                        |
| UI variants       | `3` default; `5` max                                        |

## Branch selection

1. **Logic** — question asks whether state model, transition, data shape, business rule, or API feels right. Build single standalone HTML with pure logic module, free-play actions, full state, guided scenarios.
2. **UI** — question asks what page/component/flow should look like. Build structurally different variants with switcher.
3. **Ambiguous** — backend/module context → Logic. Page/component context → UI. Record assumption at prototype top + PDDR.

Wrong branch wastes prototype. Resolve before code.

## Process

1. **Resolve scope** — state exact question, target users, cases, adjustable params, mocked behavior, target tech. Ambiguity remains → run 1 `grill-me-aron` round, max 4 questions. Caller says autonomous → safest default + PDDR assumption.
2. **Select branch** — apply [Branch selection](#branch-selection). Record branch + question visibly in prototype.
3. **Create dirs** — create `{project_root}/artifacts/` + `{project_root}/docs/feature/`. Failure → STOP, quote exact error.
4. **Choose UI host** — UI only. Existing web page plausibly hosts feature → prototype there using real read-only data/auth/layout, then mirror evaluator into standalone `Working prototype`. No host or non-web target → standalone only. Record choice + why. Logic always standalone.
5. **Build prototype** — follow [Logic prototype](#logic-prototype) or [UI prototype](#ui-prototype). Always write `Working prototype`; integrated UI additionally writes route files. Runnable check fails → repair once; still fails → STOP with blocker.
6. **Expose evaluation controls** — Logic: all legal/illegal actions + scenarios. UI: variant switcher + every within-variant adjustable param. Missing control → add before review.
7. **Start PDDR** — record branch, host choice, decisions, `CHOSEN`, `NOT CHOSEN`, rationale, params. Missing rationale → add before review.
8. **Present** — open standalone file or run project cmd + surface route and `?variant=` keys. Provide prototype + PDDR paths. Ask for feedback or exact validation phrase. Open/run fails → provide exact manual cmd/path.
9. **Iterate** — apply feedback, update PDDR, preserve current params when compatible. Logic feedback changes actions/scenarios/model. UI feedback changes variants/layout/params. Unclear req → focused question before edit.
10. **Validate decision** — list final state model/actions/scenarios or chosen UI variant + all params, values, units, ranges, states. Unsettled choice → reject approval, name unresolved item, return step 9.
11. **Accept approval** — continue only after user sends `prototype approved` + all choices fixed. Phrase absent → remain iteration loop.
12. **Freeze** — write accepted standalone artifact to `Fixed prototype`. Remove toolbar, switcher, drag handle, collapse btn, copy btn, debug UI. Logic keeps domain controls + approved walkthroughs. UI keeps chosen variant only. Mismatch → fix against approved state.
13. **Write final spec** — write `Final spec` from accepted prototype + PDDR. Logic: data shape, initial state, actions, transitions, invariants, invalid actions, scenarios. UI: hierarchy, dimensions, states, behavior, tokens, accessibility, target-tech mapping.
14. **Capture answer** — record verdict + settled question in PDDR/final spec. Explicit Git-capture req → preserve full prototype on throwaway feature branch, outside main. Never publish/push unasked.
15. **Verify outputs** — open working + fixed HTML, run integrated route if used, verify docs, confirm fixed artifact has no evaluation/debug UI. Failure → repair once; still fails → report failed.

## Logic prototype

1. Put actual model in one pure `<script>` module: reducer `(state, action) => state`, explicit state machine, pure fn set, or state-owning class/module. Choose shape fitting question.
2. Keep model free from DOM, `document`, storage, network, button handlers. Page calls model; model never calls page.
3. Render visible question, readable full relevant state, last change, domain-language action controls.
4. Add free-play btn per action. Expose illegal attempts when legality is part of question.
5. Add tabbed guided scenarios: happy path, awkward edge case, illegal attempt. Each reset to known initial state + uses real action btns.
6. Keep state in memory. Persistence question → scratch DB/file clearly named `PROTOTYPE_WIPE_ME`; never real DB.
7. No framework, bundler, server, tests, speculative generalization, or production HTML-shell reuse.

## UI prototype

1. Default `3` variants, max `5`. Each differs in layout, info hierarchy, primary affordance—not color/copy only.
2. Existing-page host preferred. Keep existing data fetching, params, auth above switch; swap rendered subtree only. Never wire prototype to real mutations; use stubs.
3. Name variants clearly: `VariantA`, `VariantB`, `VariantC`.
4. Select via `?variant=A|B|C`. Floating bottom-center switcher: previous, current label, next; wrap around; update URL through project router.
5. Support `←`/`→`; ignore keys while `<input>`, `<textarea>`, or `[contenteditable]` focused.
6. Gate integrated switcher from prod using project-equivalent env check. Standalone HTML must remain single-file, inline CSS + JS, zero network fetch.
7. Add draggable/collapsible toolbar for adjustable params. Final row: `Copy parameters` btn, right aligned. Copy every param name/value/unit/state; clipboard failure → selectable-text fallback.
8. Controls update prototype immediately. Preserve keyboard use, visible focus, semantic labels, sufficient contrast.
9. Native/terminal/embedded/game target → HTML simulation only; label mocked runtime behavior explicitly.

## PDDR

Append; never erase decision history. Use Caveman Lite.

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

1. Scope + out-of-scope.
2. Question + verdict.
3. Branch + target-tech mapping.
4. State/data model or screens/components/hierarchy.
5. Exact transitions/behavior or layout/dimensions/tokens/assets.
6. Fixed action/param table.
7. Mocked vs production behavior.
8. Invalid/error/empty/loading states.
9. Accessibility.
10. PDDR refs.
11. Impl acceptance checks.

## Rules

- Prototype answers one explicit question. New question → new prototype.
- Throwaway code clearly named + located close to target context.
- Skip tests, production error handling, persistence, abstractions unless question specifically tests them.
- Never claim mocked native/runtime/backend behavior is implemented.
- Never freeze while model, variant, or adjustable param remains unresolved.
- Never treat approximate visual approval as exact decision approval.
- Touch only prototype artifacts/route code unless user explicitly requests production impl.
- Do not promote prototype code directly to prod; rewrite validated decision under production constraints.

## Done when

- Branch + question explicit; assumption recorded when needed.
- Prototype runs via one cmd or double-click.
- Logic: pure model + full state + free-play + 3 guided scenarios.
- UI: 3 structurally different variants or PDDR rationale for fewer; shareable selector works.
- PDDR records chosen + rejected options with rationale.
- User sent exact `prototype approved` phrase.
- Every model/variant/param choice fixed; none unresolved.
- Fixed prototype matches approval, contains no toolbar/switcher/debug UI.
- Final spec makes production rewrite reproducible.
- Working prototype, PDDR, fixed prototype, final spec exist; integrated route paths recorded + runnable when used.

## Caller override

Caller may set **autonomous**. Then no grill or user confirm. Use safest defaults, append `## Assumptions` to PDDR, substitute internal approval after choices fixed. Never implement production feature without explicit req.

Caller override wins over this file.
