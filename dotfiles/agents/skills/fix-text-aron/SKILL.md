---
name: fix-text-aron
description: >
  Correct orthograph, grammer, syntax of given text or file.
---

# Fix Text

Rule ids `A1`-`L4` → `~/.agents/GLOBAL_RULES.md` (pi appends it to the system prompt; other harnesses read it).

## 1. Inputs

Required:

1. Source — pasted text, local file path, or public URL containing text.

Optional:

-. `intensity=<intensity_option>` — `word` (default) / `syntax` / `sentence` / `paragraph`

- `language=<language>` — force final text into target language. Preserving meaning, structure, formatting, names, URLs, code, and technical tokens.
- `overwrite=true` — Explicit approval to overwrite input file. Without it or false, write output beside source as `<stem>_fixed<ext>`.

Suggested command:

```text
/fix-text-aron intensity=<word|syntax|sentence|full> [language=<language>] [overwrite=true] <source>
```

Examples:

```text
/fix-text-aron intensity=word
[pasted text]

/fix-text-aron intensity=syntax notes/draft.md

/fix-text-aron intensity=sentence language=French notes/draft.md

/fix-text-aron intensity=full language=English overwrite=true notes/draft.md
```

Accepted intensities:

- `words`
- `syntax`
- `sentences`
- `full`

## 3. Intensity

### words

Fix word-level mistakes only:

- Clear spelling or typo errors
- Wrong inflection, agreement form, or conjugated form
- Clearly wrong word caused by confusion or typo, only when intended word is unambiguous
- Capitalization tied to corrected word

Do not add missing words, reorder words, alter syntax, rewrite phrases, or swap valid words for style.

### syntax

Apply `words` plus minimal grammar and syntax fixes:

- Add or remove missing/extra function words
- Fix word order
- Fix agreement, tense, articles, prepositions, pronouns, punctuation, fragments, and run-ons
- Make smallest edit needed for grammatical sentences

Do not rewrite a grammatical sentence for style or clarity.

### sentences

Apply `words` plus `syntax`. Rewrite part or all of individual sentences when needed for clarity, flow, concision, or natural phrasing.

Preserve meaning, facts, tone, detail, paragraph order, and overall structure. Do not add claims or remove substantive content. Do not reorganize full text unless required to repair a sentence boundary.

### full

Rewrite full text for clarity, coherence, flow, concision, and natural language.

May reorder sentences or paragraphs, merge or split passages, and replace wording. Preserve intended meaning, facts, tone, key detail, and approximate depth. Do not invent facts, arguments, citations, or examples. Do not summarize or expand unless requested separately.

## 4. Language

Without `language`, preserve source language. Detect it from source.

With `language`, final output must use requested language. Translation permission applies even at `words`; intensity controls revision freedom after translation:

- `words`: faithful, close translation; fix clear word errors.
- `syntax`: faithful translation with grammatical target-language syntax.
- `sentences`: natural sentence-level translation.
- `full`: natural full-text adaptation preserving meaning and tone.

For mixed-language text, translate prose into target language. Preserve code, identifiers, commands, URLs, filenames, citations, product names, and proper names unless established translation is clearly intended.

## 5. Source handling

- Local file: read full file before revision.
- Public URL: fetch readable text; revise relevant main text. If scope is unclear, ask which section.
- Preserve Markdown structure, YAML frontmatter, links, tables, code fences, inline code, and embedded HTML. Revise prose only unless Aron explicitly includes structured fields.
- Always write final text to a file, even when revision produces no changes.
- Sibling / increment naming per H4: `<stem>_fixed<ext>`, then `<stem>_fixed_2<ext>` until path is unused. `overwrite=true` replaces source instead.
- When source has no usable writable location, including pasted text, selection, or public URL, write under repository-root `.tmp/fix-text-aron/`. Create directory when missing. Derive safe descriptive filename from source; use `fixed-text.md` when no useful name exists. Add numeric suffix to avoid replacement.

## 6. Overwrite mode

`overwrite=true` is the explicit request H4 requires. It means: replace local source file with final text, no backup, copy, diff file, or temp artifact.

Warning to state before writing (H4): overwrite is irreversible from this skill. Git history, filesystem snapshots, editor history, sync history, logs, or storage recovery may still retain prior content; “no trace” cannot be guaranteed.

If source is pasted text, selection, URL, read-only file, or source path is ambiguous, do not overwrite. Write under `.tmp/fix-text-aron/` instead.

Use surgical single-file overwrite. Do not alter metadata or unrelated files where avoidable.

## 7. Workflow

1. Parse source, intensity, language, overwrite.
2. Ask only for missing required input or material ambiguity.
3. Read/fetch full source.
4. Protect formatting and non-prose tokens.
5. Revise at exactly requested intensity.
6. Translate when `language` is set.
7. Check meaning/facts against source; remove invented content.
8. Write full final text using source-handling policy.
9. Return output path plus concise status.

## 8. Output

Always save final text. Reply with:

```text
written: <output-path>
intensity: <words|syntax|sentences|full>
language: <detected or requested language>
overwritten: true  # only when source was replaced
unchanged: true    # only when revision produced no edits
```

Do not include full revised text in reply unless requested. Do not provide commentary, alternatives, or a change-by-change explanation unless requested.
