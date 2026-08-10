---
name: nix-aron
description: >
  Apply change to NixOS/Home Manager config repo:
  add, remove, or update packages/modules/settings. Grill if unclear.
  When clear: edit, commit, push, then ask user to rebuild.
disable-model-invocation: true
---

# nix-aron

One prompt in → clear change on active nix config → commit → push → **ask** rebuild.

## Fixed context

Read and obey `/home/aron/AGENTS.md` plus repo `NIX-CHEATSHEET.md`.

| Fact             | Value                                                                                                 |
| ---------------- | ----------------------------------------------------------------------------------------------------- |
| Repo             | `/home/aron/config/nix-aron`                                                                          |
| Host flake       | `desk-main-nvme` (btrfs nvme0n1, current) / `desk-main-samsung` (ext4 sdb) — **no bare `desk-main`**   |
| HM user flake    | none — HM is wired through the NixOS module; `nixos-rebuild` applies it. Never run `home-manager switch` |
| Active source    | this flake only                                                                                       |
| Legacy           | `/etc/nixos/configuration.nix` — **never** edit for system changes                                    |
| Rebuild (system) | `sudo nixos-rebuild switch --flake /home/aron/config/nix-aron#$(nixos-host)`                              |
| Branch           | work on `main` unless user said otherwise                                                             |

## Input

**Arg1 = prompt** (required). Natural language: add / remove / change package, service, module, dotfile wiring, gsettings, desktop default, etc.

STOP if prompt empty. Ask for prompt only.

### Multi-store link recipe (`add to rofi and floccus …`)

When prompt matches **add to rofi and floccus** (optional: and managed Brave / Nix bookmarks) with one or more URLs:

| Store | Path | Default |
| --- | --- | --- |
| Rofi launcher | `home/aron/end4.nix` → `xdg.desktopEntries` | `brave <url>`; icon `brave-browser`; categories `Network`; key = slug from title/host |
| Floccus | `/home/aron/config/bookmarks/bookmarks.xbel` (separate git repo) | folder `Synced`; `<title>` human name |
| Nix managed Brave | `modules/nixos/brave-policies.nix` | folder **Daily** unless user named another |

Defaults when unspecified: title from site/host (e.g. `scryfall.com` → `Scryfall`); include all three stores; keep existing XBEL entries; dedupe by URL.

**Git:**
1. nix-aron: commit + push intentional paths (this skill’s normal rules).
2. bookmarks repo: `cd /home/aron/config/bookmarks` → commit intentional `bookmarks.xbel` → `git push origin` **if remote exists**; else report `blocked: no bookmarks remote` (do not invent remote, no force-push).

**Rebuild ask** still required for nix-aron/HM/Brave policy. Floccus picks up after bookmarks push + extension sync.

Pi convenience: prompt template `/add-rofi-floccus <url> [url…]` expands to this skill path (read skill file; no nested `/skill:` expand).

## Job

```
1. Parse prompt → intended end state (add | remove | change | multi).
2. Explore repo. Find real files/modules. Prefer existing patterns (home/aron/*.nix, hosts/desk-main, modules/nixos, dotfiles/).
3. Clarity gate:
   - Unclear / multi-way choice / destructive / security-sensitive / irreversible
     → grill until shared understanding (see Clarity gate). Do not edit yet.
   - Clear enough for one safe implementation path
     → proceed. Log brief Assumptions if tiny defaults taken.
4. Implement surgical edit(s) only. Match repo style. No drive-by refactors.
5. Sanity check when cheap: `nix flake check` and/or evaluate touched attr if practical.
   Fail → fix or hard-stop with evidence. Do not push broken obvious syntax.
6. Git on repo root:
   - status / diff / log style
   - stage only intentional paths (no secrets, no .env, no .tmp junk, no .pi-subagents)
   - new .nix files **must** `git add` (flake ignores untracked)
   - commit message: conventional, why-focused
     e.g. `feat(hm): add foo` / `fix(nixos): ...` / `chore(nix): ...`
   - `git push` to `origin` current branch
7. **Do not rebuild.** Ask user to rebuild. Offer exact cmd(s).
```

## Clarity gate (when to grill)

Grill = read `~/.agents/skills/grill-me-aron/SKILL.md` now and follow it fully — rounds, frontier, html doc, wait for answers each round. Its `assets/*.html` paths resolve inside **its own** dir.

Grill when any true:

- Prompt names goal but not which host/user/package/module
- Multiple reasonable impls (systemPackage vs HM, module vs overlay, enable flag vs package only)
- Remove/disable may break login, network, boot, disk, GPU, display manager
- Secrets, keys, tokens, password hashes, Wi‑Fi PSKs
- Flake input bumps / nixpkgs channel jumps with wide blast radius
- User intent could mean HM-only **or** NixOS-only and both exist

Skip grill when:

- Single obvious package pin/add/remove in existing list
- Flip existing option already patterned in repo
- User pasted exact package/module/file + action

After grill rounds finish and user confirms shared understanding → continue from step 4.

## Impl rules

- **Surgical:** touch only files required by prompt.
- **Prefer existing modules** over new top-level sprawl.
- **HM vs NixOS:** GUI user apps/dotfiles → often `home/aron/`; system services, boot, hardware, system-wide → `hosts/` + `modules/nixos/`.
- **Desktop stack:** end4/Hyprland bits live in `home/aron/end4.nix` and related; do not fight that layout.
- **No legacy `/etc/nixos` edits.**
- **No secrets in git.** Point to sops/agenix/existing secret pattern if repo has one; else hard-stop and ask.
- **Do not** run `nixos-rebuild` / `home-manager switch` in this skill. User confirms rebuild.
- **Do not** open PR unless user asked. Push branch only.
- Unrelated dirty tree: commit only your files; leave other dirty files unstaged. If dirty overlap blocks safe edit → stop and report.

## Commit / push rules

- Repo cwd: `/home/aron/config/nix-aron`
- No force-push. No `--no-verify` unless user said.
- No amend of others' commits. No rewrite published history.
- Scan diff for secrets before commit.
- Push fail network → retry once. Auth/protected → hard-stop, show state.
- If nothing to change after investigation → say so; no empty commit.

## Rebuild ask (mandatory end)

After successful push (or "no change needed"), tell user:

```text
state: pushed | no-change | blocked
branch: {branch}
remote: origin
commit: {sha|—}
files: ...
assumptions: ...   # if any
residual-risk: ...

Rebuild when ready (I did not run it):

  sudo nixos-rebuild switch --flake /home/aron/config/nix-aron#$(nixos-host)

# If change was HM-only and you normally use HM separately, also/alternate:
  home-manager switch --flake /home/aron/config/nix-aron#<user-or-output>
```

Pick the accurate rebuild line(s) from what you changed. Prefer full `nixos-rebuild switch` when both system + HM wired through NixOS; mention HM-only when that is truly enough.

**Wait for user** to approve/run rebuild. Do not run sudo rebuild yourself unless user explicitly orders rebuild in a later message.

## Hard stop

Stop + report when:

- Grill unfinished / user did not confirm understanding on ambiguous change
- Need secret or external account user must supply
- Push rejected with no safe fix
- Edit would touch boot/disk/network critically and user did not clearly accept risk
- Flake/eval broken after edit and one repair pass failed

## Anti-patterns

- Silent assume on multi-path nix design
- Edit `/etc/nixos/configuration.nix`
- Rebuild without asking
- Empty commit / commit unrelated junk / commit `.tmp`
- Broad reformat of nix files
- Scope creep "while here"
- Force-push main

## Done when

- Prompt satisfied in config **or** blocked with clear reason
- If changes: committed + pushed
- User has exact rebuild command and explicit ask to run it
