---
name: make-skill-aron
description: Create agent skill.
disable-model-invocation: true
---

# make-skill-aron

## Pre-flight

Read `~/.agents/skills/caveman/SKILL.md` if not already — skill bodies are written Caveman Ultra.

Lazy — read only when needed :

- `~/.agents/skills/grill-me-aron/SKILL.md` — ambiguity left **and** caller did not say autonomous.
- `~/.agents/skills/_shared/orchestration.md` — new skill spawns subagents or runs a loop.

## Inputs

1. **Name + purpose**. Purpose missing -> grill (1 round, max 4 questions : trigger, inputs, outputs, tier).
2. (Optional) **skills root**. Not given -> `Const`.
3. (Optional) **caller mode** — see [Caller override](#caller-override).

## Const

| name             | value                                                              |
| ---------------- | ------------------------------------------------------------------ |
| Skills root      | `~/config/nix-aron/dotfiles/agents/skills/`                        |
| Skill dir        | `{skills root}/{name}/`                                            |
| Body             | `{skill dir}/SKILL.md` — required                                  |
| Codex/pi adapter | `{skill dir}/agents/openai.yaml` — optional                        |
| Assets           | `{skill dir}/assets/` — templates, references                      |
| Format docs      | `{skill dir}/{TOPIC}-FORMAT.md` — only if body > ~200 lines        |
| Install rule     | `~/config/nix-aron/home/aron/agents.nix:72` — whole dir, recursive |
| Live path        | `~/.agents/skills/{name}/` -> symlinked to claude, pi, codex       |
| Rebuild          | `sudo nixos-rebuild switch --flake .#$(nixos-host)`                |
| Roles            | `~/.agents/roles/{scout,impl-worker,reviewer}.md`                  |
| Reference skill  | `make-plan-aron` (full shape), `make-setup-aron` (short shape)     |

## Process

1. **Name** — kebab-case, lowercase, no space. Personal skill -> `{verb}-{noun}-aron` (`make-plan-aron`, `fix-text-aron`).
   Generic/shared skill -> no suffix (`handoff`, `teach`).
   Collision check : `ls {skills root}` . Name taken -> new name, or `-2` variant if explicit successor.
2. **Classify** — pick shape before writing :
   - **short** (< 60 lines) — 1 clear procedure, no artifact zoo. Model : `make-setup-aron`, `research-aron`.
   - **full** (60-200 lines) — artifacts, templates, rules, tiering. Model : `make-plan-aron`, `grill-me-aron`.
   - **split** (> 200 lines) — full + `{TOPIC}-FORMAT.md` sidecars. Model : `teach`.
3. **Scaffold** — `mkdir -p {skill dir}/agents`. `assets/` only if skill ships a template.
4. **Write frontmatter** — per [Frontmatter](#frontmatter). `name` **must equal dir name**.
5. **Write body** — sections in [Body skeleton](#body-skeleton) order. Skip a section only when it truly does not apply.
6. **Write adapter** — `agents/openai.yaml` per [Adapter](#adapter). Skip only if skill is Claude-only by design.
7. **Ship assets** — template consumed by the skill -> copy it into `{skill dir}/assets/`, reference it **relative to skill dir**. Never point at another skill's assets.
8. **Verify** — run [Verify](#verify). Any fail -> fix, re-run.
9. **Install** — nix already sources the whole skills dir recursively -> **no nix edit**. Tell user to rebuild :
   `cd ~/config/nix-aron && sudo nixos-rebuild switch --flake .#$(nixos-host)`
   Skill appears in `~/.agents/skills/{name}` and, through it, in claude / pi / codex.
10. **Report** — files written, shape chosen, rebuild cmd, how to invoke (`/{name}`).

**DO NOT run the rebuild yourself** unless user says install / apply. It is a system-wide switch.

## Output

### Skill dir layout

```
{name}/
├── SKILL.md                  # required — the procedure
├── agents/openai.yaml        # codex + pi display name / invocation policy
├── assets/                   # templates, reference outputs (optional)
└── {TOPIC}-FORMAT.md         # split shape only
```

### Frontmatter

```yaml
---
name: { name } # == dir name, kebab-case
description: { one line — what + when to load } # folded `>` if 2+ lines
disable-model-invocation: true # default: user-invoked only
argument-hint: "{what user types after /name}" # only if skill takes an arg
---
```

- `description` is the **only** thing the model sees before loading. Write the trigger into it : "Use when user asks to X".
- `disable-model-invocation: true` unless skill must fire automatically on a topic. Default = true.
- No other keys. No `version`, no `author`, no `tags`.

### Body skeleton

```md
# {name}

{1 line : input -> output}

## Pre-flight <!-- only if skill reads other skills -->

Read `~/.agents/skills/{dep}/SKILL.md`.
Lazy — read only when needed : {dep} — {condition}.

## Inputs

1. **{arg}** — {type}. Missing -> {fallback or STOP}.
2. (Optional) {arg}. Not given -> `Const`.

## Const

| name | value |
| ---- | ----- |

## Process

1. **{Step}** — {imperative}. {failure branch}.
2. ...

## Output

{exact artifact shapes : path, template, fenced example}

## Rules

- {invariant that is not a step}

## Done when

- {checkable condition, evidence-bearing}

## Caller override

Caller may set **autonomous**. Then : {what drops}.
Caller override wins over this file.
```

### Adapter

`{skill dir}/agents/openai.yaml` :

```yaml
interface:
  display_name: "{Title Case Name}"
  short_description: "{≤ 60 chars, verb-first}"
policy:
  allow_implicit_invocation: false # mirror disable-model-invocation
```

### Verify

| check                                                                   | fix                 |
| ----------------------------------------------------------------------- | ------------------- |
| `head -6 {skill dir}/SKILL.md` — frontmatter parses, 3 dashes both ends | rewrite frontmatter |
| `name:` == dir name                                                     | rename dir or key   |
| `description` states **what + when**                                    | rewrite             |
| every `Const` path exists or is created by the skill                    | fix path            |
| every relative link resolves from skill dir                             | fix link            |
| `assets/` files referenced by body actually shipped                     | copy them in        |
| no other skill has this name (`ls {skills root}`)                       | rename              |
| body has `Process` **and** `Done when`                                  | add them            |

## Rules

- **Procedure, not prose.** Every line must change model behavior. Cut anything a reader would call "background".
- **Caveman Ultra.** Drop articles, filler, hedging. Arrows for cause/effect. Keep exact paths, cmds, API names verbatim.
- **Exact over vague.** `./ai-artifacts/PLAN_{YYYY_MM_DD}_{title}.md`, never "an artifacts folder".
- **Self-contained dir.** Skill needs a template -> ship it in its own `assets/`. Cross-skill asset ref = broken skill.
- Cross-skill **behavior** ref is fine, by path : `~/.agents/skills/{name}/SKILL.md`. Never inline another skill's body.
- Subagent spawn -> pass role **by path** : `Read ~/.agents/roles/{role}.md. Follow it.` Never paste role body.
- Every branch point gets a written default. Choice left to the reader = defect.
- `disable-model-invocation: true` by default — user's skills are user-triggered.
- Never edit `agents.nix` to add a skill. Dir is sourced recursively; editing it is noise.
- Refactor of an existing skill -> keep the old dir intact, write `{name}-2`. User validates before the old one dies.

## Done when

- `{skill dir}/SKILL.md` exists, frontmatter parses, `name` == dir name
- body carries `Process` + `Done when`, every step imperative with a failure branch
- `agents/openai.yaml` written (or skip justified to user)
- assets shipped inside the skill dir, every reference resolves
- [Verify](#verify) table all pass
- user told : rebuild cmd + `/{name}` invocation
- **not** claimed installed until rebuild ran

## Caller override

Caller may set **autonomous**. Then :

- No grill, no user confirm.
- Ambiguity -> safest default, logged in a `## Assumptions` block at end of the new `SKILL.md`.
- Fact unknown + findable -> `scout` child : `Read ~/.agents/roles/scout.md. Follow it.`
- Fact unknown + only user has it -> `TODO(user)` line in the new skill.
- Never rebuild autonomously. System switch stays user-triggered.

Caller override wins over this file.
