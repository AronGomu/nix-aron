{
  imports = [
    ./hardware-configuration.nix
    ./storage.nix

    # shared
    ../../modules/nixos

    # this machine only
    ../../modules/nixos/nvidia.nix
    ../../modules/nixos/gaming.nix
    ../../modules/nixos/openrazer.nix
  ];

  networking.hostName = "desk-main";

  desktop.end4.enable = true;

  system.stateVersion = "26.05";
}
