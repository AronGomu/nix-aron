# Shared coding-task model routing

Canonical routing policy for implementation-skill child launches.

## Models

- M1. **Luna** = `openai-codex/gpt-5.6-luna`
- M2. **Terra** = `openai-codex/gpt-5.6-terra`
- M3. **Sol** = `openai-codex/gpt-5.6-sol`
- M4. **Astra** = `openai-codex/gpt-6-astra`

## Routing rules

1. Classify each ticket before spawn. Match its dominant task plus every explicit risk signal below.
2. Multiple matches → choose strongest model, then highest thinking level.
3. After a failed attempt, escalate exactly one model tier from the failed attempt: Luna → Terra → Sol → Astra. Keep the failed attempt's thinking level unchanged. At Astra, stay on Astra with the same thinking level. For failure retries, this rule overrides task reclassification and the table's `Escalate if needed` column; existing retry limits still apply.
4. Caller must pass exact model and thinking through supported spawn controls. In Pi, use `model: "provider/model:thinking"` on every launch; a separate top-level `thinking` field is not an execution override. Agent frontmatter is fallback only; prompt text cannot switch an already-started model.
5. Worker prompt must include: `Routing: {matched row} → {provider/model}, thinking {level}`.
6. Child verifies routing line against ticket before edits. Mismatch → report `failed: routing mismatch`; do not implement.

## Pi launch contract

- P1. Before delegation, discover executable agents with `subagent({ action: "list" })`. Agent role selects tools/prompt, not model tier. Classify the task using this table; pass explicit model/effort for every single, parallel, and chain child. Non-coding tasks outside the table require an explicit justified route; never silently inherit the parent model.
- P2. Set `context: "fresh"` explicitly. Supply bounded task context, relevant paths, and validation commands. Use `fork` only when inherited history is necessary; record why.
- P3. Verify the selected provider/model is registered and supports the requested thinking level. Unavailable model/effort → report blocked; no silent substitution, effort downgrade, or automatic fallback to another tier. Read effective launch metadata when available; a `Routing:` prompt line alone is not runtime proof.
- P4. Failure escalation requires a new launch, not `resume`. Keep the same role, workspace, and thinking level; hand off changed files, failed commands/output, and retry count. Wait for the previous writer to finish before launching its replacement. Only actual failed attempts escalate; a paused/stopped child is not automatically a failure.
- P5. This is persistent prompt-level policy, not hard runtime enforcement. Skill-local model/thinking defaults cannot override it. Record unavailable runtime verification rather than claiming enforcement.

Example: Simple CRUD, first attempt:

```json
{
  "agent": "worker",
  "context": "fresh",
  "model": "openai-codex/gpt-5.6-luna:medium",
  "task": "Routing: Simple CRUD → openai-codex/gpt-5.6-luna, thinking medium\nImplement the supplied ticket within its scope and run its validation commands."
}
```

After failure, use `openai-codex/gpt-5.6-terra:medium`, preserving the existing retry limit.

## Task table

| Coding task                             | Default model | Thinking | Escalate if needed |
| --------------------------------------- | ------------- | -------: | ------------------ |
| Rename / tiny edit                      | **Luna**      |      Low | —                  |
| Formatting / lint fixes                 | **Luna**      |      Low | —                  |
| Boilerplate generation                  | **Luna**      |      Low | —                  |
| Simple unit tests                       | **Luna**      |   Medium | —                  |
| Documentation / comments                | **Luna**      |      Low | —                  |
| Simple CRUD                             | **Luna**      |   Medium | —                  |
| Add form / validation                   | **Luna**      |   Medium | —                  |
| Simple API endpoint                     | **Luna**      |   Medium | —                  |
| Small frontend component                | **Luna**      |   Medium | —                  |
| Local bug with clear error              | **Luna**      |   Medium | Luna High          |
| Fix failing tests                       | **Luna**      |     High | Terra High         |
| Add integration tests                   | **Luna**      |   Medium | Luna High          |
| Small multi-file feature                | **Luna**      |     High | Terra High         |
| Dependency/library integration          | **Luna**      |     High | Terra High         |
| Code review / obvious bugs              | **Luna**      |   Medium | Terra High         |
| Deep code review / cross-file risks     | **Terra**     |     High | Sol High           |
| Security code review                    | **Sol**       |     High | Astra High         |
| Test planning / test selection          | **Luna**      |   Medium | Terra High         |
| Test writing / coverage expansion       | **Luna**      |   Medium | Terra High         |
| Test triage / flaky-test diagnosis      | **Terra**     |     High | Sol High           |
| Repo scouting / codebase reconnaissance | **Luna**      |      Low | Terra Medium       |
| Unknown-system scouting                 | **Terra**     |   Medium | Sol High           |
| Medium feature                          | **Terra**     |     High | Sol High           |
| Significant refactor                    | **Terra**     |     High | Sol High           |
| Complex multi-file feature              | **Sol**       |     High | Astra High         |
| Architecture change                     | **Sol**       |     High | Astra High         |
| Difficult debugging                     | **Sol**       |     High | Astra High         |
| Unknown root-cause bug                  | **Sol**       |     High | Astra High         |
| Performance optimization                | **Sol**       |     High | Astra High         |
| Concurrency / race condition            | **Sol**       |     High | Astra High         |
| Security-sensitive code                 | **Sol**       |     High | Astra High         |
| Database migration                      | **Astra**     |     High | —                  |
| Large repo refactor                     | **Sol**       |     High | Astra High         |
| Framework migration                     | **Sol**       |     High | Astra High         |
| Repo-wide API rename/change             | **Luna**      |     High | Terra High         |
| Greenfield small app                    | **Terra**     |   Medium | Terra High         |
| Greenfield complex subsystem            | **Sol**       |     High | Astra High         |
| Autonomous “fix until tests pass”       | **Luna**      |     High | Sol High           |
| Autonomous well-specified feature       | **Luna**      |     High | Terra High         |
| Autonomous ambiguous feature            | **Terra**     |     High | Sol High           |
| Long agentic session, repetitive work   | **Luna**      |     High | Terra High         |
| Long agentic session, hard reasoning    | **Sol**       |     High | Astra High         |
| Extremely hard task                     | **Astra**     |     High | —                  |
| Last-resort unsolved coding problem     | **Astra**     |     High | —                  |
