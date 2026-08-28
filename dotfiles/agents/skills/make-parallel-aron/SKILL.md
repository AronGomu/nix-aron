---
name: make-parallel-aron
description: Parallelize implementation.
disable-model-invocation: true
---

# make-parallel-aron

You are orchestrator.

Plan in → ticket workers (ship) → commit + push each → done or hard-stop.

## Pre-flight

`Ship` skill locally installed.
If not -> install it from : https://github.com/AgentSystemLabs/core

## Job Orchestrator

Identify tickets available for implementation. For each ticket :

1. Create new worktree.
2. Spawn `Impl Agent` to implement ticket in worktree.
3. Wait for `Impl Agent ` report.
4. Merge worktree into main branch. You solve conflicts.
5. Update following tickets on new understanding.
6. Identify new tickets available and loop.

END = All tickets are implemented and merged into main.

## Rules

### FULLY AUTONOMOUS

- **Zero user question** except hard stop (core Hard stop list).
- Ambiguity → safest in-scope default, log under plan `## Assumptions`.
- Fact unknown + findable → `Scout Agent`.
- Fact unknown + only user can supply (secret, account, business rule) → Add to `## User TODO`

## Impl Agent

Model & Thinking = Same as orchestrator.

### Input

1. Ticket Markdown Plan

### Job

Run `ship` skill with `Ticket Markdown Plan` as input.
Add **NO USER INTERACTION**. Follow `Fully Autonomous` rule.

## Scout Agent

Model = Sonnet
Thinking = Medium
**READ-ONLY**

### Input

1. Search scope

### Job

1. Explore codebase.
2. Compile Findings into report.
3. Pass report to caller.

## Final Implementation Report

Single Markdown File.
Continuously updated throughout implementation.

Contains :
`## Ticket State List` : List of all ticket and implementation state.
`## Assumptions` : With dedicated chapter for each assumptions.
`## User TODO` : List of manual actions for user that cannot be done by agents.

Must be commited and pushed to main with last commit.

## Final cleanup

After last ticket is merged to main.
Delete plan index, matching ticket dir, progress file, impl scratch/temp/log files.

Keep only `Final Implementation Report`.
