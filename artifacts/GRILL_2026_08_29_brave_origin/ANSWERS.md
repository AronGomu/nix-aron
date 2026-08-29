# Grill: Brave Origin as default browser

## Facts (resolved before round 1)

- Brave Origin is free on Linux, paid on Windows/macOS — source: `curl https://brave.com/origin/`, FAQ "Why is Brave Origin free for Linux users, but not users of other operating systems?" / "We're making Origin free to all Linux users"
- `brave-origin` 1.93.138 exists in current `nixos-unstable`, MPL-2.0, `unfree=false`, platforms include `x86_64-linux` — source: `nix eval github:NixOS/nixpkgs/nixos-unstable#brave-origin.meta`
- Locked repo input `nixpkgs-unstable` rev `241313f4e8e5` has **no** `brave-origin` attr — source: `nix eval` on `builtins.getFlake` inputs → `{"has":false,"ver":"MISSING"}`
- Origin data dir `~/.config/BraveSoftware/Brave-Origin`; Brave uses `Brave-Browser` — source: `strings /nix/store/g5k9h4l84s1rnvzk7hwj27sy9cqn6kv1-brave-origin-1.93.138/opt/brave.com/brave-origin/brave | grep BraveSoftware`
- Origin reads `/etc/brave/policies` — same dir as Brave → `modules/nixos/brave-policies.nix` applies unchanged — source: same `strings` run
- Origin ships `bin/brave-origin`, `brave-origin.desktop` + `com.brave.Origin.desktop`, icon `brave-origin` (hicolor 16→256 px) — source: `ls $out/bin`, `ls $out/share/applications`, `find $out/share/icons`
- Current Brave `150.1.92.141` (nixpkgs-unstable pin), Origin = Chromium 151 / 1.93.138 → profile migration is an upgrade, not a downgrade — source: `brave --version`, `~/.config/BraveSoftware/Brave-Browser/Last Version`
- Existing profile dir 1.8 G, profiles `Default` + `Profile 1` — source: `du -sh`, `Local State` `profile.info_cache`
- 87 `brave` references across `home/aron/{desktop,shell,packages,end4}.nix`, `lib/allow-unfree.nix`, `modules/nixos/{brave-policies,default}.nix` — source: `grep -rn brave --include=*.nix -io . | wc -l`
- `end4.nix` holds 35 `icon = "brave-browser"` + 35 `exec = ... brave ...` lines, plus `browser = "brave"` (line 266) and `hl.exec_cmd("brave --new-window", ...)` (line 310) — source: `grep -c`
- HM `programs.brave` External Extensions JSON shape = `{"external_update_url":"https://clients2.google.com/service/update2/crx"}`, path `${xdg.configHome}/BraveSoftware/Brave-Browser/External Extensions/${id}.json` — source: `modules/programs/chromium.nix:244-266` in HM input `igashb29hcn1575501sxf67im06zjvzx-source`
- Origin removes Rewards, Wallet, AI (Leo), VPN — source: `brave-origin.meta.longDescription`

## Round 1 — Install source, coexistence, default wiring, extensions, profile migration

| #   | Question                                          | Answer                                                                                 | Precision |
| --- | ------------------------------------------------- | -------------------------------------------------------------------------------------- | --------- |
| 1   | Where should the `brave-origin` package come from? | Bump the `nixpkgs-unstable` lock                                                        | —         |
| 2   | Keep regular Brave installed alongside Origin?     | Keep both; remove Brave in a later commit after Origin proves itself                    | —         |
| 3   | How should Origin get the declarative extensions?  | Explicit `home.file` writes of the same extension JSONs into `Brave-Origin/External Extensions` | —         |
| 4   | How far should the default-browser rewiring go?    | Full sweep: mime, `BROWSER`, end4 `variables.lua`, all rofi entries, icons, aliases     | —         |
| 5   | How should current Brave settings reach Origin?    | Recursive copy of the profile dirs `Brave-Browser` → `Brave-Origin`                     | —         |
| 6   | Which profiles should be copied?                   | Both `Default` and `Profile 1`, plus `Local State`                                      | —         |
| 7   | Who runs the profile copy, and when?               | I print the exact command; user runs it after closing Brave                             | —         |

## Shared understanding

- Spec level: 2 — target reached
- Goal: install `brave-origin`, make it the default browser everywhere in the nix config, and migrate the existing Brave profile data to it.

### Settled

1. `nix flake update nixpkgs-unstable` (that input only) to a rev containing `brave-origin` ≥ 1.93.138.
2. `home/aron/packages.nix`: add `pkgsUnstable.brave-origin` to the unstable package list. `programs.brave` block and `pkgsUnstable.brave` stay as-is (coexistence).
3. `home/aron/packages.nix` (or nearest existing pattern): five `home.file` entries writing `{"external_update_url":"https://clients2.google.com/service/update2/crx"}` to `.config/BraveSoftware/Brave-Origin/External Extensions/<id>.json` for Unhook `khncfooichmfjbepaaaebmommgaepoid`, SponsorBlock `mnjggcdmjocbbbhaepdhchncahnbgone`, Enhancer for YouTube `ponfpcnoihfmfllpaingbgckeeldkhle`, Dark Reader `eimadpbcbfnmbkopoojfekhnkhdbieeh`, Floccus `fnaicdffflnofjppbagibeoednhnbjhg`.
4. Full sweep to Origin:
   - `home/aron/desktop.nix`: `text/html`, `x-scheme-handler/http`, `x-scheme-handler/https` → `brave-origin.desktop`
   - `home/aron/shell.nix`: `BROWSER = "brave-origin"`; `brave-personal` / `brave-mtgones` aliases keep their names, exec `brave-origin --profile-directory=...`
   - `home/aron/end4.nix`: `browser = "brave-origin"`, `hl.exec_cmd("brave-origin --new-window", ...)`, all 35 `exec` lines → `brave-origin`, all 35 `icon = "brave-browser"` → `icon = "brave-origin"`
5. `modules/nixos/brave-policies.nix` unchanged — Origin reads the same `/etc/brave/policies`.
6. Profile migration by recursive copy of the whole `Brave-Browser` dir (both profiles + `Local State`) to `Brave-Origin`. Source untouched. Command is printed, user runs it with Brave closed.
7. Commit + push. User runs the rebuild (K1).

### Assumptions

- Alias names `brave-personal` / `brave-mtgones` stay; only their target binary changes.
- `lib/allow-unfree.nix` untouched — `brave-origin` is `unfree = false`.
- The `brave` command remains available (package still installed), so old Brave stays reachable for the trial period.
- Extension JSONs are written declaratively even though the profile copy already carries the installed extensions; they are idempotent.

### Out of scope

- Removing `pkgsUnstable.brave` and the `programs.brave` block — deferred to a later commit per Q2.
- Deleting the old 1.8 G `Brave-Browser` dir.
- Brave Sync chain setup.
- `lib/allow-unfree.nix` cleanup.

### Residual risk

- Bumping `nixpkgs-unstable` also moves `brave`, `ghostty`, `obs-studio`, `claude-code`, `codex`, `grok-cli`, `pi-coding-agent` — accepted by the user in Q1. Breakage surfaces at rebuild, not at commit time.
