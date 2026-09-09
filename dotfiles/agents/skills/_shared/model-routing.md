# Shared coding-task model routing

Canonical routing policy for implementation-skill child launches.

## Models

- **Luna** = `openai-codex/gpt-5.6-luna`
- **Astra** = `openai-codex/gpt-6-astra`

## Routing rules

1. Classify each ticket before spawn. Match its dominant task plus every explicit risk signal below.
2. Multiple matches → choose strongest model, then highest thinking level.
3. Previous failed attempt always matches `Extremely hard / previously failed task`.
4. Caller must pass exact `model` and `thinking` spawn overrides. Agent frontmatter is fallback only; prompt text cannot switch an already-started model.
5. Worker prompt must include: `Routing: {matched row} → {provider/model}, thinking {level}`.
6. Child verifies routing line against ticket before edits. Mismatch → report `failed: routing mismatch`; do not implement.

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
| Extremely hard / previously failed task | **Astra**     |     High | —                  |
| Last-resort unsolved coding problem     | **Astra**     |     High | —                  |
