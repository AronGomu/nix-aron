# make-aron-v2 — gate contract

Read by parent + every writing role. Sidecar to `SKILL.md`.

## Contract

```
gates/run.sh <gate-id> [--json]
  exit 0  pass
  exit 1  fail — findings on stdout
  exit 2  cannot run (tool missing, config missing, cmd unresolved)
```

`exit 2` is **never** a pass. Missing mutation engine reads as blocked, not clean scan. Parent hard-stops on `exit 2` and prints the missing tool + install cmd.

Every gate reads `./.make-aron/gates.json`. No gate hardcodes a command or a number.

## Gates

| id | name | script path | threshold key | scope |
| --- | --- | --- | --- | --- |
| `G0` | spec-red | `run.sh G0` | — | ticket acceptance test |
| `G1` | build | `run.sh G1` | — | project |
| `G2` | suite | `run.sh G2` | — | project |
| `G3` | coverage | `run.sh G3` | `coverage` | changed lines |
| `G4` | crap | `gates/crap.py` | `crap`, `crap_risk` | changed functions |
| `G5` | mutation | `run.sh G5` | `mutation` | diff vs base |
| `G6` | dep-rules | `gates/deprules.py` | — | changed files |
| `G7` | residue | `run.sh G7` | — | working tree + staged |
| `G8` | acceptance | `run.sh G8` | — | ticket acceptance test |
| `G9` | qa | `run.sh G9` | — | running system |
| `G10` | flake | `gates/flake.sh` | — | project, run start |
| `G11` | prove-test | `gates/prove-test.sh` | — | tests added this ticket |

### `G0` / `G8` — the spec pair

Same test, two moments. `G0` runs before the coder and **must fail** — a spec that passes before implementation encodes nothing. `G8` runs at commit and must pass.

`G0` passing -> `exit 1` with `spec is already green; it constrains nothing`.

### `G3` — coverage

Line coverage over **changed lines only**, from lcov. Threshold `coverage` (default `1.0`).

100% on a commit-sized diff is right and is what makes `G4` meaningful. Never point `G3` at the whole project — that is the unterminating-loop failure.

### `G4` — CRAP

```
CRAP(m) = comp(m)^2 * (1 - cov(m))^3 + comp(m)
```

`G3` pins changed-line coverage at `1.0` before `G4` runs -> first term is zero -> **`CRAP = cyclomatic complexity`**. The score is a pure complexity dial. That is why the threshold here is `crap` (default `6`) and not the published `30` — 30 is for triaging legacy at partial coverage, a different job.

File matches a `risk-signals.md` pattern -> threshold drops to `crap_risk` (default `4`).

`--source mutation` swaps the coverage term for per-function mutation score (`CRAP'`). Off by default; enable after `G5` is stable.

### `G5` — mutation

Diff-scoped, incremental, per-test coverage analysis. Never full-project inside the loop.

Threshold `mutation` (default `1.0`) computed as:

```
score = killed / (total - allowlisted)
```

**Equivalent mutants are undecidable**, so `1.0` needs an escape valve:

```jsonc
// ./.make-aron/equivalent-mutants.json — committed, reviewed like code
[
  {
    "file": "src/pricing.ts",
    "line": 42,
    "mutator": "EqualityOperator",
    "original": "i < 10",
    "mutated": "i != 10",
    "justification": "loop steps by 1 from 0; observationally identical",
    "added_by": "T4",
    "sha": "abc1234"
  }
]
```

Rules:

- `hardener-auditor` **proposes** entries in its report. It cannot write the file — it is read-only.
- Parent writes the entry only after it survives one `reviewer-test-quality` advisor pass.
- Entry without a prose `justification` -> `exit 1`.
- Cap `max_equivalents_per_ticket` (default `3`). Exceeded -> `blocked_gate:G5`. Growth of this file is where the gate goes to die; the cap is the alarm.

### `G6` — dep-rules

```jsonc
// ./.make-aron/layers.json — committed, optional
{
  "layers": ["domain", "application", "adapters", "ui"],
  "rules": [
    { "from": "domain",      "may_depend_on": [] },
    { "from": "application", "may_depend_on": ["domain"] },
    { "from": "adapters",    "may_depend_on": ["application", "domain"] },
    { "from": "ui",          "may_depend_on": ["application"] }
  ],
  "map": {
    "src/domain/**": "domain",
    "src/app/**": "application",
    "src/adapters/**": "adapters",
    "src/ui/**": "ui"
  }
}
```

Violation is **never** `auto-fixable`. Three legal repairs, all structural: invert the dependency · insert an interface · split the module. Gate names the violating edge; `fixer` picks the repair.

`layers.json` absent -> `exit 0` with `not configured` on stdout, and the final report says so verbatim. Silence is not a pass.

### `G10` — flake guard

Suite twice, same seed, same `TZ`. Compare exit code + pass/fail counts + failing test ids. Any drift -> `exit 1`.

Runs once per invocation, before any ticket. A mutation run on a flaky suite reads a random failure as a kill and a random pass as a survivor — the whole gauntlet becomes noise. Fix flakiness first: pin the clock, seed the PRNG, `TZ=UTC`, isolate DB state.

### `G11` — prove-test

For each test file added or changed this ticket:

1. `git worktree add` a temp tree at the ticket base SHA
2. copy the new/changed test files in
3. run **only** those tests in the temp tree
4. expect **FAIL**
5. remove worktree

Any test that passes without the implementation tests nothing. `exit 1` names it.

Temp worktree, never `git stash` — the working tree is not touched, so a crash cannot lose work.

This gate is Bob's "agents write fake tests to kill mutants" guardrail turned into an exit code. It is the reason `hardener-auditor` can be trusted to hand cases to `test-writer`.

## Config

```jsonc
// ./.make-aron/gates.json — generated once by bootstrap/detect.py, committed
{
  "version": 1,
  "stack": "node-ts",
  "detected_from": ["package.json", "vitest.config.ts", "tsconfig.json"],
  "cmd": {
    "typecheck": "npx tsc --noEmit",
    "lint":      "npx eslint . --max-warnings 0",
    "build":     "npm run build",
    "test":      "npx vitest run",
    "test_one":  "npx vitest run {file}",
    "coverage":  "npx vitest run --coverage --coverage.reporter=lcov",
    "complexity":"lizard {src} --csv",
    "mutation":  "npx stryker run --since={base} --reporters json"
  },
  "paths": {
    "src": "src",
    "lcov": "coverage/lcov.info",
    "mutation_json": "reports/mutation/mutation.json"
  },
  "thresholds": {
    "crap": 6,
    "crap_risk": 4,
    "coverage": 1.0,
    "mutation": 1.0,
    "max_file_lines": 400,
    "max_equivalents_per_ticket": 3
  },
  "determinism": { "TZ": "UTC", "env": { "SEED": "0", "PYTHONHASHSEED": "0" } },
  "qa": { "cmd": "npx playwright test tests/qa", "required": true }
}
```

`{file}` `{base}` `{src}` are the only substitutions. Bootstrap verifies every `cmd` by running it once; unresolvable -> `exit 2`.

### Tool matrix

| stack | complexity | coverage | mutation (incremental flag) |
| --- | --- | --- | --- |
| JS / TS | `lizard` | vitest/jest lcov | Stryker `--since=main` |
| Python | `lizard` or `radon cc -j` | `pytest --cov-report=lcov` | mutmut `--paths-to-mutate $(git diff --name-only main)` |
| Go | `lizard` or `gocyclo` | `-coverprofile` + `gcov2lcov` | `go-mutesting` + diff file list |
| Rust | `lizard` | `cargo-llvm-cov --lcov` | `cargo-mutants --in-diff` |
| Java | `lizard` or PMD | JaCoCo -> lcov | PIT `--changedSinceLastCommit` |
| PHP | `lizard` | PHPUnit clover -> lcov | Infection `--git-diff-filter=AM` |
| C# | `lizard` | coverlet lcov | Stryker.NET `--since` |

`lizard` is the default complexity tool — 12+ languages, one install (`pip install lizard`). Native tools are opt-in overrides in `cmd.complexity`.

## Layering — where each gate runs

| layer | runs | when | consumer |
| --- | --- | --- | --- |
| hook | format + lint + typecheck, changed file only | every file write | writing role, in its working set |
| coder exit | `G1` `G2` `G8` | end of step 2 | coder loop |
| cleaner exit | `G3` `G4` | end of step 3 | cleaner loop |
| hardener exit | `G5` `G11` | end of step 5 | test-writer loop |
| commit | `G6` `G7` `G9` + final candidate gate | before git | parent |
| advisors | LLM fanout | after every gate green | parent |
| run start | `G10` | once per invocation | parent |

Cheap deterministic first, while code is cheap to change. Expensive probabilistic last, on what is left.

**Hook layer.** Harness with a `PostToolUse` matcher on `Edit|Write` -> wire `cmd.lint` + `cmd.typecheck` scoped to the changed file, non-zero exit fed back. No hook support -> the writing roles carry the rule and `G1` catches drift late. Prose the agent must remember is the weakest form of this layer; wire the hook where you can.

## Budgets

| id | scope | limit | on exhaustion |
| --- | --- | --- | --- |
| `B1` | `G0` `G1` `G2` `G8` per role | 3 attempts | `blocked_gate:{id}` + last output verbatim |
| `B2` | `G4` cleaner | 5 attempts | `blocked_gate:G4` + function name + its CC |
| `B3` | `G5` hardener round (audit -> write -> re-run) | 3 rounds | `blocked_gate:G5` + survivors + proposed equivalents |
| `B4` | final candidate gate recursion | 3 | `blocked_gate:final` — pipeline oscillating, that is itself the finding |
| `B5` | advisor fix pass | 1, `CRITICAL`/`HIGH` only | rest -> residual risk |

Budget exhausted -> hard stop with a one-line next human action. Never a silent downgrade, never a threshold quietly relaxed.

## Anti-Goodhart

Not scriptable. Carried by `roles/cleaner.md`, enforced by advisor `reviewer-code`.

Complexity limits push agents to shred functions into meaningless helpers — eight private fns, CC 3 each, dashboard green, code worse. Guards:

- Extracted function must be nameable **without "and"**.
- `max_file_lines` capped, so shredding is not free.
- Helper used exactly once and named after its call site -> not an extraction. Revert it.
- Splitting a cohesive 400-line file scatters context. Split at a seam (independent concern, separately-tested unit, separately-imported export) or not at all.

## Ledger

```md
# make-aron-v2 run {run-id}

- Status: RUNNING | COMPLETE | BLOCKED
- Started / Updated: {ISO}
- Base SHA: {sha}
- Branch: {branch}
- Tickets: {paths, in resolved order}
- Config: ./.make-aron/gates.json  (stack: {stack})

## Assumptions
- ...

## Tickets

| ID | State | Step reached | SHA | Gate |
| -- | ----- | ------------ | --- | ---- |

## Gate log

- {ISO} T3 G4 pass — `gates/run.sh G4` -> `crap max 5.0 / threshold 6 over 7 fns`
- {ISO} T3 G5 fail — 3 survivors src/pricing.py:42,55,61

## Advisor findings

| advisor | severity | file:line | disposition |
| ------- | -------- | --------- | ----------- |

## Residual risk
- ...
```

Validate base SHA still matches before trusting a resumed ledger. Ledger is the evidence of record — the parent reads it to build the final report, never reconstructs from memory.
