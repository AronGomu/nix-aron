# Copy this folder:
#   cp -r hosts/_template hosts/<name>
# Then:
#   1. edit networking.hostName below
#   2. generate hardware-configuration.nix on the machine
#   3. write storage.nix (see storage.btrfs.nix example)
#   4. toggle optional module imports
#   5. add nixosConfigurations.<name> in flake.nix
{
  imports = [
    ./hardware-configuration.nix
    ./storage.nix

    # shared
    ../../modules/nixos

    # optional — uncomment per machine
    # ../../modules/nixos/nvidia.nix
    # ../../modules/nixos/gaming.nix
  ];

  networking.hostName = "CHANGE-ME";

  system.stateVersion = "26.05";
}
