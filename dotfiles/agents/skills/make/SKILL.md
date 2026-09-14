---
name: make
description: Implement plan with orchestrator and cheaper subagents.
disable-model-invocation: true
---

# make

## Pre-flight

Read `~/.agents/GLOBAL_RULES.md`.
Read `~/.agents/skills/_shared/model-routing.md` and use supported spawn controls for every subagent.
Run `~/.agents/skills/_shared/cleanup-implementation.md` start + end.

## Input

Plan.

## Job

You are ORCHESTRATOR and final decision-maker.

Do not implement code unless escalation rules require frontier takeover.
You may read files, inspect diffs, run tests, diagnose failures, review evidence, and steer workers.

Keep an authoritative task ledger: objective, worker, state, changed paths, validation, retry count, and escalation reason.

For each task:

1. Classify risk and dependencies before spawn.
2. Give one cheaper worker bounded scope, exact routing, acceptance criteria, validation commands, constraints, and required report shape.
3. Keep one writer per cwd/worktree. Run independent tickets in parallel when plan allows; serialize dependent tickets. Parallelize read-only research or review freely.
4. Launch implementation asynchronously when supported. Use `steer` for live correction, `interrupt` for clear drift or blockage, and `resume` with narrowed instructions after diagnosis.
5. Inspect actual diff and validation output. Worker completion claim is not acceptance.
6. Accept, issue one targeted cheap repair when failure is localized with concrete diagnostics, or escalate.

### 1. Final Implementation Report : `IMPLEMENTATION-REPORT-{name}.md`

Worker report must include state, changed files, commands with exit codes, validation evidence, assumptions, unresolved risks, and requested parent decision.

### 2. Detailed agentic session log : `AGENTIC-REPORT-{name}.html`

After implementation, invoke `make-html-aron` to generate then open standalone interactive HTML report via `xdg-open`.

Report must include:

- Summary cards (exactly five): wall time, summed active/compute time, human wait, total tokens split input/output/cache read/cache write, total cost including nested children, parallelism gain. Distinguish wall time from summed compute time.
- Per-model-and-thinking interactive table: resolved model, thinking level, calls, duration, token split, observed cost, errors, avg latency, captured time-to-first-token, tokens/sec, cost/successful task, retries/fallbacks. Group rows by resolved model + thinking level. Observed cost must come from captured billing telemetry for that route and usage; never infer it from thinking level alone.
- Per-task interactive table: task ID/type, agent, model, status, wall time, tokens, cost, tools. Types fixed to research/planning/implementation/review/validation; label inferred classification `inferred`.
- Agent hierarchy: children/task, nesting depth, peak concurrency, failed/stopped/timed-out tasks, fallback attempts.
- Efficiency/quality: tool success rate, repeated calls, retries, compactions, peak context, changed files/lines, test status, acceptance status, orphaned work, error timeline.
- Collection sources: Pi session JSONL, live extension lifecycle events for exact spans/UI wait/concurrency, pi-subagents results/artifacts, git/test evidence. Note post-session parsing limits.
- Presentation: Gantt/timeline with parent-child overlap; sortable/filterable/searchable tables; expandable event log with model/task/agent/tool/error filters; JSON export; local standalone HTML with inline CSS/JS, dark mode, zero network fetch.
- Security: redact secrets, credentials, PII, provider headers, raw payloads. Keep local-only unless explicit publish.

## Completion

Implementation is complete only when orchestrator-inspected changes satisfy plan validation criteria and independent review is clean or every finding is dispositioned.

Create PR in local forgejo serveur ready for review.

## Rules

Follow global rules for user-owned decisions and hard stops. Otherwise choose safest in-scope option and record it under Assumptions.

Never run parallel writers in one worktree.
Never continue optional polish after acceptance criteria pass.

Final report states decisions, changed files, validation evidence, model escalations, residual risks.

### Escalation

For architecture decisions, security-sensitive changes, migrations, destructive operations, concurrency, unknown root causes, broad context coupling, or previously failed hard work => Spawn Frontier model subagent to solve task.

Escalate after one cheap repair fails, worker uncertainty affects correctness, scope expands, validation repeatedly fails, worker exceeds assigned scope, or reviewers disagree on a blocker.

Do not repeat cheap attempts without new evidence.
