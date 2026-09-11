# Ownership / deployment map

Root [AGENTS.md](../AGENTS.md) owns sync policy: existing `origin` (`AronGomu/nix-aron`), authoritative bootstrap branch `main`. This repo supplies NixOS + integrated Home Manager; native Omarchy portable sources live separately in `AronGomu/dotfiles`.

| ID | Owned source | Runtime destination / deployment |
|---|---|---|
| D1 | `flake.nix`, `flake.lock`, `hosts/`, `modules/`, `lib/` | NixOS configuration and package composition. Host/disk-specific outputs selected via `nixos-host`. System activation is user-run only; never mutate boot/disk/network policy as a side effect of config sync. |
| D2 | `home/aron/*.nix`, `home/aron/scripts/` | Integrated Home Manager packages, shell, desktop entries, user-service declarations. `home/aron/default.nix` imports focused modules. Changes apply through the NixOS rebuild, never standalone HM. |
| D3 | `dotfiles/agents/`, `dotfiles/pi/`, `dotfiles/claude/`, `dotfiles/codex/` | `home/aron/agents.nix` maps source into user config/shared skills. Preserve its explicit writable-source/symlink policy; never copy auth, trust, session data, or runtime caches into Git. |
| D4 | `home/aron/tailscale.nix`, `home/aron/scripts/tailscale-open.py` | `tailscale-open` on user PATH and `tailscale-open.desktop` via HM. Packaged Python, Tailscale, iproute2, systemd, xdg-utils, NetworkManager, Mullvad. Privileged sudo wrapper comes from host PATH. Existing `modules/nixos/remote-access.nix` owns tailscaled; no firewall changes. |
| D5 | `AGENTS.md`, `NIX-CHEATSHEET.md`, `docs/`, `tests/` | Source-owned guidance and validation; no independent system apply. `NIX-CHEATSHEET.md` also mapped into HOME by agents module. |

## Tailscale portable mirror

- M1. `home/aron/scripts/tailscale-open.py` mirrors native dotfiles `bin/tailscale-open` byte-for-byte. `tests/test_tailscale_open.py` and `docs/tailscale-open.md` also match both repos. Change and test both intentionally; do not add cross-checkout runtime dependencies.
- M2. Runtime launcher disconnects known VPN connections only when user invokes it. Auth remains in tailscaled/browser, never portable source. No firewall, DNS service, kill-switch preference, service enablement, or login-on-boot changes.
- M3. Setup instructions and limitations: [tailscale-open.md](tailscale-open.md). Validation: [validation.md](validation.md). Manual changes require explicit sync; no automatic watcher.
