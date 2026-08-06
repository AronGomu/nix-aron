#!/usr/bin/env bash
# §3 — capture the pre-migration state of desk-main. Non-destructive.
# Writes to ~/migration-baseline/ and to /mnt/data/rescue/_system/baseline/ so a
# copy survives on the Data HDD once the Samsung is gone.
set -euo pipefail

OUT="$HOME/migration-baseline"
MIRROR="/mnt/data/rescue/_system/baseline"

mkdir -p "$OUT"

# efibootmgr and sgdisk are not on a stock NixOS unless the config asks for them.
# modules/nixos/base.nix now does, but this script has to work before that rebuild.
# Run each tool from the system if present, otherwise fetch it transiently.
have() { command -v "$1" >/dev/null 2>&1; }
run_tool() {
  local tool="$1" pkg="$2"; shift 2
  if have "$tool"; then
    sudo "$tool" "$@"
  else
    echo "  ($tool absent — fetching $pkg transiently)" >&2
    nix-shell -p "$pkg" --run "sudo $tool $*"
  fi
}

lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,LABEL,MOUNTPOINTS,UUID > "$OUT/lsblk.txt"
lsblk -o NAME,TRAN,HOTPLUG,SIZE -d                            > "$OUT/lsblk-transport.txt"
findmnt -A                                                    > "$OUT/mounts.txt"
swapon --show                                                 > "$OUT/swap.txt"
id aron                                                       > "$OUT/uid.txt"
ls -l /dev/disk/by-id/                                        > "$OUT/by-id.txt"
ls -l /dev/disk/by-uuid/                                      > "$OUT/by-uuid.txt"
# The load-bearing one. After the install there are TWO EFI entries and, with
# systemd-boot, both read "Linux Boot Manager". This file is how you tell the new
# NVMe entry from the old Samsung one at §8 and §9.
run_tool efibootmgr efibootmgr -v                             > "$OUT/efi.txt"
sudo bootctl status                                           > "$OUT/bootctl.txt" 2>&1 || true
run_tool sgdisk gptfdisk -p /dev/nvme0n1                      > "$OUT/nvme-parttable.txt"

echo "--- written to $OUT"
ls -1 "$OUT"

if mountpoint -q /mnt/data || [ -d /mnt/data/rescue ]; then
  mkdir -p "$MIRROR"
  cp -f "$OUT"/* "$MIRROR"/
  echo "--- mirrored to $MIRROR"
else
  echo "!!! /mnt/data not available — baseline exists ONLY on the Samsung." >&2
fi
