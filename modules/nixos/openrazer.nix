{ pkgs, ... }:
{
  hardware.openrazer = {
    enable = true;
    users = [ "aron" ];
  };

  environment.systemPackages = with pkgs; [
    polychromatic
    razer-cli
  ];
}
