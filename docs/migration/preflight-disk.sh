#!/usr/bin/env bash
# §4 pre-flight — prove the target disk is the Crucial P310 and nothing else.
# READ-ONLY. Destroys nothing. It prints the destructive commands for you to
# run by hand; it deliberately does not run them.
set -euo pipefail

DISK="${1:-/dev/disk/by-id/nvme-CT1000P310SSD8_252550DB0A3E}"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "  ok   $*"; }

echo "=== target: $DISK"
[ -e "$DISK" ] || fail "path does not exist"

REAL="$(readlink -f "$DISK")"
echo "=== readlink -f -> $REAL"
case "$REAL" in
  *p[0-9]) fail "resolves to a PARTITION, not a whole disk" ;;
  /dev/nvme?n1) ok "whole disk" ;;
  *) fail "unexpected node: $REAL" ;;
esac

MODEL="$(lsblk -dno MODEL "$REAL" | tr -d ' ')"
SIZE="$(lsblk -dno SIZE "$REAL" | tr -d ' ')"
[ "$MODEL" = "CT1000P310SSD8" ] || fail "model is '$MODEL', expected CT1000P310SSD8"
ok "model $MODEL"
[ "$SIZE" = "931.5G" ] || fail "size is '$SIZE', expected 931.5G"
ok "size $SIZE"

NPARTS="$(lsblk -lno NAME "$REAL" | tail -n +2 | wc -l)"
[ "$NPARTS" = "6" ] || fail "$NPARTS partitions visible, expected the 6 old ones"
ok "6 partitions present"

# The running root must NOT be on this disk.
ROOTSRC="$(findmnt -no SOURCE /)"
case "$(readlink -f "$ROOTSRC")" in
  "$REAL"*) fail "the RUNNING ROOT is on this disk — abort" ;;
  *) ok "running root is $ROOTSRC (not on target)" ;;
esac

echo
echo "=== current layout"
lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINTS "$REAL"

echo
echo "=== active swap (NVMe part5 must be absent before wiping)"
swapon --show || echo "  (no swap active)"

echo
echo "=== anything from this disk currently mounted?"
if findmnt -rno SOURCE,TARGET | grep -q "^${REAL}"; then
  findmnt -rno SOURCE,TARGET | grep "^${REAL}"
  fail "unmount the above first"
else
  ok "nothing mounted from target"
fi

cat <<EOF

============================================================
ALL CHECKS PASSED.

The commands below permanently destroy the Windows install and the old 232 GB
Linux install on $REAL. There is no image and no undo. Run them by hand, in
this order, only when you are ready.

  sudo -i
  nix-shell -p gptfdisk dosfstools parted btrfs-progs rsync

  export DISK=$DISK

  swapon --show
  swapoff "\$DISK-part5"          # only if it shows as active

  for p in "\$DISK"-part*; do wipefs -a "\$p"; done
  sgdisk --zap-all "\$DISK"
  wipefs -a "\$DISK"

  sgdisk -n 1:0:+1G -t 1:ef00 -c 1:NIXBOOT "\$DISK"
  sgdisk -n 2:0:0   -t 2:8300 -c 2:NIXROOT "\$DISK"
  partprobe "\$DISK"
  udevadm settle

  mkfs.fat -F 32 -n NIXBOOT "\$DISK-part1"
  mkfs.btrfs -f -L NIXROOT  "\$DISK-part2"

Then create the subvolumes and mounts (see docs/migration/README.md §4),
and run docs/migration/fill-uuids.sh.
============================================================
EOF
