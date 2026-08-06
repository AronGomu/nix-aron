#!/usr/bin/env bash
# §3 — capture the pre-migration state of desk-main. Non-destructive.
# Writes to ~/migration-baseline/ and to /mnt/data/rescue/_system/baseline/ so a
# copy survives on the Data HDD once the Samsung is gone.
set -euo pipefail

OUT="$HOME/migration-baseline"
MIRROR="/mnt/data/rescue/_system/baseline"

mkdir -p "$OUT"

lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,LABEL,MOUNTPOINTS,UUID > "$OUT/lsblk.txt"
lsblk -o NAME,TRAN,HOTPLUG,SIZE -d                            > "$OUT/lsblk-transport.txt"
findmnt -A                                                    > "$OUT/mounts.txt"
swapon --show                                                 > "$OUT/swap.txt"
id aron                                                       > "$OUT/uid.txt"
ls -l /dev/disk/by-id/                                        > "$OUT/by-id.txt"
ls -l /dev/disk/by-uuid/                                      > "$OUT/by-uuid.txt"
sudo efibootmgr -v                                            > "$OUT/efi.txt"
sudo sgdisk -p /dev/nvme0n1                                   > "$OUT/nvme-parttable.txt" 2>/dev/null \
  || echo "sgdisk unavailable — run inside: nix-shell -p gptfdisk" > "$OUT/nvme-parttable.txt"

echo "--- written to $OUT"
ls -1 "$OUT"

if mountpoint -q /mnt/data || [ -d /mnt/data/rescue ]; then
  mkdir -p "$MIRROR"
  cp -f "$OUT"/* "$MIRROR"/
  echo "--- mirrored to $MIRROR"
else
  echo "!!! /mnt/data not available — baseline exists ONLY on the Samsung." >&2
fi
