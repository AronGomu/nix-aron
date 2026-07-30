# desk-main active layout: Samsung 860 EVO 500GB (sdb), ext4 stock install.
# Target Btrfs layout in ./storage.btrfs.nix — use after reinstall per INSTALL.md.
{ lib, ... }:
{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/4c7138e6-9d27-4c85-8004-60d7621b982e";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/DFD1-432B";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  # 4 TB HGST — label Data (shared with Windows)
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-label/Data";
    fsType = "ntfs3";
    options = [
      "nofail"
      "x-systemd.automount"
      "x-gvfs-show"
      "x-gvfs-name=Data"
      "uid=1000"
      "gid=100"
      "umask=0022"
    ];
  };

  # zram from modules/nixos/base.nix
  swapDevices = lib.mkForce [ ];
}
