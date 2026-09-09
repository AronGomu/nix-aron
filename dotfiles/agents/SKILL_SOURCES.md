# Skill source snapshots

| ID | Config source | Provenance | Deployment |
|---|---|---|---|
| S1 | `skills/graphify/` | Installed `graphifyy` distribution, version `0.9.53`: `graphify/skill-pi.md` + matching `graphify/skills/pi/references/`; distribution licenses retained. Restores missing runtime entry file. | Shared skill hub. Install `graphifyy` via uv; verify `graphify --help`. Do not install duplicate skill copies. |
| S2 | `skills/make-features-aron/SKILL.md` | New compatibility alias. Historical workflow merged into `make-aron` by `986e3e6f381e5a7aa42c94f98f132ee1690668fa`. Runtime entry was a broken store symlink. | Shared skill hub; delegates to current `make-aron`. |
| S3 | `skills/.system/` | Local Codex vendor source snapshot: imagegen, openai-docs, plugin-creator, review-agent, skill-creator, skill-installer. Exact upstream revision unknown; bundled licenses retained. Runtime marker excluded. One trailing space normalized in plugin-creator update reference to pass diff validation. | Preserve snapshot in repo. Installer compares current Codex bundled skills; choose one source per name, no duplicate discovery. Do not overwrite newer bundled skills blindly. |

## Assumptions

- A1. Requested runtime-only skills include vendor sources. Source snapshot is backup/config input, not proof of cross-harness compatibility.
- A2. Agent installer owns target-specific discovery wiring. Runtime homes derive from current user/config conventions, not old machine paths.

## Validation

- V1. Snapshot copies contain regular source files, no runtime store symlinks.
- V2. Basic private-key/token pattern scan passed during capture; not a complete security audit.
- V3. No CLI install, system apply, runtime skill replacement, commit, or publication performed during capture.
