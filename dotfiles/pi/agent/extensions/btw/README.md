# btw — side questions

A replica of Claude Code's `/btw` ("by the way") feature for the pi harness.

Ask a quick question about the current conversation **without derailing the
task in progress**:

```
/btw what was that config file called again?
```

## How it works

- Spawns a throwaway, **read-only** `pi` process that `--fork`s the *current*
  session, so the side question sees the full conversation context.
- The fork is written to a temp `--session-dir` and deleted afterwards — the
  real session is never modified.
- `--no-tools` (and no extensions/skills/context files): the answer comes only
  from what's already in the conversation. It is, per the original, the inverse
  of a subagent — full context, zero tools.
- The answer appears in a **dismissible overlay** and is **not** added to the
  transcript.

## Overlay keys

| Key       | Action                          |
| --------- | ------------------------------- |
| `esc` `q` `space` `enter` | close             |
| `↑`/`↓` `k`/`j` | scroll                     |
| `PgUp`/`PgDn` | page                        |
| `←`/`→`   | step through earlier questions  |
| `c`       | copy answer to clipboard        |

The model/provider match the parent session's current model. Earlier side
questions are browsable in the overlay for the lifetime of the session and are
never persisted.
