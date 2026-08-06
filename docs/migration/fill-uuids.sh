#!/usr/bin/env bash
# G0 step 1 — read the UUIDs of the freshly formatted Crucial partitions,
# write them into hosts/desk-main/storage.btrfs.nix, and switch
# hosts/desk-main/default.nix over to that module.
#
# Run AFTER mkfs.fat / mkfs.btrfs. Idempotent — safe to re-run.
# Touches only files in this repo. No disks are modified.
set -euo pipefail

DISK="${1:-/dev/disk/by-id/nvme-CT1000P310SSD8_252550DB0A3E}"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STORAGE="$REPO/hosts/desk-main/storage.btrfs.nix"
DEFAULT="$REPO/hosts/desk-main/default.nix"

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

sed -i \
  -e "s|^  rootUuid = \".*\";|  rootUuid = \"$ROOT_UUID\";|" \
  -e "s|^  bootUuid = \".*\";|  bootUuid = \"$BOOT_UUID\";|" \
  "$STORAGE"

grep -q "REPLACE-ME" "$STORAGE" && fail "placeholders still present in $STORAGE"
echo "--- patched $STORAGE"
grep -n 'Uuid = ' "$STORAGE"

# Switch the host over to the Btrfs layout.
if grep -q '\./storage\.btrfs\.nix' "$DEFAULT"; then
  echo "--- $DEFAULT already imports storage.btrfs.nix"
else
  sed -i 's|\./storage\.nix|./storage.btrfs.nix|' "$DEFAULT"
  echo "--- switched $DEFAULT to storage.btrfs.nix"
fi
# Plain `grep -q ... && fail`: `grep -c | grep -qx 0` looks equivalent but
# grep -c exits 1 on zero matches and pipefail turns the success case into a
# failure. The regex must not match ./storage.btrfs.nix, hence the anchor on
# "nix" immediately after "storage.".
grep -qE '\./storage\.nix([^a-zA-Z0-9]|$)' "$DEFAULT" \
  && fail "$DEFAULT still imports storage.nix — both must never be imported"
grep -n 'storage' "$DEFAULT"

# Sanity-check the subvolumes exist, if the fs is mounted somewhere.
if MP="$(findmnt -rno TARGET "$ROOT" 2>/dev/null | head -1)" && [ -n "$MP" ]; then
  echo "--- subvolumes on $ROOT (mounted at $MP)"
  btrfs subvolume list "$MP" || true
fi

echo
echo "Next: docs/migration/g0-verify.sh"
