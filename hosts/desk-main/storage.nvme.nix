# Crucial P310 1 TB NVMe — ESP + Btrfs subvolumes. The migration target.
#
# Reached only through ../desk-main/nvme.nix -> flake output `desk-main-nvme`.
# Building this output while running from the Samsung is fine; *switching* to it
# is not, and cannot happen by accident because `rebuild` resolves the output
# from the running root disk (see nixos-host in ./common.nix).
{ lib, pkgs, ... }:
let
  disks = import ./disks.nix;

  rootDevice = "/dev/disk/by-uuid/${disks.nvme.root}";

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

  # nofail on /.snapshots only. A missing @snapshots subvolume (deleted by a
  # snapshot tool, or absent after a restore) would otherwise fail
  # local-fs.target and drop the boot into emergency mode for a subvolume
  # nothing needs at boot. /, /nix and /home stay strict — those must fail loudly.
  fileSystems."/.snapshots" = subvol "@snapshots" // {
    options = (subvol "@snapshots").options ++ [ "nofail" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/${disks.nvme.boot}";
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
    device = "/dev/disk/by-uuid/${disks.data}";
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

  # Refuse to leave bootloader entries on the Samsung's ESP. See ./esp-guard.nix.
  boot.loader.systemd-boot.extraInstallCommands = import ./esp-guard.nix {
    inherit pkgs;
    expectedEspUuid = disks.nvme.boot;
    thisOutput = "desk-main-nvme";
  };

  # Btrfs root is live in this output, so scrubbing is meaningful.
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  # zram from modules/nixos/base.nix. The old 4 GB NVMe swap partition is
  # destroyed by the wipe; a stale swapDevices entry stalls every boot ~90 s.
  swapDevices = lib.mkForce [ ];
}
