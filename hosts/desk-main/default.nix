{
  imports = [
    ./hardware-configuration.nix
    ./storage.nix

    # shared
    ../../modules/nixos

    # this machine only
    ../../modules/nixos/nvidia.nix
    ../../modules/nixos/gaming.nix
  ];

  networking.hostName = "desk-main";

  system.stateVersion = "26.05";
}
