#!/usr/bin/env bash
# §4 step 5 — create the Btrfs subvolumes on the freshly formatted NVMe and
# mount the target tree at /mnt. Non-destructive to anything outside the NVMe,
# but it does mount over /mnt, so it refuses to run if /mnt is already in use.
#
# Run as root:  sudo ./docs/migration/mount-target.sh
set -euo pipefail

DISK="/dev/disk/by-id/nvme-CT1000P310SSD8_252550DB0A3E"
BOOT="$DISK-part1"
ROOT="$DISK-part2"

[ "$(id -u)" = 0 ] || { echo "must run as root"; exit 1; }

# The Data HDD lives at /mnt/data. Mounting the new root over /mnt would hide
# it and, worse, a later rsync could write into the hidden mountpoint.
#
# It is mounted with x-systemd.automount, so plain `umount` is not enough: an
# autofs trigger stays mounted at /mnt/data and any stat() of that path — even
# `mountpoint -q` — re-mounts the disk. Stop the unit instead. systemd starts
# it again on the next boot; nothing in the config changes.
if findmnt -rno TARGET /mnt >/dev/null 2>&1; then
  echo "FATAL: /mnt is already a mountpoint"; findmnt -R /mnt; exit 1
fi
if systemctl is-active --quiet mnt-data.automount || findmnt -rno TARGET /mnt/data >/dev/null 2>&1; then
  echo "--- stopping mnt-data.automount and mnt-data.mount"
  systemctl stop mnt-data.automount mnt-data.mount || true
fi
if findmnt -rno TARGET,FSTYPE /mnt/data 2>/dev/null | grep -q .; then
  echo "FATAL: could not free /mnt/data:"; findmnt -rno TARGET,SOURCE,FSTYPE /mnt/data
  exit 1
fi

[ -b "$BOOT" ] && [ -b "$ROOT" ] || { echo "FATAL: $BOOT / $ROOT missing"; exit 1; }
[ "$(lsblk -dno FSTYPE "$ROOT")" = "btrfs" ] || { echo "FATAL: $ROOT is not btrfs"; exit 1; }
[ "$(lsblk -dno FSTYPE "$BOOT")" = "vfat"  ] || { echo "FATAL: $BOOT is not vfat";  exit 1; }

OPTS="compress=zstd,noatime"

echo "--- create subvolumes"
mount "$ROOT" /mnt
for sv in @ @home @nix @snapshots; do
  if [ -d "/mnt/$sv" ]; then
    echo "    $sv already exists"
  else
    btrfs subvolume create "/mnt/$sv"
  fi
done
btrfs subvolume list /mnt | sed 's/^/    /'
umount /mnt

echo "--- mount target tree"
mount -o "subvol=@,$OPTS" "$ROOT" /mnt
mkdir -p /mnt/boot /mnt/home /mnt/nix /mnt/.snapshots /mnt/mnt/data
mount -o "subvol=@home,$OPTS"      "$ROOT" /mnt/home
mount -o "subvol=@nix,$OPTS"       "$ROOT" /mnt/nix
mount -o "subvol=@snapshots,$OPTS" "$ROOT" /mnt/.snapshots
mount "$BOOT" /mnt/boot

echo
findmnt -R /mnt | sed 's/^/  /'
echo
echo "Next: docs/migration/fill-uuids.sh  (as your normal user, not root)"
