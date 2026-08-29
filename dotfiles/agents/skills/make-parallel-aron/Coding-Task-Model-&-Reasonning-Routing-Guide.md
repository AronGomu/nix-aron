| Coding task                             | Default model | Thinking | Why                                        |
| --------------------------------------- | ------------- | -------: | ------------------------------------------ |
| Rename / tiny edit                      | **Luna**      |      Low | Cheapest possible execution                |
| Formatting / lint fixes                 | **Luna**      |      Low | Almost no reasoning needed                 |
| Boilerplate generation                  | **Luna**      |   Medium | Cheap, enough reliability                  |
| Simple unit tests                       | **Luna**      |   Medium | Repetitive/local work                      |
| Documentation / comments                | **Luna**      |      Low | Low reasoning requirement                  |
| Simple CRUD                             | **Luna**      |   Medium | Strong cost efficiency                     |
| Add form / validation                   | **Luna**      |   Medium | Local feature work                         |
| Simple API endpoint                     | **Luna**      |   Medium | Usually constrained scope                  |
| Small frontend component                | **Luna**      |   Medium | Good default for isolated UI               |
| Local bug with clear error              | **Luna**      |     High | Luna High has excellent $/success          |
| Fix failing tests                       | **Luna**      |     High | Iterative debugging suits cheap agent runs |
| Add integration tests                   | **Luna**      |     High | More context, but still structured         |
| Small multi-file feature                | **Luna**      |     High | Best Luna sweet spot                       |
| Dependency/library integration          | **Luna**      |     High | Unless API/docs are complicated            |
| Code review / find obvious bugs         | **Luna**      |     High | Cheap enough to inspect broadly            |
| Medium feature                          | **Sol**       |   Medium | Better reliability/context reasoning       |
| Significant refactor                    | **Sol**       |   Medium | Behavior preservation matters              |
| Complex multi-file feature              | **Sol**       |     High | Worth paying for deeper reasoning          |
| Architecture change                     | **Sol**       |     High | Global consequences                        |
| Difficult debugging                     | **Sol**       |     High | Better reasoning worth the extra cost      |
| Unknown root-cause bug                  | **Sol**       |     High | Search space is large                      |
| Performance optimization                | **Sol**       |     High | Requires causal reasoning                  |
| Concurrency / race condition            | **Sol**       |    XHigh | Hard reasoning problem                     |
| Security-sensitive code                 | **Sol**       |    XHigh | Failure cost is high                       |
| Database migration                      | **Sol**       |     High | Correctness across states matters          |
| Large repo refactor                     | **Sol**       |     High | Cross-file understanding                   |
| Framework migration                     | **Sol**       |     High | Many interacting changes                   |
| Repo-wide API rename/change             | **Sol**       |   Medium | Mostly systematic with some reasoning      |
| Greenfield small app                    | **Sol**       |   Medium | Architecture + implementation              |
| Greenfield complex subsystem            | **Sol**       |     High | Long planning horizon                      |
| Autonomous “fix until tests pass”       | **Luna**      |     High | Excellent when retries are cheap           |
| Autonomous well-specified feature       | **Luna**      |     High | Strong cost/output                         |
| Autonomous ambiguous feature            | **Sol**       |     High | Ambiguity favors stronger reasoning        |
| Long agentic session, repetitive work   | **Luna**      |     High | Best cost advantage                        |
| Long agentic session, hard reasoning    | **Sol**       |     High | Better reliability                         |
| Extremely hard / previously failed task | **Sol**       |    XHigh | Escalation tier                            |
| Last-resort unsolved coding problem     | **Sol**       |    XHigh | XHigh should be exceptional                |
