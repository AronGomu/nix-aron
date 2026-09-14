{ pkgs, ... }:
{
  # GUI + CLI client from https://mullvad.net/
  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };
}
