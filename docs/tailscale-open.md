# Tailscale launcher

Run `tailscale-open` as the desktop user, or choose **Tailscale (disconnect other VPNs)** in the application menu. Terminal stays open on failure. Enter sudo password there; complete browser sign-in if requested.

**VPN disconnection may expose traffic outside VPN protection. Use a local desktop session, not SSH over a VPN being disconnected. The launcher leaves other VPNs disconnected, including after cancellation or failure.**

## Behavior

- B1. Check required commands and obtain interactive sudo authorization before any VPN mutation. Never run the launcher itself with sudo: browser must run as the desktop user.
- B2. Disconnect Mullvad through its CLI; deactivate active NetworkManager `vpn`/`wireguard` connections except `tailscale0`; stop active `wg-quick@`, `openvpn@`, `openvpn-client@`, Nix `openvpn-`/`wireguard-` service instances. Verify Mullvad and service disconnects. Wired/Wi-Fi connectivity is not disabled.
- B3. Inspect remaining administratively-up tunnel interfaces. Unknown VPN clients (for example standalone Proton/Nord/OpenConnect not managed through the supported managers) are not killed. Remaining tunnels block launch with interface names; disconnect through their owning application and retry. A tunnel can have legitimate non-VPN use; this check intentionally refuses to guess.
- B4. Start existing `tailscaled.service`; run `tailscale up --timeout=120s` without changing stored preferences or forcing reauthentication. Poll local status; open an HTTPS `login.tailscale.com` AuthURL through `xdg-open` as desktop user. No auth URL/status dumps, temporary auth files, or root browser. Custom Headscale login domains require manual `sudo tailscale up --timeout=120s`.
- B5. Commands have 20-second limits, browser launch 15 seconds, sudo prompt 120 seconds, login loop 120 seconds. An in-flight status/browser command can finish after the loop deadline. Cancel with Ctrl+C. Success prints local Tailscale IPs; failure reports a bounded diagnostic rather than silently hanging.

## Install

- I1. NixOS: `home/aron/tailscale.nix` packages the mirrored Python script with native dependencies and a terminal desktop entry. Existing NixOS remote-access module enables Tailscale. Apply through user-run NixOS rebuild; no standalone Home Manager switch.
- I2. Native Omarchy: install capabilities from [deployment.md](deployment.md), [validation.md](validation.md). Required: Python 3, `tailscale`, `sudo`, `systemctl`, `ip` (iproute2), `xdg-open` (xdg-utils), desktop browser, terminal handler. `nmcli` (NetworkManager) and `mullvad` required when those managers are installed/active. Tailscale must have its native systemd unit installed.
- I3. Native source mapping: link `bin/tailscale-open` into absent `~/.local/bin/tailscale-open`; copy `desktop/launchers/tailscale-open.desktop` into absent `$XDG_DATA_HOME/applications/` (default `~/.local/share/applications/`). Review existing destination before replacing. Ensure `~/.local/bin` is in desktop session PATH. Root repo guide owns conflict handling; no installer runs implicitly.

## Limits / recovery

- L1. No firewall rules, DNS services, VPN kill-switch preferences, service enablement, or arbitrary interfaces/processes are changed. Unknown policy-only blockers (without a tunnel interface) may remain; login then fails or times out. Resolve through the owning app, never blanket-disable security services.
- L2. Mullvad lockdown mode can continue blocking after disconnect. Persistent VPN reconnect policies can recreate tunnels. Both require explicit app/config reconciliation; the launcher does not change those policies.
- L3. Reconnect a previously used VPN through its own app when finished with Tailscale. For Mullvad, `mullvad connect`; simultaneous VPN operation is not guaranteed. Service-managed VPNs remain stopped, not disabled.
- L4. This establishes Tailscale connectivity only; it does not configure remote desktop, app binding, SSH, or firewall exposure. Phone access requires an existing reachable service.

## Verification

Run `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p test_tailscale_open.py -v` in either config repo. Tests mock privilege/network/browser commands: no VPN is disconnected during validation. Mirrored script/tests must stay byte-identical; runtime depends only on the installed copy, not a sibling checkout.
