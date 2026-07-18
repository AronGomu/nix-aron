{
  imports = [
    ./hardware-configuration.nix
    ./storage.nix
    ../../modules/nixos
  ];

  networking.hostName = "nixos";

  system.stateVersion = "26.05";
}
