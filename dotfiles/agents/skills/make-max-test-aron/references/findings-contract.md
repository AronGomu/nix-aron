# Findings contract

Canonical output for every file in `make-max-test-aron/advisors/`. The parent applies `auto-fixable: true` items mechanically and surfaces the rest — this format is a **real API**, not cosmetic.

## Severity — exactly four levels

- **CRITICAL** — shipped as-is it leaks data, corrupts persisted state, or lets an unauthorized actor act. Missing auth / IDOR, logged secret, destructive migration on populated data.
- **HIGH** — breaks a real user path or a production invariant under normal use. N+1 on a hot route, optimistic update with no rollback, unverified webhook, blank-screen error path, assertion-free test on changed logic.
- **MEDIUM** — noticeable but non-catastrophic correctness / UX / perf degradation, or latent until scale or an edge condition hits.
- **LOW** — polish, consistency, defense in depth. Safe to defer, worth recording.

Never invent `INFO`, `NIT`, `HIGH IMPACT`. Fold into the four.

Only `CRITICAL` and `HIGH` earn a fix pass.

## `auto-fixable` — required on every finding

- `true` — mechanical, context-free edit the parent applies without judgment. Add `disabled={isPending}`, add an accessible name to an icon button, named-import swap, rename a single-file local.
- `false` — needs domain judgment or could make things worse if guessed. Auth-check placement, optimistic-rollback shape, any structural refactor, any test-strengthening.

In doubt -> `false`. An advisor with zero mechanically-applicable findings still writes the field on every line — the parent must never guess whether a line is safe to apply.

## Template

```
## <advisor-name> scan — <N> findings

### CRITICAL — <count>
1. **<one-line defect>** — `<file>:<line>`
   - Failure: <concrete inputs/state -> wrong result, crash, leak, or unmet criterion>
   - Fix: <concrete fix, using the project's existing helpers>
   - auto-fixable: <true|false>

### HIGH — <count>
...
```

Omit empty severity groups. Reply with **only** the report — no preamble, no summary paragraph.

## Zero-findings sentinel

Exactly one line, nothing else:

```
No <concern> issues detected.
```

e.g. `No authz issues detected.` So the parent can detect a clean scan unambiguously and tell it apart from a truncated report.

## Finding bar

A finding names a **concrete failure**: inputs or state -> wrong output, crash, leak, or an unmet ticket criterion. Cannot name the failure -> not a finding, cut it.

Style preference, naming taste, "I would have done it differently" -> not a finding. Cut.

Outside the ticket's scope -> not a finding. At most one line under `Residual risk:`.

Clean is a valid, expected result. Never manufacture findings to look useful.

## Universal NEVERs

- **NEVER edit a file.** Read, report. The parent or `roles/fixer.md` writes.
- **NEVER ask the parent or the user a question.** Unknown -> state the unknown in the finding.
- **NEVER report a finding without `file:line` and a concrete fix.**
- **NEVER pass something because a suite is green.** Green and empty is a finding, not a pass.
