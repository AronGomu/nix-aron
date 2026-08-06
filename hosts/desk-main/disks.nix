# Every disk UUID desk-main knows about, in one place.
#
# This machine has two bootable systems attached at once: the Samsung 860 EVO
# (ext4, the rollback system) and the Crucial P310 (Btrfs, the migration
# target). They are separate flake outputs — desk-main-samsung and
# desk-main-nvme — so a rebuild can never hand one disk's fstab to the other.
#
# UUIDs, not labels: with both disks attached, /dev/disk/by-label/NIXROOT would
# resolve non-deterministically. UUIDs cannot collide.
#
# Written by docs/migration/fill-uuids.sh after mkfs; the `root =` / `boot =`
# lines under `nvme` are matched by that script's sed, so keep them one per line.
{
  # Samsung 860 EVO 500 GB — sdb, stock ext4 install.
  samsung = {
    root = "4c7138e6-9d27-4c85-8004-60d7621b982e"; # sdb2, ext4, label nixos
    boot = "DFD1-432B"; # sdb1, vfat ESP
  };

  # Crucial P310 1 TB NVMe — nvme0n1, ESP + Btrfs subvolumes.
  nvme = {
    root = "5b251757-c14c-4641-aec5-cea83857290b"; # nvme0n1p2, btrfs, label NIXROOT
    boot = "61EA-07B3"; # nvme0n1p1, vfat, label NIXBOOT
  };

  # 4 TB HGST — sda1, NTFS, label Data. Shared with the old Windows install.
  # Known and stable; not touched by the migration.
  data = "B41E0A3F1E09FB5E";
}
