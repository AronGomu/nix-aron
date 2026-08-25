# make-aron-v2 — advisor fanout

Read by parent at chain step 8. Sidecar to `SKILL.md`.

Advisors run **after every deterministic gate is green**. Cheap checks that cannot be argued with go first; expensive probabilistic judgment goes last, on what is left.

## Hard rules

- Every advisor is **read-only**. No edit, no commit, no stage, no format. A findings report is its only output.
- Every advisor is **fresh context**, 1 dimension, dispatched in parallel batches.
- Model + effort are **hard-set in each advisor file frontmatter**. Set on spawn where the harness allows; always restate in the prompt. Never downgrade — cheap reviewers rubber-stamp.
- Spawn line: `Read ~/.agents/skills/make-aron-v2/advisors/{name}.md. Follow it fully.` Never paste the body.
- Output format is `references/findings-contract.md`. A malformed or missing report from a **fired** advisor is a coverage failure, not a clean scan.
- Advisors advise; gates block. Only `CRITICAL` / `HIGH` earn a fix pass (`B5`, one pass). `MEDIUM` / `LOW` -> ledger + residual risk.
- 2+ advisors returned findings -> dispatch `findings-reconciler` before any fix.
- Fix applied -> back to chain step 7 (final candidate gate). A fix may not certify itself.

## Dispatch matrix

Gate column = what in the diff makes the advisor fire. No gate match -> skip, and **record the skip with its reason** in the ledger. An unfired advisor and a clean advisor are different results.

| advisor                             | model / effort  | fires when the diff...                                                                                                           |
| ----------------------------------- | --------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `reviewer-code`                     | opus / high     | **always**                                                                                                                       |
| `reviewer-test-quality`             | opus / high     | **always** (tests exist by construction)                                                                                         |
| `reviewer-authz`                    | opus / high     | adds or changes a server entry point                                                                                             |
| `reviewer-security-regression`      | opus / high     | touches auth, secrets, input handling, serialization, file paths, shell, SQL                                                     |
| `reviewer-contracts`                | opus / high     | crosses client/server, route/schema, IPC, OpenAPI, tRPC, DTO, generated client; or changes a shared type / shared component prop |
| `reviewer-boundary-validation`      | opus / high     | accepts external input — request body, query, env, file, message, third-party payload                                            |
| `reviewer-concurrency`              | opus / high     | adds mutations, jobs, queues, webhooks, transactions, retries, idempotency, read-modify-write, state transitions                 |
| `reviewer-data-integrity`           | opus / high     | writes persisted data, migrates schema, deletes rows, changes a uniqueness/ownership rule                                        |
| `reviewer-dependencies`             | opus / high     | changes a manifest or lockfile                                                                                                   |
| `reviewer-perf`                     | sonnet / high   | touches a hot path, a query, a loop over data, render path, startup                                                              |
| `reviewer-observability-coverage`   | sonnet / high   | adds an integration boundary, async work, error path, job, webhook, external call                                                |
| `reviewer-error-boundaries`         | sonnet / high   | adds a failure path, async call, or UI that can render an error                                                                  |
| `reviewer-loading-states`           | sonnet / high   | adds async UI — route data, query hook, mutation, submit button, polling                                                         |
| `reviewer-accessibility-regression` | sonnet / high   | mutates interactive UI — button, form, dialog, menu, custom click target, focus, error message                                   |
| `reviewer-client-bundle`            | sonnet / high   | adds a client-side import, dependency, asset, or moves code across a server/client boundary                                      |
| `utility-finder`                    | sonnet / medium | introduces a new helper/util/component — one dispatch per new symbol                                                             |
| `findings-reconciler`               | opus / high     | 2+ advisors returned findings                                                                                                    |
| `integration-verifier`              | opus / high     | ticket spans 3+ subsystems, or changes persistence **and** a runtime/client boundary                                             |

## Order

```
1. dispatch every advisor whose gate fired — parallel, one batch
2. any advisor missing / malformed report -> re-dispatch once -> still bad -> blocked
3. 2+ advisors with findings -> findings-reconciler -> one disposition ledger
4. CRITICAL / HIGH -> roles/fixer.md, one pass (B5)
5. fixer touched code -> chain step 7, final candidate gate, from G1
6. MEDIUM / LOW -> ledger, surfaced in the final report as residual risk
7. integration-verifier fires only after steps 1-6 settle, on the combined tree
```

`integration-verifier` never fixes its own findings. A `FAIL` returns the work to `roles/fixer.md` and a **fresh** verifier runs after.

## Coverage record

Ledger must carry, per ticket:

```md
| advisor        | fired | verdict  | findings | disposition                            |
| -------------- | ----- | -------- | -------- | -------------------------------------- |
| reviewer-code  | yes   | findings | 2        | 1 fixed, 1 logged                      |
| reviewer-authz | no    | —        | —        | skipped: no server entry point in diff |
```

Every one of the 18 rows present, every skip carrying its reason. A missing row is a coverage failure.
