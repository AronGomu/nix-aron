# Probe briefs

Canned `scout` briefs for planning. Each names a bug class a plan misses by default.

A probe is **not** a new role. Spawn the normal scout child — `Read ~/.agents/roles/scout.md. Follow it.` — then paste the brief below plus repo root and the concrete target. Read-only, fresh context, no user question, `scout.md` report shape.

Probes are **conditional**. Trigger absent → skip, no probe. Never run all three by reflex.

Every probe answers by **inspection** (`F1`): real reachable call site with `path:line`, or `not-found`. A surface inferred from a comment, a name, or a README is not a finding.

## P1 — surface parity

**Trigger:** a ticket adds or changes a field, column, or behavior on an entity that **already exists**.

Answer, for the named entity:

- **Schema anchor** — where the entity's shape is declared. This is the anchor for everything below.
- **Write surfaces (fan-out)** — every path materialising or mutating a row: create form, edit form, settings page, bulk/CSV import, duplicate/clone, from-template, API endpoint, admin override, **seed script, migration, fixture**. Classify each + note the actor.
- **Read surfaces (fan-in)** — every path displaying or emitting it: list, detail, shared card/table component, dashboard widget, export, API response/serializer, email/notification template. Note which fields each reads.
- **Shared consumers** — any read surface mounted from 2+ places. Name every mounting path.

Two rules that survive any stack:

- **Pre-existing rows.** Every column or shape change must answer "what happens to rows written before this commit?" No answer → the plan is missing a backfill.
- **Shared consumer.** A newly-required field on a shared consumer needs a named producer supplying it on **every** mounting path, not just the one the ticket touches.

Seed / migration / fixture surfaces count. They encode the shape at row-creation time; a new required field they don't supply breaks dev silently.

Exactly one write surface → say so and stop. Single-surface entity, no parity concern.

Planner folds the result into the ticket's `## Inputs` and `## Impl steps`, marking each surface **applies** or **explicitly skipped**. Silent partial ship is the failure this probe exists to prevent.

## P2 — runtime trace

**Trigger:** a ticket touches an integration that **already exists** — a side effect crossing a process, host, or library boundary.

Trace 4 links, each `path:line` or `MISSING — could not locate`:

1. **Trigger** — the action or event that starts it. Payload shape.
2. **Dispatch** — where it leaves the process. Exact endpoint / channel / queue / file path / library entry point, plus auth, headers, env vars.
3. **Receive** — the handler. Payload validation. Short-circuits before the real work (auth gate, idempotency check, flag).
4. **Observe** — where the effect becomes visible. DB row, log line, cache invalidation, external resource.

Also report **silent-failure swallow sites** on every link: `|| true`, empty `catch {}`, `>/dev/null 2>&1`, fire-and-forget with no error path. That is where the bug hides, and a test can pass because of one.

`MISSING` is a finding, not a gap in the report. Never guess a link. No observe link → the plan cannot prove that ticket done.

Library boundary in the trace → cite the installed source, not the `.d.ts` and not the README, or mark `library behavior assumed — not verified against source`.

Never include a literal secret value. Variable name + `path:line` only.

## P3 — sibling convention

**Trigger:** a ticket adds a **new instance of a recurring family** — modal, form, CLI subcommand, API endpoint, migration, test file, config block.

Pick 2–3 real siblings, spanning different areas, skipping stories / fixtures / scratch. Per sibling, report what the family actually does, each with `path:line`: entry shape, naming, error path, loading or in-flight state, keyboard or flag surface, teardown, test placement.

Then split the set: **consistent** across siblings (planner matches by default) vs **varies** (planner decides, and writes the decision in the ticket).

- Report what is there. Never recommend a primitive or pattern the project does not already use (`D3`).
- Sibling lacks the thing → report "not wired", never invent it because it feels right.
- Fewer than 2 siblings → say so and stop. No convention to extract; planner establishes it and documents why.

"Match existing conventions" left in a ticket is an undecided choice, i.e. a planner defect. This probe turns it into a written decision.
