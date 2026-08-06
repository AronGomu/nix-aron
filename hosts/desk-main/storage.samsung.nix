# Samsung 860 EVO 500 GB (sdb) — stock ext4 install, the rollback system.
#
# Reached only through ../desk-main/samsung.nix -> flake output
# `desk-main-samsung`. Never imported alongside ./storage.nvme.nix; the two
# outputs are the isolation mechanism, so there is nothing to guard against here.
{ lib, pkgs, ... }:
let
  disks = import ./disks.nix;
in
{
  # Refuse to leave bootloader entries on the NVMe's ESP. See ./esp-guard.nix.
  boot.loader.systemd-boot.extraInstallCommands = import ./esp-guard.nix {
    inherit pkgs;
    expectedEspUuid = disks.samsung.boot;
    thisOutput = "desk-main-samsung";
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/${disks.samsung.root}";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/${disks.samsung.boot}";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  # 4 TB HGST — label Data (shared with Windows). by-label, not by-uuid, purely
  # so this layout keeps producing the fstab the running system already has:
  # changing the device string would make the next `switch` remount /mnt/data.
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
