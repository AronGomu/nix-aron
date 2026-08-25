---
name: make-html-aron
description: generate html doc from input
triggers:
  - "make html"
  - "generate doc"
  - "explain me X"
---

# Make Html Aron

Rule ids `A1`-`L4` → `~/.agents/GLOBAL_RULES.md` (pi appends it to the system prompt; other harnesses read it).

## Auto-Triggers

- When more than 100 words of information must be communicated to user.
- Graphical information communicate better

## Input

1. Prompt and/or list of path to file.

2. Effort :
   - low - markdown style
   - medium - css styling, allow graphs & image (default)
   - high - heavy css styling & graphs & images

3. verbosity:
   - prose
   - caveman-lite (default)
   - caveman-ultra

## Pre-flight

If not already, read :
`~/.agents/skills/caveman/SKILL.md`

## Process

1. Analyse resources given.
2. If **high** : Find local and/or internet images for illustration.
3. Generate, then open the file in the default browser (`xdg-open {file}.html`). Every HTML this skill writes must end up open in the default browser.

**DO NOT ASK USER INPUT UNTIL HTML GENERATION IS COMPLETE !**

## Style

Dark mode by default.
Focus human readability.
Deliverable file per L3: standalone, inline CSS + JS, zero network fetch.

### Charts

Chart.js: each canvas in its own container div with explicit height + `width: 100%`, and `maintainAspectRatio: false` — else chart stops at intrinsic size instead of filling width.

### `artifact` fragments (L2/L4)

Fragment injected into pi's shell → no `<html>`/`<head>`, no reset, no CSS framework. Semantic HTML + shell vars `--bg` `--fg` `--muted` `--border` `--code-bg` `--accent` in scoped `<style>`. Never hardcode colors or fonts. Quiet document look: hairline borders, generous whitespace, one accent.

## Resources paths

### Local

~/brain/3_resources/assets/*
/mnt/data/Images/*
/mnt/data/Videos/*

### Online

- [Wojakland](https://wojakland.com/)
- [Know Your Meme](https://knowyourmeme.com)
- [Imgflip templates](https://imgflip.com/memetemplates)
- [GIPHY](https://giphy.com)
- [Tenor](https://tenor.com)
