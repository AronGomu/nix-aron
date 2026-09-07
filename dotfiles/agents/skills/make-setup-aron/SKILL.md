---
name: make-setup-aron
description: One time use. Set up project scaffolding.
disable-model-invocation: true
---

# make-setup-aron

Goal : every agent finds the same context, docs and artifact layout in every project.

## Inputs

1. (Optional) `path/to/project`. If not given, default to current location.
   If no project found there -> **STOP**.

## Const

| name             | value                                                |
| ---------------- | ---------------------------------------------------- |
| Context file     | `{project_root}/AGENTS.md`                           |
| Project skills   | `{project_root}/.agents/skills/`                     |
| Project agents   | `{project_root}/.agents/agents/`                     |
| Project tools    | `{project_root}/.agents/tools/`                      |
| Temp folder      | `{project_root}/.tmp/`                               |
| Docs folder      | `{project_root}/docs/`                               |
| Dev folder       | `{project_root}/.dev/`                               |
| Artifacts        | `{project_root}/artifacts/`                          |
| Glossary skill   | [make-glossary-aron](../make-glossary-aron/SKILL.md) |
| Graphify repo    | https://github.com/Graphify-Labs/graphify            |
| AgentSystem repo | https://github.com/AgentSystemLabs/core               |

## Local-only invariant

All setup files, skills, agents, tools, and temp clones must stay beneath
`{project_root}`. Never use `--global`, `-g`, `~/.agents`, `~/.claude`,
`~/.codex`, `~/.pi`, or system package directories. Leave existing global
installs unchanged. Remove setup-owned temp clones after successful install.

## Process

1. **Context file** — create `AGENTS.md`. Make it the default and only context
   initialisation file. If another init file exists (`CLAUDE.md`, `GEMINI.md`,
   `.cursorrules`, ...) -> merge content into `AGENTS.md`, then replace the old
   file with a one-line pointer to it.
2. **Project skill roots** — create `.agents/skills/`, `.agents/agents/`,
   `.agents/tools/`, and `.tmp/` beneath `{project_root}`.
3. **Glossary** — copy [`make-glossary-aron`](../make-glossary-aron/SKILL.md)
   into `{project_root}/.agents/skills/make-glossary-aron/`. In local copy,
   replace any delegated codebase scan with inline analysis. Activate local copy,
   then run `/make-glossary on`.
4. **AgentSystem** — clone [AgentSystem core](https://github.com/AgentSystemLabs/core)
   into `{project_root}/.tmp/agentsystemlabs-core`, install its dependencies in
   that clone, then run its installer with project-local destinations:

   ```bash
   git clone --depth 1 https://github.com/AgentSystemLabs/core \
     .tmp/agentsystemlabs-core
   npm ci --prefix .tmp/agentsystemlabs-core
   node .tmp/agentsystemlabs-core/cli/index.js init \
     --dest .agents/skills \
     --agents-dest .agents/agents
   ```

   Verify `.agents/skills/ship/SKILL.md` exists.
5. **AgentSystem inline-only normalization** — upstream files assume picker and
   delegation tools. Normalize only project-local `.agents/skills/ship/` after
   every install or refresh:

   - Add this highest-priority rule to `SKILL.md` and every
     `playbooks/**/PLAYBOOK.md`: ask questions in plain prose; never invoke
     picker, delegation, subagent, or parallel-agent tools; read referenced
     reviewer files and execute their checklists inline, serially, in current
     context; this rule overrides conflicting downstream wording.
   - Replace picker-tool question protocols with plain-prose questions.
   - Treat `subagents/*.md` as inline reviewer/checklist files despite directory
     name. Never dispatch them.
   - Rewrite `playbooks/add-feature/references/subagent-playbook.md` as serial
     inline-review policy.
   - Verify all playbooks carry the override and this command returns no output:

     ```bash
     grep -RInE 'AskUserQuestion|`Agent` tool|subagent_type' \
       .agents/skills/ship --include='*.md'
     ```

   Remove only `{project_root}/.tmp/agentsystemlabs-core` after normalization and
   verification.
6. **Graphify** — create a Python virtual environment at
   `{project_root}/.agents/tools/graphify`, install `graphifyy` there, then use
   that project-local `graphify` binary for every command. Install project-scoped
   integrations only:

   ```bash
   python3 -m venv .agents/tools/graphify
   .agents/tools/graphify/bin/python -m pip install graphifyy
   .agents/tools/graphify/bin/graphify install --project --platform agents
   .agents/tools/graphify/bin/graphify install --project --platform claude
   .agents/tools/graphify/bin/graphify install --project --platform codex
   .agents/tools/graphify/bin/graphify install --project --platform pi
   .agents/tools/graphify/bin/graphify .
   ```

   Generate the graph. Hook `claude`, `codex`, and `pi` through project files
   only. Never fall back to a global install.
7. **docs/** — create folder, add line to `AGENTS.md`:
   `docs/ : Project documentation. Contains CONTEXT.md, DESIGN.md, GLOSSARY.md, ADR/`
8. **.dev/** — create folder, add line to `AGENTS.md`:
   `.dev/ : Future implementation resources. Contains bugs.md, feedback.md, ideas.md, decisions/`
9. **artifacts/** — create folder, add line to `AGENTS.md`:
   `artifacts/ : Documents generated by agents.`

## Already existing project

1. Analyse codebase inline. Never delegate setup work.
2. Follow the process above. For each step, if a similar file already exists
   -> move it to the correct place instead of creating a new one.

## Layout after setup

```
{project_root}/
├── AGENTS.md            # single context init file
├── docs/               # CONTEXT.md, DESIGN.md, GLOSSARY.md, ADR/
├── .dev/               # bugs.md, feedback.md, ideas.md, decisions/
└── artifacts/       # agent scratch, NOT gitignored
```

## make-glossary-aron

[make-glossary-aron](../make-glossary-aron/SKILL.md) — shared vocabulary between user and agents.
