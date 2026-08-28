# Code smells

Read by `roles/cleaner.md` and `advisors/reviewer-code.md`.

No gate scores complexity. This file is the whole standard, and it is read by a person or an agent exercising judgment — there is no number to hide behind and none to game.

## Structure

- **Long file / long function** — files over `max_file_lines`, and any function you cannot hold in your head at once. Split **at a seam**: an independent concern, a separately-tested unit, a separately-imported export. A cohesive 400-line file with one concern is fine; an incoherent 200-line file is not.
- **Nested conditionals 3+ deep** — ternary chains, nested if/else, nested switch. Flatten with early returns, guard clauses, or a lookup table.
- **Flag argument** — a boolean parameter that selects between two behaviors. Two functions.
- **Tight coupling** — repeated cross-module logic, a module reaching into another's internals, an import that crosses a layer (`G6` catches the layer part).
- **Feature envy** — a function that uses another object's data more than its own.

## Duplication

- **DRY violation** — near-duplicate blocks encoding the same rule.
  **Trigger question for every flagged block: do these two call sites change for the same reason?** No -> leave them duplicated. Premature DRY couples unrelated callers and is worse than copy-paste.
- **Missed reuse** — a new helper that duplicates an existing util. Dispatch `advisors/utility-finder.md` per new symbol; do not guess.
- **Scattered enum literals** — the same string constant compared in five places. Name it once.

## Naming

- **Magic number / magic string** — name by **business meaning**. `MAX_RETRY_ATTEMPTS`, never `THREE`. A constant whose name restates its value is the same code with extra steps.
- **Non-self-describing name** — `data`, `handle`, `process`, `tmp`, `flag`, `doIt`. A boolean not named as a predicate (`isX`, `hasX`, `shouldX`).
- **Name that lies** — `getUser` that also writes, `validate` that also mutates.

## Efficiency

- **Unnecessary work** — redundant computation, duplicate I/O, N+1 query pattern.
- **Missed concurrency** — independent async ops awaited in sequence.
- **Hot-path bloat** — blocking work added to startup, per-render, or per-request paths.
- **Unbounded growth** — a structure that only ever grows, a listener never removed, a cache without eviction.

## Anti-Goodhart — the smells a cleanup pass creates

Every rule above pushes toward extraction. Extraction taken too far is worse than the branching it removed. These are findings **against** the refactor:

- **Shredded function** — helper used exactly once, named after its call site, carrying no independent meaning. Eight tiny helpers is worse code that merely looks tidier.
- **Not nameable without "and"** — an extracted function whose honest name contains "and" was cut at the wrong seam.
- **Split that scatters context** — a file split that forces the reader to hold two files open to understand one flow.

Cleaner must revert its own extraction when it hits one of these, and `G3` must still pass afterward. A ticket where both cannot hold is a signal the ticket is too big — report it as a plan defect rather than shredding.

## Never

- **NEVER** replace a magic number with a constant whose name restates the value.
- **NEVER** extract a shared helper from two near-duplicates without confirming they evolve together.
- **NEVER** split a file only because it is long.
- **NEVER** add a comment explaining what the refactor did. Git history holds the trail; `// extracted from X` rots immediately.
- **NEVER** refactor structural code without the covering test green first. `G3` guarantees it exists; run it before and after.
