# Uncached auto-compact

Automatically compacts the active Pi session after a completed LLM turn reports more than 200,000 uncached prompt tokens.

Uncached prompt usage is `usage.input + usage.cacheWrite`; `usage.cacheRead` is excluded. Provider usage arrives after the turn, so compaction cannot interrupt an in-flight request.

## Command

```text
/uncached-compact
```

Toggles the rule for the current extension runtime. It starts enabled; `/reload`, `/new`, and `/resume` start a new enabled runtime. Disabling while compaction is already running does not cancel that compaction.
