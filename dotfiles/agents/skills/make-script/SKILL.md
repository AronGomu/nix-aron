---
name: make-script
description: >-
  Convert a plain text or Markdown video/talk script into a self-contained HTML
  teleprompter page (auto-scroll, adjustable text size, per-section read times,
  table of contents, reading progress bar). Use when the user says "make a
  script page", "turn this md into an html script", "teleprompter", "make-script
  on <file>", or points at a .md/.txt script and asks for a readable/presentable
  HTML version. Skip for: general docs-to-HTML conversion, blog posts, or slide
  decks.
---

> **User-question protocol:** Whenever this skill needs the user to pick between options or confirm an action, call the `AskUserQuestion` tool rather than printing numbered options as text.

# Turn a raw script into an HTML teleprompter

Input: one `.md` or `.txt` script. Output: `script.html` (or `<input-basename>.html`) next to the input — a single self-contained file, no external assets, no build step.

Template: `references/template.html` in this skill directory — the only source of layout, CSS and JS.

---

## Phase 1 — Read and parse

Read the whole input file. Do not skim — you must reproduce **every sentence verbatim**. This is a presentation layer, not an edit pass.

Identify:

| Source element | Meaning |
|---|---|
| `# Heading` (or first line / filename) | Document headline |
| `## Heading` | One `<section>` |
| `### Heading` | Sub-heading inside a section |
| Blank-line-separated block | One paragraph |
| Single newline inside a block | Line break inside that paragraph |

If the file has no headings at all (plain `.txt`), infer section boundaries from topic shifts and give each a short title. Tell the user you inferred them.

## Phase 2 — Fill the template

Copy `references/template.html` and replace the four placeholders:

- `{{TITLE}}` — browser tab title, short project name
- `{{BRAND}}` — top-bar label, short project name
- `{{SUBTITLE}}` — one small line under the brand, e.g. `video script · read-through`
- `{{HEADLINE}}` — the `<h1>`, the full document title
- `{{SECTIONS}}` — the generated body (below)

Everything else in the template — CSS, the top bar, the JS — is left untouched. The JS builds the table of contents, word counts, and per-section read times at load time, so **never hand-write a `<li>` in `#tocList`**.

### Section markup

```html
  <section id="s-SLUG">
    <h2>Section title</h2>
    <div class="cue">Section N</div>
    <p class="beat">Hook line that opens the section.</p>
    <p>Normal paragraph.</p>
    <p>Paragraph with<br>
    a soft line break.</p>

    <h3>Sub-heading</h3>
    <p>More paragraphs.</p>
    <p class="beat">Punchline that closes the section.</p>
  </section>
```

Rules:

- `id="s-SLUG"` — short kebab-case slug from the section title, unique per file.
- `.cue` is `Section N`, 1-indexed in document order. The last section is `Section N · final`.
- `p.beat` (accent-coloured) is for **hook and punchline only** — the line that opens a section and the line that lands it. At most two per section, often zero. Overusing it kills the signal.
- A single newline inside a source paragraph becomes `<br>` + newline + two-space indent, keeping the sentences in the same `<p>`. This is what makes a paragraph read as one breath.
- Escape `&`, `<`, `>` in the text. Preserve the author's typography as-is (`—`, `‑`, `×`, `?` spacing, quotes) — do not normalise it.
- Do not reword, reorder, merge, split, or fix the prose. Typos stay. If you spot something genuinely broken, report it after writing the file; don't silently patch it.

## Phase 3 — Verify

1. `grep -c '<section' out.html` matches the number of `##` headings.
2. `grep -c '{{' out.html` returns 0.
3. Word count is within ~1% of the source (`wc -w` the source vs. stripped HTML) — a big drop means you dropped content.
4. Open it: `xdg-open out.html`. Confirm the table of contents populates, the word/minute counts render, and auto-scroll runs.

Report the output path, section count, total word count, and estimated runtime at 150 wpm.

---

## Controls the page ships with

Space = play/pause auto-scroll · `←` `→` = scroll speed · `+` `−` = text size · `↑ Top` = back to top. Any wheel/touch/click stops auto-scroll so the reader can take over. `@media print` gives a clean printable version.
