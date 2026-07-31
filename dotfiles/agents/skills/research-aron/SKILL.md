---
name: research-aron
description: Investigate question against high-trust primary sources and capture findings in Markdown file and html doc in the repo.
disable-model-invocation: true
---

Spin up **background agent** to do research. Keep working while it gather informations.

Tasks:

1. Investigate question against **primary sources** — official docs, source code, specs, first-party APIs — not secondary write-up of them.
   Follow every claim back to owner source.
2. Write findings to 1 Markdown file, cite each claim's source.
3. Save markdown file to `./.tmp/RESEARCH_{title}.md`.
4. Write findings in 1 report html doc. Must emphasis human readability. Heavy use of styling and graphs. Default to dark mode.
5. Save html doc to `./.tmp/RESEARCH_REPORT_{title}.html`.
6. Open html doc to default browser.
