# Risk signals

Single source. Used by:

- `gates/crap.py` — file matches -> threshold drops from `crap` to `crap_risk`
- `ADVISORS-FORMAT.md` — dispatch matrix gates
- `roles/specifier.md` — a risk-signal ticket demands an executable QA script, never a manual checklist entry alone

Any **one** signal is enough. Signals never remove a gate; they only tighten a threshold or force an advisor to fire.

## Signals

- **Auth / permissions** — login, session, token, role, tenancy, ownership check, permission grant
- **Secrets** — key, credential, token issuance, env-var read, signing, encryption
- **Payments** — charge, refund, subscription, invoice, price, quota, billing webhook
- **External webhooks** — inbound handler, signature verification, replay window
- **Schema migration / persisted-data rewrite** — DDL, backfill, column drop, type change, index change
- **Destructive deletion of an external or public contract** — removing an endpoint, event, column, or exported symbol other systems consume
- **Background work** — job, queue, worker, cron, scheduler, retry, idempotency key
- **Outbound side effects** — email, SMS, push, file write, IPC, spawned process, third-party API call
- **Import / export** — bulk ingest, CSV/JSON import, data export, report generation
- **Caching / invalidation** — cache write, query invalidation, feature flag, analytics event
- **Concurrency-sensitive mutation** — read-modify-write, transaction, optimistic lock, state transition
- **Multi-subsystem** — the diff touches frontend + backend + persistence together

## Config

Patterns live in `./.make-aron/gates.json` under `risk_paths` when the defaults do not fit the repo:

```jsonc
"risk_paths": ["src/auth/**", "src/billing/**", "migrations/**", "src/jobs/**"]
```

Absent -> `crap.py` matches on path substrings derived from the signal names above (`auth`, `billing`, `payment`, `migration`, `webhook`, `job`, `queue`, `cron`, `session`, `token`, `permission`).

Substring matching is a heuristic and will miss a repo that names things differently. Set `risk_paths` explicitly on any project where it matters — a missed signal silently loosens a threshold.
