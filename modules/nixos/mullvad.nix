{ pkgsUnstable, ... }:
{
  # GUI + CLI client from https://mullvad.net/
  services.mullvad-vpn = {
    enable = true;
    package = pkgsUnstable.mullvad-vpn;
  };
}
