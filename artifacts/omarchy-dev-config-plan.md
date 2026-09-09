# Omarchy migration — portable dev config

**State: plan done. Migration not executed.**

Keep personal workflow, not NixOS implementation. Recommended new repo: `dev-config`. Plain files + one agent entry guide. No replacement config framework needed.

## Assumptions

- A1. Fresh Omarchy owns drivers, boot, OS updates. Preserve dev workflow + selected personal desktop deltas.
- A2. User selections below confirmed. Former optional IDs O1–O5, O7–O10 now required. O6/O11 remain optional. O4 excludes DaVinci Resolve.
- A5. Bar toggle means manual show/hide via `Super+Shift+B`, replacing idle auto-hide; installer resolves existing shortcut conflicts. No running desktop changes in this task.
- A3. “Single repo” means owned config + instructions centralized. Third-party tools/plugins remain upstream deps; project source stays in project repos.
- A4. Current working tree = planning baseline, including existing uncommitted edits. Fresh Omarchy release/package availability not tested; installer agent must inspect target.

## Evidence snapshot

- E1. `git ls-files` → 237 tracked files. Inventory covers `dotfiles/`, `home/aron/`, `modules/nixos/`, `hosts/`, `pkgs/`, flake wiring, docs.
- E2. Full Neovim config comes from external input; local repo overlays only `options.lua`, `treesitter.lua`, `ui.lua`. Sources: `flake.nix:23`, `home/aron/agents.nix:10`.
- E3. `flake.lock` inspection → old Neovim revision `33d6efc5bea28131441eeda52a7853c7cdb9d65d`. Installed Lua config confirms C#/Razor, Angular/TS, debugging, tests. Installer should fetch latest upstream default branch when uncertain, merge personal overrides, record tested revision.
- E4. Runtime audit: graphify entry file missing; restored from installed `graphifyy 0.9.53` Pi skill bundle. make-features entry broken; history `986e3e6` merged it into make-aron → compatibility alias added. Codex `.system` vendor source snapshot captured with licenses, without runtime marker. Provenance: `dotfiles/agents/SKILL_SOURCES.md`.
- E5. Pi runtime-only entries include `models-store.json`, `trust.json`, `auth.json`, sessions, npm installs. Names inspected only; contents not exported. Repo snapshot alone is not full live-state backup.

## 1 — Must keep

| ID | Keep | Save / adaptation | Evidence |
|---|---|---|---|
| K1 | **Full Neovim config** | Fetch latest default branch from `https://github.com/AronGomu/TRULY_CUSTOM_NVIM_WINDOWS_LINUX`; vendor complete source into `dotfiles/nvim/`; reconcile 3 local overrides against latest upstream, avoiding stale wholesale replacement. Preserve init, keymaps, autocmds, filetypes, plugin specs, utils. Record upstream URL/revision. Preserve plugin lockfile if available; otherwise create tested baseline during migration. Do not copy symlink to Nix store. | `flake.nix:23`; `home/aron/agents.nix:10`; `dotfiles/nvim/options.lua:1` |
| K2 | **Neovim language/debug workflow** | Keep C#/Razor/Blazor Roslyn registry/setup; .NET SDK 10, `netcoredbg`, `csharpier`; Angular/TS/HTML/CSS/Lua tooling; `stylua`, `prettierd`, Tree-sitter parser list. Preserve DAP, DLL autopicker, scope walker, `neotest-vstest`, debug/test keys. Install method may change; executable names must still resolve. | Installed `~/.config/nvim/lua/plugins/lsp.lua:1`, `dotnet.lua:1`; `home/aron/packages.nix:356`; `dotfiles/nvim/treesitter.lua:1` |
| K3 | **Pi config + custom extensions** | Save `dotfiles/pi/agent/`: settings, keybindings, bridge config, extension configs, prompts, local extensions (`btw`, footer-context-tokens, model-switch, trusted-permission-gate). Keep package sources/pins, package extension exclusions. Current pins: `pi-subagents@0.38.0`, `@adrianapan/pikit@1.1.7`. Model IDs/theme availability need target validation. | `dotfiles/pi/agent/settings.json:1`; `home/aron/agents.nix:99` |
| K4 | **Shared agent rules + skills** | Save `GLOBAL_RULES.md`, every authored portable skill except unused `grok-imagine`, restored graphify, make-features alias, vendor `.system` snapshot, `_shared/`, templates, references, advisor/role files, gate/bootstrap scripts, agent metadata. Canonical hub: `~/.agents/skills`. Reconnect Pi/Claude/Codex discovery; one copy, no duplicate installs. Exclude hidden run/scratch dirs. | `home/aron/agents.nix:88`; `dotfiles/agents/skills/` |
| K5 | **Claude Code + Codex prefs** | Save both CLIs' sanitized configs, Claude memory/commands/statusline script, Codex prompts/rules/caveman config, docs MCP endpoint. Preserve preferred behavior—not old absolute trust paths, hook trust hashes, reminder text. Fix Claude statusline path. | `dotfiles/claude/settings.json:1`; `dotfiles/claude/statusline.sh:1`; `dotfiles/codex/config.toml:1`; `home/aron/agents.nix:117` |
| K6 | **Shell/Git/terminal workflow** | Extract Bash aliases, completion, ble.sh→Starship ordering, plain direnv integration, Git prefs, Yazi opener/Escape key, Ghostty prefs. Keep `EDITOR`/`VISUAL=nvim`, terminal choice, Nerd Font. Preserve Ghostty Ctrl+Enter unbind → Pi receives newline shortcut. Use `$HOME` for navigation aliases. | `home/aron/shell.nix:3`, `:70`, `:98`, `:116`, `:136` |
| K7 | **Devtools manifest** | Record required capabilities, not copied Nix package expressions: Git/gh/lazygit; Node.js 24/npm; Python/uv; .NET 10; Rust/cargo/clippy/rustfmt; Go; GCC/make; Tree-sitter; shellcheck; jq/yq, ripgrep/fd/fzf, curl/wget, bat/eza/tree, archive tools, zoxide. Keep requirements visible; reuse existing Omarchy installs when compatible. | `home/aron/packages.nix:350`; `home/aron/default.nix:21` |
| K8 | **Project environment requirements** | Preserve rootless Docker intent, plain direnv, Playwright browser-test capability. Move Python Pillow/lxml/requests requirements into project venv setup instead of global Python mutation. Preserve file-explorer Tauri build requirements: Rust/Node, pkg-config, GTK/WebKit, OpenSSL, appindicator. Project lockfiles remain authority. | `modules/nixos/base.nix:125`, `:181`; `home/aron/packages.nix:261`; `flake.nix:143` |
| K9 | **Workspace map** | Export `repos.nix` into plain repo URL→local directory manifest. Preserve checkout names, `~/config`, `~/projects`, useful navigation aliases. Existing checkouts stay untouched. Replace old Nix config checkout with new repo entry. Do not merge project source into config repo. | `home/aron/repos.nix:3`; `home/aron/shell.nix:9` |
| K11 | **Agent-adjacent Herdr workflow** | Keep `dotfiles/herdr/config.toml`, sound assets, Herdr install source/version note. Extract clickable notification shim; scope override to Herdr PATH, not global `notify-send`. Retained; user exclusion applies only to grok-imagine, not Herdr. | `home/aron/herdr.nix:3`; `home/aron/packages.nix:27`; `pkgs/herdr-notify-shim.nix:9`; `flake.nix:36` |
| K12 | **Writable-state + secret contract** | Save deployment map, env template, auth recovery instructions. Preserve `~/.local/bin`, `~/.dotnet/tools` PATH. Pi settings seed/merge should preserve runtime model choices. Mutable config must remain writable; do not recreate Home Manager indirection. Audit runtime-only skill/config differences before final export. | `home/aron/agents.nix:32`, `:60`; `home/aron/default.nix:21`; `home/aron/shell.nix:37` |

**Security boundary:** Never commit API keys, OAuth tokens, SSH private keys, browser sessions, password databases, recovery material, or authentication state—even to a private repo. Keep encrypted backups separately. Re-authorize services on the new host. Review broad project trust and automatic permission settings explicitly; do not replay them blindly. Sources: `dotfiles/codex/config.toml:8`, `dotfiles/claude/settings.json:2`, `home/aron/keepassxc.nix:4`.

### Confirmed additions to category 1

Original O IDs retained for user discussion. Rows below are required, not opt-ins.

| ID | Required workflow | Save / adaptation | Evidence |
|---|---|---|---|
| O1 | Personal desktop deltas | Keep monitor scale 1, mouse sensitivity 0.3, gaps 2, startup/workspace rules, NightLight indicator, Tokyo Night, Adwaita cursor. Replace idle auto-hide with manual bar visibility toggle `Super+Shift+B`. Use installed Omarchy bar control; no old QML timer patch. Save personal overrides, not patched upstream tree. | `modules/nixos/omarchy.nix:30`; `home/aron/omarchy.nix:116`, `:186` |
| O2 | OpenWhispr dictation | Normal current OpenWhispr install using supported Omarchy/Arch/upstream route. Keep dictation workflow; use normal app shortcut/setup support. Do not port old AppImage patch, custom cancel/paste code, sg wrapper, or forced socket. Installer follows current app requirements. | `home/aron/packages.nix:44`; `modules/nixos/omarchy.nix:48`; `docs/problems/openwhispr-hyprland-paste.md:1` |
| O3 | Media automation | `remove-silence.sh`, `social-square.sh`, `ytmusic-sync.py`, related Pi prompts, cut-retakes skill assets/docs. Record auto-editor, ImageMagick, pngquant/oxipng, ffmpeg, yt-dlp, ytmusicapi, Strawberry deps. All three scripts required, with their prompts/assets/deps. Also retain clone-repos helper, Herdr notification helper, Claude statusline; grok-imagine explicitly excluded. Nix disk migration scripts remain excluded. | `home/aron/packages.nix:273`; `home/aron/scripts/`; `dotfiles/pi/agent/prompts/` |
| O4 | Media apps + speech prefs | Keep Kdenlive + its config, OBS, GIMP. Exclude DaVinci Resolve. Preserve Kdenlive dark theme, VOSK FR/EN model names, Whisper turbo preference; current Kdenlive config is barebone per user; no live capture required, normal install + declared prefs sufficient. Download model weights later; no model/cache blobs. | `home/aron/kdenlive.nix:29`; `home/aron/packages.nix:16`, `:312` |
| O5 | Browser/bookmark workflow | Brave Origin choice, profile launcher aliases, Unhook/SponsorBlock/Enhancer/Dark Reader/Floccus list, managed bookmarks, web launchers. Local bookmark repo is separate; publish/export separately only after privacy review. | `home/aron/packages.nix:9`; `home/aron/shell.nix:30`; `modules/nixos/brave-policies.nix:1`; `home/aron/repos.nix:34` |
| O7 | Google Drive mount | Portable user service/path unit, `gdrive:` name, `~/GoogleDrive`, cache options. Re-auth rclone separately. | `home/aron/google-drive.nix:9` |
| O8 | Remote access + VPN | Tailscale, SSH, mosh, Mullvad. Preserve security intent: SSH/mosh restricted to tailnet; no password/root SSH login. Remote-hosted config does not itself require inbound access. | `modules/nixos/remote-access.nix:3`; `modules/nixos/mullvad.nix:3` |
| O9 | Open WebUI Computer | `cptr` localhost-only user service, restrictive umask, data-dir convention. Runtime inventory: `uv tool list` reports `cptr v0.9.21`; installer chooses current compatible release. Replace Nix PATH. Private app data outside repo. | `home/aron/cptr.nix:3` |
| O10 | Extra apps/gaming/hardware prefs | Custom file-explorer source reference, OneKey app preference, Steam/Lutris/Wine/gamescope, Brood War/OpenBW launch env, Razer tools, peripheral/audio prefs. Game data/wallet secrets are not config. | `pkgs/file-explorer.nix:1`; `pkgs/onekey-wallet.nix:1`; `modules/nixos/gaming.nix:1`; `modules/nixos/openrazer.nix:1`; `home/aron/shell.nix:64`; `modules/nixos/base.nix:63` |
## 2 — Choose not to keep by default, but could

| ID | Optional workflow | Save if wanted | Evidence |
|---|---|---|---|
| O6 | Desktop app prefs beyond selected deltas | MIME defaults, Dolphin dimensions/tooltips, GTK/Qt dark prefs, terminal chooser, file manager bookmarks; Obsidian, Thunderbird, CopyQ, KeePassXC. Required script deps such as Strawberry still installed under O3. | `home/aron/desktop.nix:392`, `:456`; `home/aron/keepassxc.nix:4` |
| O11 | Old troubleshooting knowledge | Small selected notes: OpenWhispr bug, Hyprland hotplug/portal/cursor bugs, media tuning decisions. Keep symptoms/repro/resolution; no unconditional old workarounds. | `docs/problems/`; `docs/ADR/`; `home/aron/omarchy.nix:23`; `modules/nixos/omarchy.nix:58`, `:220` |

## 3 — Definitely unnecessary in new config repo

“Unnecessary” means **exclude from portable bootstrap**, not delete from old disk or erase backup.

| ID | Exclude | Reason / boundary | Evidence |
|---|---|---|---|
| D9 | Unused app / superseded customizations | Exclude grok-imagine CLI + skill + dedicated config; exclude DaVinci Resolve; exclude old OpenWhispr custom patches; exclude idle auto-hide bar patch. Existing NixOS files remain untouched; exclusion applies to new repo export. Grok CLI itself remains independent. | User selections; `pkgs/grok-imagine.nix:9`; `home/aron/packages.nix:16`, `:44`; `modules/nixos/omarchy.nix:77` |
| D1 | NixOS/Home Manager framework | `flake.nix`, `flake.lock`, module wiring, overlays, package hashes, allow-unfree, generations, GC, formatter, activation DAG. First extract portable content identified above. | `flake.nix:1`; `modules/nixos/nix.nix:1`; `lib/allow-unfree.nix:1` |
| D2 | Old disk/host installation logic | `hosts/`, UUIDs, fstab/storage declarations, ESP guard, bootloader wiring, disk-output detection. `docs/migration/` is old migration machinery—not Omarchy installer. | `hosts/desk-main/`; `hosts/_template/`; `modules/nixos/boot.nix:1`; `docs/migration/` |
| D3 | Nix FHS compatibility fixes | nix-ld library inventory; Nix-store Playwright env/download suppression; `/run/opengl-driver` wrappers; Nix-only Qt/AppImage fixes; hardcoded store executables. Preserve app capability, retest with native deps. | `modules/nixos/base.nix:125–179`; `home/aron/kdenlive.nix:3`; `home/aron/packages.nix:16`, `:210` |
| D4 | Omarchy-on-Nix port | Patched shebangs, repackaged upstream apps/Quickshell, disabled Arch first-run provisioning, hidden system-update widget, seeded SDDM/PAM/module wiring. Native Omarchy should own its install/update flow. Personal deltas remain O1. | `modules/nixos/omarchy.nix:9`, `:25`; `home/aron/omarchy.nix:14`, `:72`, `:186`; `pkgs/omacalc.nix:1`; `pkgs/omawrite.nix:1`; `pkgs/ttfx.nix:1`; `pkgs/cliamp.nix:1` |
| D5 | Nix-specific instructions | `INSTALL.md`, `NIX-CHEATSHEET.md`, rebuild/hm/update aliases, nix-direnv integration, old nix-aron skill implementation. Retain portable policy; rewrite make-skill paths/install steps, Nix-specific prompt references. | `home/aron/shell.nix:21`, `:93`; `dotfiles/agents/skills/nix-aron/SKILL.md:18`; `dotfiles/agents/skills/make-skill-aron/SKILL.md:30` |
| D6 | One-time migration cleanups | Tree-sitter deletion hook, duplicate skill cleanup, cache rebuilds, Home Manager backup recovery. Fresh install needs correct config, not old repair history. | `home/aron/agents.nix:20`, `:52`; `home/aron/desktop.nix:450` |
| D7 | Rebuildable output | `.pi-subagents/`, `.tmp/`, old agent reports, caches, logs, sessions, downloaded npm/plugin trees, binaries, parser builds, store symlinks, package-build lockfiles for discarded derivations. Keep authored skill assets—not generated agent debris. | `git ls-files`; `.gitignore:7`; `pkgs/file-explorer-Cargo.lock`; `pkgs/file-explorer-package-lock.json` |
| D8 | Machine trust/auth/runtime history | Old absolute project trust paths, trusted hook hashes, auth/session files, runtime onboarding state. Store intentional prefs as sanitized seeds. Private data still needs separate backup. | `dotfiles/codex/config.toml:8`, `:43`; `home/aron/agents.nix:60`; runtime directory comparison |

## Single-repo layout — proposal

```text
dev-config/
  AGENTS.md                  # sole agent entry guide; intent + setup order + checks
  README.md                  # human overview; fetch instruction; links AGENTS.md
  manifests/
    tools.md                 # required tools/capabilities; optional groups; deps
    repos.tsv                # remote URL -> local checkout path
    sources.md               # upstream refs + tested versions; nvim provenance
  dotfiles/
    nvim/                    # FULL merged Lua config, not just 3 overlays
    agents/                  # GLOBAL_RULES.md + portable skills + assets
    pi/agent/                # sanitized config + custom extensions/prompts
    claude/                  # sanitized config + commands + statusline
    codex/                   # sanitized config + prompts/rules
    shell/                   # Bash/Git/Yazi/Ghostty extracts
    herdr/                   # prefs + sounds
  bin/
    remove-silence           # existing shell script
    social-square           # existing shell script
    ytmusic-sync            # Python entrypoint + isolated deps
    clone-repos             # extracted idempotent checkout helper
    herdr-notify-send        # scoped shim; no global replacement
  services/                  # rclone, cptr; selected service intent
  desktop/                   # personal deltas; browser/bookmarks; Kdenlive
  optional/                  # O6/O11 only
  .gitignore                 # deny secrets, state, caches, generated output
```

One guide beats elaborate installer. No giant Bash provisioning script, custom package manager, compulsory Stow/chezmoi layer, copied Omarchy defaults. Small manifest + native config + agent judgment matches requested flexibility.

## Installer source map — Omarchy adaptation

All source paths below relative to this Nix repo. During new repo extraction, include listed source logic as native files; installer must not depend on old checkout being present. `.nix` files are readable source references, never Arch install scripts.

| ID | Required output / behavior | Source to give installer | Omarchy instruction |
|---|---|---|---|
| S1 | `bin/remove-silence` | `home/aron/scripts/remove-silence.sh`; deps in `home/aron/packages.nix` | Preserve script; executable Bash entrypoint; install auto-editor/coreutils. |
| S2 | `bin/social-square` | `home/aron/scripts/social-square.sh`; same package module | Preserve script; install ImageMagick, pngquant, oxipng, coreutils. |
| S3 | `bin/ytmusic-sync` | `home/aron/scripts/ytmusic-sync.py`; same package module | Preserve Python logic; isolated ytmusicapi env; ffmpeg, yt-dlp, Strawberry, procps/coreutils available. |
| S4 | `bin/clone-repos` + repo manifest | `home/aron/repos.nix` | Extract shell body, replace generated clone lines with manifest input; existing dirs/checkouts untouched. |
| S5 | Herdr notification helper | `pkgs/herdr-notify-shim.nix`; `home/aron/packages.nix`; `dotfiles/herdr/` | Extract shell body; replace Nix interpolation with native executable resolution; libnotify/jq/util-linux/coreutils deps. Scope wrapper to Herdr. |
| S6 | Claude statusline | `dotfiles/claude/statusline.sh`; `dotfiles/claude/settings.json` | Preserve script; derive installed location; inspect script deps. |
| S7 | Shell/Git/Ghostty/Yazi | `home/aron/shell.nix` | Extract native snippets/config; omit rebuild aliases, nix-direnv, store paths, grok-imagine-only setup. Preserve independent Grok CLI prefs. |
| S8 | Desktop/bar | `modules/nixos/omarchy.nix`; `home/aron/omarchy.nix` | Translate personal deltas only. Bind `Super+Shift+B` to current bar visibility control; omit old idle timer, Nix provisioning/update changes. |
| S9 | OpenWhispr | App identity in `home/aron/packages.nix` | Install normal current release. Old embedded patch is excluded, not an install source. |
| S10 | Kdenlive | `home/aron/kdenlive.nix` | Normal install + minimal declared native prefs; no live config capture needed. Omit loader wrapper; OBS/GIMP normal install. |
| S11 | Browser/bookmarks | `home/aron/packages.nix` extension list; `home/aron/shell.nix` profile aliases; `modules/nixos/brave-policies.nix`; `home/aron/desktop.nix`; local bookmark checkout | Centralize sanitized bookmark/config exports; derive native browser policy/extension locations. |
| S12 | rclone / cptr | `home/aron/google-drive.nix`; `home/aron/cptr.nix` | Translate user units, native ExecStart/PATH; rclone auth separate; cptr isolated uv tool install. Preserve localhost binding/umask. |
| S13 | Remote/VPN | `modules/nixos/remote-access.nix`; `modules/nixos/mullvad.nix` | Native Tailscale/OpenSSH/mosh/Mullvad install; preserve tailnet-only exposure, key-only non-root SSH. |
| S14 | Extra apps/gaming/peripherals | `pkgs/file-explorer.nix`; `pkgs/onekey-wallet.nix`; `modules/nixos/gaming.nix`; `modules/nixos/openrazer.nix`; `modules/nixos/base.nix`; `home/aron/shell.nix` | Resolve upstream/native packages; retain selected prefs/game launch env; no Nix derivations, copied device IDs, wallet/game data. |
| S15 | Added skills | `dotfiles/agents/skills/graphify/`, `make-features-aron/`, `.system/`; `dotfiles/agents/SKILL_SOURCES.md` | Install graphifyy tool; shared discovery for authored/graphify skills; choose bundled or snapshot vendor skills per name, avoid duplicates. |

## Target filesystem tree — no fixed username

Repo root chosen by installer. `$HOME` = target user; XDG overrides take precedence. Installer owns symlink/copy/seed choice, mutable config handling, trust/path adaptation.

```text
$HOME/
  config/dev-config/             # suggested checkout; not mandatory
  projects/                      # repo manifest destinations
  .agents/
    GLOBAL_RULES.md
    skills/                      # canonical shared skill sources
  .pi/agent/                     # config, extensions, prompts; private auth separate
  .claude/                       # prefs, memory, commands; shared skills discovery
  .codex/                        # prefs, prompts/rules; vendor skill discovery
  .config/
    nvim/                        # full merged Lua config
    ghostty/                     # native terminal prefs
    yazi/                        # native file-manager prefs
    herdr/                       # native prefs/sounds; verify app convention
    hypr/                        # personal overrides for installed Omarchy version
    omarchy/                     # user shell/theme prefs
    systemd/user/                # rclone/cptr user units
    rclone/                      # private auth config, never repo content
    kdenliverc                   # writable Kdenlive preferences
  .local/bin/                    # script/uv entrypoints on PATH
  .dotnet/tools/                 # .NET global-tool shims on PATH
  GoogleDrive/                   # selected rclone mount
```

Config sources centralized; runtime state/auth/cache remain outside repo. Agent installer determines actual app conventions; tree describes roles, not mandatory absolute paths.

## Mandatory config-sync skill

Source: `dotfiles/agents/skills/sync-config-aron/`. Shared invocation policy: `dotfiles/agents/GLOBAL_RULES.md`, M1–M4.

- C1. Any agent update to mapped config invokes skill before edits, then after completed batch. Includes scripts, skills, manifests, deployment/setup docs. Manual/GUI changes require explicit invocation or next agent task; no watcher.
- C2. New repo `AGENTS.md` must declare `docs/deployment.md`, `docs/validation.md`, configured secret scanner, authoritative bootstrap remote/branch. Installer connects shared rules across Pi/Claude/Codex. Missing setup → blocked, never guessed ownership.
- C3. Sync sequence: inspect clean baseline → fetch/check ancestry → update portable sources → validate → secret review → exact-path staging → commit → verify reversibility/downstream effects → push → fetch/verify.
- C4. Success = entire repo clean including untracked files; local HEAD equals approved bootstrap remote tip; ahead/behind `0 0`. Clean pushed feature branch alone does not update bootstrap branch; report pending integration.
- C5. Preserve unrelated dirty work. Never reset/stash/discard/mass-stage, force-push, bypass hooks, or export secrets/runtime state to meet cleanliness target.
- C6. G3 gates irreversible actions locally or remotely, not remote effects alone. Validated reversible config sync to configured authorized remote/branch proceeds without per-push confirmation. Assess downstream CI/deploy effects, visibility, recovery; unknown reversibility → stop. History/secret/scope/system-apply safeguards remain. Copy updated global policy into new portable repo.

- [ ] S1. Include sync skill + adapter, shared M1–M4 policy, owner/deployment/validation/remote contract in portable repo. **verify:** agent editing mapped config loads skill automatically before/after batch.
- [ ] S2. Exercise sync workflow in disposable test repo, not user config. **verify:** clean/no-change, intentional change, unrelated dirt, secret finding, remote divergence, rejected push, feature-only delivery, reversible authorized push without confirmation, irreversible/unknown downstream effect each produce correct state; no unsafe cleanup.

## AGENTS.md — setup contract outline

- [ ] P1. Define core outcome, category-2 opt-ins, upstream-owned boundaries. **verify:** agent can name selected tools/config targets before changes.
- [ ] P2. Inspect fresh target; fetch reviewed repo revision; compare existing files; back up conflicts before replacement. Prefer supported native install methods; user executes system-level changes. **verify:** source revision recorded; conflict/backup map available.
- [ ] P3. Install missing tool capabilities; honor project runtime requirements. No copied Nix env flags; installer derives target paths from current user. **verify:** `command -v nvim pi claude codex gh node npm python uv dotnet cargo go gcc make jq rg fd fzf shellcheck`; `dotnet --list-sdks`; `node --version`.
- [ ] P4. Deploy complete Neovim config, shared rules/skills, agent prefs, terminal/shell config, custom CLIs. Seed mutable config without wiping runtime choices. **verify:** `nvim --headless '+checkhealth' '+qa'` reviewed; interactive Pi/Claude/Codex show shared skill discovery; `graphify --help`; script help checks; Herdr notification click focuses intended tab.
- [ ] P5. Resolve runtime-only extras; sanitize paths/trust/settings; reconnect auth outside Git. Check model/theme/extension compatibility against installed CLI versions. **verify:** no extension startup errors; expected models available; one shared skill copy; no stale Nix paths in deployable files.
- [ ] P6. Restore confirmed O1–O5/O7–O10 workflows; leave O6/O11 optional. **verify:** `Super+Shift+B` hides then shows bar; idle causes no auto-hide; normal OpenWhispr dictation works; scripts run on sample copies; Kdenlive/OBS/GIMP launch; browser extensions/bookmarks, Drive, remote access/VPN, cptr, selected extra apps pass smoke checks.
- [ ] P7. Prove real dev workflow: C#/Razor LSP/completion, breakpoint + test debug; TS/Angular navigation/format; representative project build/test; Playwright browser launch; rootless container if selected for project. **verify:** `dotnet build`; `dotnet test`; `npx playwright test` in relevant projects; `docker info` confirms intended daemon mode. Record project-specific cmds/results.
- [ ] P8. Repeat config deployment. **verify:** no duplicate shell lines/skills; no overwritten auth/runtime choices; no broken links; existing checkouts unchanged. Record remaining manual tasks.

These are future migration checks, not executed claims. Resolve exact package install cmds on target; avoid fossilizing current package names.

## Before retiring NixOS

- [ ] B1. Fetch latest Neovim source, merge personal overrides, export real files; record tested revision. Retain old pinned source only as recovery reference. **verify:** exported config contains `init.lua`, `lua/utils/path.lua`, full plugin tree; no `/nix/store` symlink dependency.
- [ ] B2. Reconcile live-vs-repo custom skills, Pi config/extensions, user-installed tools (`uv tool list`, `dotnet tool list -g`, `npm list -g --depth=0`). **verify:** every needed local-only item captured or reinstall source recorded; credentials never printed.
- [ ] B3. Review existing dirty config before export; preserve intended edits. **verify:** exported snapshot includes reviewed current changes; old working tree untouched.
- [ ] B4. Back up irreplaceable files separately: unpushed project work, local bookmark repo, personal notes, auth/recovery material, app data. **verify:** encrypted backup restore tested before any disk wipe.
- [ ] B5. Create clean new repo from allowlisted files, not copied old Git history. **verify:** secret scan + staged diff review pass; no scratch/session/cache files; no broad inherited trust. Remote target must be authorized; publication must have verified reversible effects. No separate per-push approval for reversible in-scope sync.

## Result / limits

Plan revised per user selections. Skill source snapshots + compatibility alias added to config; provenance recorded in `dotfiles/agents/SKILL_SOURCES.md`. Existing `home/aron/agents.nix:88` recursively deploys shared skills; no module change needed. New files staged on feature branch, not committed/pushed. No remote fetch, install, system apply, running desktop change, or deletion. Fresh Omarchy compatibility untested; vendor skill content not fully security-audited. Existing dirty config untouched.
