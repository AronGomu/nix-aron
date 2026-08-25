# Grill: install broodwar (desk-main)

## Facts (scout)

- No `starcraft`/`battlenet` package in nixpkgs; only `stormlib` (MPQ library) exists — source: `nix eval` on nixpkgs attrs
- nixpkgs has lutris 0.5.22, wineWowPackages.stable 11.0, bottles 63.2, winetricks 20260125 — source: `nix eval --raw nixpkgs#<pkg>.version`
- Repo currently has no wine/lutris/bottles anywhere; only `modules/nixos/gaming.nix` with Steam — source: `grep -rn -i 'wine|lutris|bottles' --include='*.nix'`
- `modules/nixos/gaming.nix` is imported by `hosts/desk-main/common.nix`; unfree allowlist is `lib/allow-unfree.nix` (steam entries only) — source: repo read
- HM user apps live in `home/aron/packages.nix` (`home.packages`), rofi entries in `home/aron/end4.nix` (`xdg.desktopEntries`) — source: repo read
- OpenBW/BWAPI is already built at `~/projects/bwapi/build`; `~/projects/openbw-env/run.sh` blocks on missing `Patch_rt.mpq BrooDat.mpq StarDat.mpq` in `run/data/`, and honours `OPENBW_MPQ_PATH` — source: earlier session, `openbw-env/README.md`
- Blizzard's download page now funnels every classic title through the Battle.net desktop app (Windows/Mac binaries only) — source: fetch of blizzard.com download confirmation page

## Round 1 — Target & delivery path

| # | Question | Answer | Precision |
| --- | --- | --- | --- |
| 1 | What does "installed" have to mean? | Both: playable Brood War under Wine AND MPQs wired into openbw-env | |
| 2 | Which StarCraft do you have access to? | Free classic Anthology via Battle.net account (have or will create) | |
| 3 | Which Wine runner? | Lutris 0.5.22 + community Battle.net/StarCraft install script | |
| 4 | Config layer? | Home Manager, `home/aron/packages.nix` | |
| 5 | Launcher entry? | Yes, declarative `xdg.desktopEntries` in `home/aron/end4.nix` | |
| 6 | MPQ handoff? | `OPENBW_MPQ_PATH` pointed at the wine prefix StarCraft dir | |

## Facts (scout, round 2)

- `hardware.graphics.enable32Bit = true` already set in `modules/nixos/nvidia.nix` — no system-layer edit needed for 32-bit Wine
- `lutris` evaluates fine under the repo's existing `lib/allow-unfree.nix` (steam entries cover its closure) — no allowlist edit needed
- nixpkgs `lutris` is a bwrap/FHS wrapper (`lutris-0.5.22-bwrap`), so Lutris-downloaded Wine runners and install scripts work on NixOS
- 808 GB free on /home — prefix size is not a constraint
- `~/Games` does not exist yet

## Round 2 — Package set, prefix, install run

| # | Question | Answer | Precision |
| --- | --- | --- | --- |
| 1 | Which packages? | `lutris` + `wineWowPackages.stable` + `winetricks` | |
| 2 | Prefix location? | Lutris default `~/Games/battlenet` | |
| 3 | Who drives the install? | I run the Lutris CLI installer up to the login screen, then hand over | |
| 4 | Where is `OPENBW_MPQ_PATH`? | HM `home.sessionVariables` | |
| 5 | Launcher entry? | `lutris:rungame/<slug>` URI, follow-up commit after install | |

## Facts (scout, round 3)

- Lutris API has installer `starcraft-battlenet` (runner: wine, version "Battle.net") for game slug `starcraft`; also `battlenet-standard` for the launcher alone — source: `lutris.net/api/installers/starcraft`
- HM session variables already live in `home/aron/shell.nix:54` (`home.sessionVariables`) — source: repo grep
- HM package list is `home/aron/packages.nix:303`, grouped by comment headers (`# Daily desktop`, `# Development`) — source: repo read

## Shared understanding

- **Goal**: StarCraft: Brood War playable on desk-main through Lutris/Wine, and the same install's MPQ files feeding the already-built OpenBW/BWAPI workspace in `~/projects/openbw-env`.
- **Settled**
  - Scope covers both playing and the OpenBW data handoff.
  - Game source: free StarCraft Anthology through your Battle.net account.
  - Runner: Lutris, community installer `starcraft-battlenet`.
  - Config layer: Home Manager only — `lutris`, `wineWowPackages.stable`, `winetricks` in `home/aron/packages.nix`.
  - Prefix: Lutris default `~/Games/battlenet`.
  - Install run: I drive the Lutris CLI installer up to the Battle.net login screen; you enter credentials and 2FA.
  - `OPENBW_MPQ_PATH` defined in `home.sessionVariables` (`home/aron/shell.nix`).
  - Rofi/desktop entry: `lutris:rungame/<slug>` in `home/aron/end4.nix`, written in a follow-up commit once the slug exists and launches.
- **Assumptions**
  - MPQ dir will be `~/Games/battlenet/drive_c/Program Files (x86)/StarCraft`; verified after the install and corrected if wrong.
  - No system-layer edit needed: `hardware.graphics.enable32Bit` is already true, and `lutris` passes the existing unfree allowlist.
  - Two commits: (1) packages + env var now, (2) desktop entry + any path correction after the install.
- **Out of scope**
  - gamemode / mangohud / DXVK tuning, StarCraft: Remastered purchase, Battle.net ladder or multiplayer setup, an OpenBW rofi entry, ICCup or other third-party launchers.
- **Residual risk**
  - Battle.net's installer under Wine is historically flaky; failure here is a runtime problem, not a config one.
  - Whether the free Anthology is still offered inside the Battle.net app is unverified from Linux. If it is not, the path is blocked until you buy Remastered or supply game files.
  - OpenBW targets 1.16.1/1.18 MPQs; files from a current Battle.net install may not load. Untested until the data exists.
