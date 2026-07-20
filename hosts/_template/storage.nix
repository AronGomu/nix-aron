# Placeholder mounts — replace before install/rebuild.
# Prefer /dev/disk/by-label or by-uuid. Never hardcode /dev/sdX.
# See storage.btrfs.nix for the standard Btrfs daily-driver layout.
{ lib, ... }:
{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/REPLACE";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = lib.mkForce [ ];
}
