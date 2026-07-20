# Placeholder. On target machine run:
#   nixos-generate-config --show-hardware-config > hosts/<name>/hardware-configuration.nix
# Keep kernel/modules here. Put mounts in storage.nix.
{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    # filled by nixos-generate-config
  ];
  boot.kernelModules = [
    # e.g. "kvm-amd" or "kvm-intel"
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.enableRedistributableFirmware = lib.mkDefault true;
}
