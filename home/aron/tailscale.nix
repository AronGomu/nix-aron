{ pkgs, ... }:
let
  tailscale-open = pkgs.writeShellApplication {
    name = "tailscale-open";
    runtimeInputs = with pkgs; [
      tailscale
      iproute2
      systemd
      xdg-utils
      networkmanager
      mullvad-vpn
    ];
    # sudo must resolve the system's privileged wrapper, not a Nix store binary.
    text = ''
      exec ${pkgs.python3}/bin/python3 ${./scripts/tailscale-open.py} "$@"
    '';
  };
in
{
  home.packages = [ tailscale-open ];
  xdg.desktopEntries.tailscale-open = {
    name = "Tailscale (disconnect other VPNs)";
    comment = "Disconnect known VPNs, connect Tailscale, open browser login when needed";
    exec = "${tailscale-open}/bin/tailscale-open";
    icon = "network-vpn";
    terminal = true;
    categories = [ "Network" ];
  };
}
