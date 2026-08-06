#!/usr/bin/env bash
# G0 step 1 — read the UUIDs of the freshly formatted Crucial partitions and
# write them into the `nvme` block of hosts/desk-main/disks.nix.
#
# There is no longer an import to flip: the Btrfs layout is its own flake
# output (desk-main-nvme) and is always present. This script only fills UUIDs.
#
# Run AFTER mkfs.fat / mkfs.btrfs. Idempotent — safe to re-run.
# Touches only files in this repo. No disks are modified.
set -euo pipefail

DISK="${1:-/dev/disk/by-id/nvme-CT1000P310SSD8_252550DB0A3E}"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DISKS="$REPO/hosts/desk-main/disks.nix"

BOOT="$DISK-part1"
ROOT="$DISK-part2"

fail() { echo "FAIL: $*" >&2; exit 1; }

[ -e "$BOOT" ] || fail "$BOOT missing — partition the disk first"
[ -e "$ROOT" ] || fail "$ROOT missing — partition the disk first"

# lsblk, not blkid: blkid needs root and returns an EMPTY string with exit
# status 0 for a normal user, which would sed a blank UUID into the config.
# lsblk reads the same udev database unprivileged.
BOOT_FS="$(lsblk -dno FSTYPE "$BOOT")"
ROOT_FS="$(lsblk -dno FSTYPE "$ROOT")"
[ "$BOOT_FS" = "vfat" ]  || fail "part1 is '$BOOT_FS', expected vfat — run mkfs.fat"
[ "$ROOT_FS" = "btrfs" ] || fail "part2 is '$ROOT_FS', expected btrfs — run mkfs.btrfs"

BOOT_UUID="$(lsblk -dno UUID "$BOOT")"
ROOT_UUID="$(lsblk -dno UUID "$ROOT")"
[ -n "$BOOT_UUID" ] || fail "no UUID on $BOOT"
[ -n "$ROOT_UUID" ] || fail "no UUID on $ROOT"

# Guard against pointing at the Samsung by accident.
SAMSUNG_ROOT="4c7138e6-9d27-4c85-8004-60d7621b982e"
SAMSUNG_BOOT="DFD1-432B"
for u in "$ROOT_UUID" "$BOOT_UUID"; do
  case "$u" in
    "$SAMSUNG_ROOT"|"$SAMSUNG_BOOT") fail "that is the SAMSUNG's UUID — wrong disk" ;;
  esac
done

echo "  root (btrfs, NIXROOT) $ROOT_UUID"
echo "  boot (vfat,  NIXBOOT) $BOOT_UUID"

# The `samsung` and `nvme` blocks both have `root =` / `boot =` at the same
# indent, so the substitution is scoped to the nvme block by address range.
# Only the quoted value is replaced, which keeps the trailing device comment.
sed -i \
  -e "/^  nvme = {/,/^  };/ s|^\(    root = \)\"[^\"]*\"|\1\"$ROOT_UUID\"|" \
  -e "/^  nvme = {/,/^  };/ s|^\(    boot = \)\"[^\"]*\"|\1\"$BOOT_UUID\"|" \
  "$DISKS"

grep -q "REPLACE-ME" "$DISKS" && fail "placeholders still present in $DISKS"
echo "--- patched $DISKS"
sed -n '/^  nvme = {/,/^  };/p' "$DISKS" | sed 's/^/    /'

# Re-read the values back out of the nvme block to prove the sed landed there
# and not in the samsung block.
got_root="$(sed -n '/^  nvme = {/,/^  };/ s|^    root = "\([^"]*\)".*|\1|p' "$DISKS")"
got_boot="$(sed -n '/^  nvme = {/,/^  };/ s|^    boot = "\([^"]*\)".*|\1|p' "$DISKS")"
[ "$got_root" = "$ROOT_UUID" ] || fail "nvme.root is '$got_root', expected $ROOT_UUID"
[ "$got_boot" = "$BOOT_UUID" ] || fail "nvme.boot is '$got_boot', expected $BOOT_UUID"

# And that the Samsung block was left alone.
sam_root="$(sed -n '/^  samsung = {/,/^  };/ s|^    root = "\([^"]*\)".*|\1|p' "$DISKS")"
[ "$sam_root" = "$SAMSUNG_ROOT" ] || fail "samsung.root was overwritten — now '$sam_root'"

# Sanity-check the subvolumes exist, if the fs is mounted somewhere.
if MP="$(findmnt -rno TARGET "$ROOT" 2>/dev/null | head -1)" && [ -n "$MP" ]; then
  echo "--- subvolumes on $ROOT (mounted at $MP)"
  btrfs subvolume list "$MP" || true
fi

echo
echo "Next: docs/migration/g0-verify.sh"
