# Example target layout (labels NIXBOOT / NIXROOT). Copy over storage.nix after
# partitioning per INSTALL.md. Adjust /mnt/data if no shared NTFS disk.
{ lib, ... }:
let
  btrfsOptions = [
    "compress=zstd"
    "noatime"
  ];
in
{
  fileSystems."/" = {
    device = lib.mkForce "/dev/disk/by-label/NIXROOT";
    fsType = lib.mkForce "btrfs";
    options = lib.mkForce ([ "subvol=@" ] ++ btrfsOptions);
  };

  fileSystems."/home" = {
    device = lib.mkForce "/dev/disk/by-label/NIXROOT";
    fsType = lib.mkForce "btrfs";
    options = lib.mkForce ([ "subvol=@home" ] ++ btrfsOptions);
  };

  fileSystems."/nix" = {
    device = lib.mkForce "/dev/disk/by-label/NIXROOT";
    fsType = lib.mkForce "btrfs";
    options = lib.mkForce ([ "subvol=@nix" ] ++ btrfsOptions);
  };

  fileSystems."/.snapshots" = {
    device = lib.mkForce "/dev/disk/by-label/NIXROOT";
    fsType = lib.mkForce "btrfs";
    options = lib.mkForce ([ "subvol=@snapshots" ] ++ btrfsOptions);
  };

  fileSystems."/boot" = {
    device = lib.mkForce "/dev/disk/by-label/NIXBOOT";
    fsType = lib.mkForce "vfat";
    options = lib.mkForce [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # Optional shared Windows data disk — delete if absent.
  # fileSystems."/mnt/data" = {
  #   device = "/dev/disk/by-label/Data";
  #   fsType = "ntfs3";
  #   options = [
  #     "nofail"
  #     "x-systemd.automount"
  #     "uid=1000"
  #     "gid=100"
  #     "umask=0022"
  #   ];
  # };

  swapDevices = lib.mkForce [ ];
}
