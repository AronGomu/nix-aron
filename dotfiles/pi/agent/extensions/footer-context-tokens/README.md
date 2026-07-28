# Footer context tokens

Replaces Pikit footer context percentage label with cumulative input plus output tokens while preserving context bar and context-window limit.

Global settings exclude Pikit's packaged footer. This extension patches its `context_pct` segment, then loads footer itself. Requires pinned `@adrianapan/pikit@1.1.7`.
