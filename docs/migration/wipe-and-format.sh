#!/usr/bin/env bash
# §4 — DESTRUCTIVE. Wipes /dev/nvme0n1 (Crucial P310) and lays down the target
# layout: 1 GB vfat ESP (NIXBOOT) + rest Btrfs (NIXROOT) with subvolumes.
#
# Destroys the Windows install and the old 232 GB ext4 NixOS on that disk.
# There is no image and no undo. The Samsung 860 EVO (sdb) is never touched.
#
# Run as root:  sudo ./docs/migration/wipe-and-format.sh
set -euo pipefail

DISK="/dev/disk/by-id/nvme-CT1000P310SSD8_252550DB0A3E"
EXPECT_MODEL="CT1000P310SSD8"
EXPECT_SIZE="931.5G"

[ "$(id -u)" = 0 ] || { echo "must run as root"; exit 1; }

# ---- re-assert the target, independently of preflight ----------------------
# preflight ran minutes ago and device names can move. Everything below is
# keyed off the by-id path, but verify it still resolves to what we think.
REAL="$(readlink -f "$DISK")"
case "$REAL" in *p[0-9]) echo "FATAL: $DISK resolves to a partition"; exit 1 ;; esac
NAME="$(basename "$REAL")"
[ "$(lsblk -dno MODEL "$REAL")" = "$EXPECT_MODEL" ] || { echo "FATAL: wrong model"; exit 1; }
[ "$(lsblk -dno SIZE  "$REAL")" = "$EXPECT_SIZE"  ] || { echo "FATAL: wrong size";  exit 1; }

# The running root must not live on the target. This is the one check that
# turns a typo into a survivable mistake.
ROOTSRC="$(findmnt -no SOURCE /)"
case "$(readlink -f "$ROOTSRC")" in
  "$REAL"*) echo "FATAL: running root $ROOTSRC is ON the target disk"; exit 1 ;;
esac

# Nothing from the target may be mounted.
if findmnt -rno SOURCE | grep -q "^$REAL"; then
  echo "FATAL: something from $REAL is mounted:"; findmnt -rno SOURCE,TARGET | grep "^$REAL"
  exit 1
fi

echo "=== target $DISK -> $REAL  ($EXPECT_MODEL, $EXPECT_SIZE)"
echo "=== about to destroy:"
lsblk -o NAME,SIZE,FSTYPE,LABEL "$REAL" | sed 's/^/    /'
echo

# ---- swap ------------------------------------------------------------------
# nvme0n1p5 is a 4 GB swap partition. If the kernel activated it at boot it
# holds a live reference and wipefs will fail.
for p in "$REAL"p*; do
  if swapon --show=NAME --noheadings | grep -qx "$p"; then
    echo "--- swapoff $p"
    swapoff "$p"
  fi
done

# ---- wipe ------------------------------------------------------------------
# Per-partition wipefs FIRST, then zap. Order matters: --zap-all only clears
# the GPT structures at the head and tail of the disk. The ntfs and ext4
# superblocks sitting at 693 GB and 931 GB would survive it and later confuse
# blkid into reporting phantom filesystems.
echo "--- wipefs each partition"
for p in "$REAL"p*; do
  [ -b "$p" ] || continue
  echo "    $p"
  wipefs -a "$p"
done

echo "--- sgdisk --zap-all"
sgdisk --zap-all "$REAL"
echo "--- wipefs whole disk"
wipefs -a "$REAL"

# ---- partition -------------------------------------------------------------
# 1 GB ESP: the NixOS default is 512 MB, which fits ~3 generations of kernel +
# initrd. 1 GB removes a class of "no space left on /boot" failures at update
# time, and costs nothing on a 1 TB disk.
echo "--- partition"
sgdisk -n 1:0:+1G -t 1:ef00 -c 1:NIXBOOT "$REAL"
sgdisk -n 2:0:0   -t 2:8300 -c 2:NIXROOT "$REAL"

# partprobe is in parted, which is not installed. blockdev --rereadpt is
# util-linux and does the same ioctl.
blockdev --rereadpt "$REAL" || true
udevadm settle
sleep 2
udevadm settle

P1="${REAL}p1"; P2="${REAL}p2"
[ -b "$P1" ] && [ -b "$P2" ] || { echo "FATAL: partitions did not appear"; exit 1; }

# ---- format ----------------------------------------------------------------
echo "--- mkfs"
mkfs.fat -F 32 -n NIXBOOT "$P1"
mkfs.btrfs -f -L NIXROOT  "$P2"
udevadm settle

echo
echo "=== result"
lsblk -o NAME,SIZE,FSTYPE,LABEL,PARTLABEL,UUID "$REAL"
echo
echo "Next: docs/migration/mount-target.sh (subvolumes + mounts), then fill-uuids.sh"
