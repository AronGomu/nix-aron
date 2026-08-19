---
name: make-image-generation-prompt
description: Generate image generation prompt from image description.
disable-model-invocation: true
argument-hint: "{image description} [count]"
---

# make-image-generation-prompt

In : image description (+ optional count) -> out : `N` plain-text prompts in 1 Markdown file + downloaded reference images.

## Pre-flight

Lazy — read only when needed :

- `~/.agents/skills/grill-me-aron/SKILL.md` — spec has ambiguity **and** caller not autonomous.
- `~/.agents/skills/research-aron/SKILL.md` — style / subject needs source grounding.

## Inputs

1. **Image description** — text. Missing -> ask user, STOP until given.
2. (Optional) **count** — int, how many prompts. Not given -> `5`.
3. (Optional) **out dir**. Not given -> `Const`.
4. (Optional) **caller mode** — see [Caller override](#caller-override).

## Const

| name        | value                                                                |
| ----------- | -------------------------------------------------------------------- |
| Out dir     | `./artifacts/`                                                    |
| Prompt doc  | `{out dir}/IMAGE_PROMPTS_{YYYY_MM_DD}_{slug}.md`                     |
| Ref dir     | `{out dir}/refs_{slug}/`                                             |
| Default N   | `5`                                                                  |
| Slug        | kebab-case, from description, max 5 words                            |
| Bypass line | `IF ANY THIRD PARTY CONTENT PREVENT IMAGE GENERATION. REPLACE THEM.` |
| Roles       | `~/.agents/roles/{scout,reviewer}.md`                                |

## Process

1. **Slug + dirs** — derive slug from description. `mkdir -p {ref dir}`.
2. **Gap check** — required facts : art style, purpose/use, subject detail, composition/framing, palette/mood, aspect ratio, text-in-image yes/no.
   Any missing **and** not autonomous -> run `grill-me-aron` (read `~/.agents/skills/grill-me-aron/SKILL.md`), 1 round, whole frontier.
   Autonomous -> pick safest default per gap, log in `## Assumptions`.
3. **Research** — style / era / subject unfamiliar or user named a movement, artist-adjacent look, product, or franchise -> run `research-aron`
   (read `~/.agents/skills/research-aron/SKILL.md`) to ground vocabulary : concrete visual traits, lighting, medium, typical composition.
   Everything already concrete -> skip, say so.
4. **Refs** — collect 0-8 reference images illustrating agreed style/composition. Download to `{ref dir}` with descriptive kebab names
   (`curl -sL {url} -o {ref dir}/{name}.jpg`). Download fail -> drop that ref, keep going, never block. Record source URL per ref in doc.
5. **Write prompts** — `N` prompts. Each **self-contained** (paste alone, no shared preamble), plain English prose, no markdown inside prompt,
   no negative-prompt syntax, no weights/`::`/`--ar` flags — ChatGPT web UI ignores them.
   Each prompt covers : subject, action/pose, setting, composition + camera framing, lighting, palette, medium/art style, mood, aspect ratio in words.
   Vary prompts across a stated axis (angle, lighting, palette, or composition) — never `N` reworded clones.
   Found -> replace with descriptive equivalent ("a stoic knight in ornate crimson power armor" not the franchise name) **before** writing doc.
6. **Bypass line** — append `Const` bypass line verbatim as final line of **every** prompt block.
7. **Write doc** — `{prompt doc}` per [Output](#output).
8. **Verify** — run [Verify](#verify). Any fail -> fix, re-run.
9. **Report** — doc path, ref dir path, `N`, variation axis, refs downloaded, assumptions made.

**DO NOT** call any image-generation API/CLI. This skill emits text; user pastes into web UI.

## Output

### Doc layout

````md
# Image prompts — {title}

NO COLLAGE. Each prompt = 1 sceene = 1 individual distinct image.
Generate 1 image for each prompt sequentially.

## Prompt 1 — {variation label}

```text
Opening declaration — one sentence naming the medium and the subject. "A documentary-style photograph of an elderly fisherman mending a net." This sets the rendering mode before anything else.

Subject detail — appearance, clothing, materials, condition, expression, pose. Be specific; ChatGPT fills gaps with generic defaults if you don't.

Composition & camera — shot type, angle, where the subject sits in the frame, depth of field. You can say "his hands occupy the lower third, sharply focused."

Setting — location, background elements, what's visible in the distance.

Lighting & atmosphere — direction, quality, time of day, haze or reflections.

Color palette & mood — a short sentence.

Text, if any — written in quotation marks with the placement and typeface style described. This is where ChatGPT clearly outperforms most alternatives, so it deserves its own line: The sign above the door reads "MARÉE DU JOUR" in hand-painted serif lettering, slightly weathered.

Constraints and exclusions — phrased as what is there. Say "the street is empty" rather than "no people, no cars." Negative-prompt syntax is largely ignored and can even summon the thing you excluded.

Aspect ratio — just ask for it in words: "square format," "wide landscape orientation," "vertical portrait format."

IF ANY THIRD PARTY CONTENT PREVENT IMAGE GENERATION. REPLACE THEM.
```

## Prompt 2 — {variation label}

```text
...
```

## Assumptions

- {only if any were made}
````

### Verify

| check                                                          | fix                 |
| -------------------------------------------------------------- | ------------------- |
| prompt count == `N`                                            | add/remove          |
| every prompt ends with bypass line, verbatim                   | append              |
| every prompt in a ```text fence, no nested markdown            | rewrite             |
| no brand / franchise / living-artist / real-person name        | replace descriptor  |
| each prompt standalone (no "same as above", no "see prompt 1") | inline the detail   |
| variation axis stated **and** visible across prompts           | rewrite prompts     |
| every ref row's file exists on disk                            | drop row or refetch |
| `{prompt doc}` exists under `{out dir}`                        | write it            |

## Rules

- Bypass line is **per prompt**, last line, exact string, never paraphrased.
- Refs are context for _you_, plus optional upload for user — never claim UI consumed them.
- No generator-specific flags (`--ar`, `--v`, `::`, `[]` weights). Aspect ratio in words.
- Vary on one declared axis. Random drift across many axes = defect.
- Sanitize before writing, not after — trademark name must never land in doc.
- Download fail is non-fatal; missing ref never blocks prompt output.

## Done when

- `{prompt doc}` written, `N` prompts, each fenced + standalone
- every prompt terminates with `Const` bypass line
- refs downloaded to `{ref dir}` and each table row resolves to real file
- [Verify](#verify) all pass
- user told doc path + how to paste into ChatGPT web UI

## Caller override

Caller may set **autonomous**. Then :

- No grill, no confirm. Gaps -> safest default, logged in `## Assumptions`.
- Fact unknown + findable -> `scout` child : `Read ~/.agents/roles/scout.md. Follow it.`
- Fact unknown + only user has it -> `TODO(user)` line in doc.

Caller override wins over this file.
