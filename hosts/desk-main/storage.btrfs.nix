# desk-main target layout: Crucial P310 1 TB NVMe, ESP + Btrfs subvolumes.
#
# Replaces ./storage.nix in ./default.nix — do NOT import both. Importing both
# raises a conflicting-definition error on fileSystems."/mnt/data", which is the
# intended fail-loud behaviour (there are no mkForce escapes in this file).
#
# The two rootUuid/bootUuid values below are placeholders. Fill them AFTER the
# disk is partitioned and formatted, with:
#
#     docs/migration/fill-uuids.sh
#
# UUIDs, not labels: the Samsung 860 EVO stays attached through the install and
# is kept indefinitely as the rollback system. Two disks that both answer to a
# NIXROOT label would make /dev/disk/by-label/NIXROOT resolve
# non-deterministically — a silent wrong-root mount at boot. UUIDs cannot
# collide, so this stays correct no matter what is plugged in.
{ lib, ... }:
let
  # nvme0n1p2 — btrfs, label NIXROOT
  rootUuid = "5b251757-c14c-4641-aec5-cea83857290b";
  # nvme0n1p1 — vfat ESP, label NIXBOOT
  bootUuid = "61EA-07B3";
  # sda1 — 4 TB HGST, NTFS, label Data. Known and stable; not touched by the migration.
  dataUuid = "B41E0A3F1E09FB5E";

  rootDevice = "/dev/disk/by-uuid/${rootUuid}";

  btrfsOptions = [
    "compress=zstd"
    "noatime"
  ];

  subvol = name: {
    device = rootDevice;
    fsType = "btrfs";
    options = [ "subvol=${name}" ] ++ btrfsOptions;
  };
in
{
  fileSystems."/" = subvol "@";
  fileSystems."/home" = subvol "@home";
  fileSystems."/nix" = subvol "@nix";
  fileSystems."/.snapshots" = subvol "@snapshots";

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/${bootUuid}";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # 4 TB HGST — label Data (shared with the old Windows install; holds F:\rescue).
  # In-kernel ntfs3, not the FUSE driver. fmask=0133 gives files 0644, dirs 0755;
  # a bare umask=0022 would mark every file executable.
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/${dataUuid}";
    fsType = "ntfs3";
    options = [
      "nofail"
      "x-systemd.device-timeout=10s"
      "x-systemd.automount"
      "x-gvfs-show"
      "x-gvfs-name=Data"
      "uid=1000"
      "gid=100"
      "fmask=0133"
      "dmask=0022"
      "windows_names"
    ];
  };

  # Btrfs root is live from here on, so scrubbing is meaningful.
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  # zram from modules/nixos/base.nix. The old 4 GB NVMe swap partition is
  # destroyed by the wipe; a stale swapDevices entry stalls every boot ~90 s.
  swapDevices = lib.mkForce [ ];
}
