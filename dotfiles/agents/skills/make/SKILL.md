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
3. Keep one writer per cwd/worktree. Run tickets sequentially; parallelize read-only research or review only.
4. Launch implementation asynchronously when supported. Use `steer` for live correction, `interrupt` for clear drift or blockage, and `resume` with narrowed instructions after diagnosis.
5. Inspect actual diff and validation output. Worker completion claim is not acceptance.
6. Accept, issue one targeted cheap repair when failure is localized with concrete diagnostics, or escalate.

Worker report must include state, changed files, commands with exit codes, validation evidence, assumptions, unresolved risks, and requested parent decision.

## Escalation

For architecture decisions, security-sensitive changes, migrations, destructive operations, concurrency, unknown root causes, broad context coupling, or previously failed hard work => Spawn Frontier model subagent to solve task.

Escalate after one cheap repair fails, worker uncertainty affects correctness, scope expands, validation repeatedly fails, worker exceeds assigned scope, or reviewers disagree on a blocker.

Do not repeat cheap attempts without new evidence.

## Completion

Implementation is complete only when orchestrator-inspected changes satisfy plan validation criteria and independent review is clean or every finding is dispositioned.

## Rules

Follow global rules for user-owned decisions and hard stops. Otherwise choose safest in-scope option and record it under Assumptions.

Never run parallel writers in one worktree.
Never continue optional polish after acceptance criteria pass.

Final report states decisions, changed files, validation evidence, model escalations, residual risks.
