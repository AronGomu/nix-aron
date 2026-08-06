#!/usr/bin/env bash
# G0 gate — prove the flake actually describes the new NVMe before nixos-install.
# Non-destructive: builds the config and inspects the generated fstab.
#
# A G3 failure ("no bootable device", stage-1 panic) is far more often a stale
# fileSystems entry caught here than a real bootloader fault.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO"

SAMSUNG_ROOT="4c7138e6-9d27-4c85-8004-60d7621b982e"
SAMSUNG_BOOT="DFD1-432B"

pass=0
fail() { echo "  FAIL  $*"; pass=1; }
ok()   { echo "  ok    $*"; }

echo "=== import sanity"
grep -q '\./storage\.btrfs\.nix' hosts/desk-main/default.nix \
  && ok "default.nix imports storage.btrfs.nix" \
  || fail "default.nix does NOT import storage.btrfs.nix"
grep -q '\./storage\.nix' hosts/desk-main/default.nix \
  && fail "default.nix still imports storage.nix — remove it" \
  || ok "storage.nix not imported"
grep -q 'REPLACE-ME' hosts/desk-main/storage.btrfs.nix \
  && fail "UUID placeholders unfilled — run fill-uuids.sh" \
  || ok "UUIDs filled in"

echo
echo "=== git state (a flake builds from the tracked tree)"
if [ -n "$(git status --porcelain)" ]; then
  echo "  note  working tree is dirty:"
  git status --short | sed 's/^/        /'
  echo "        this flake does not use self.rev, so a dirty tree still evaluates."
  echo "        commit anyway if you want the installed system to be reproducible."
else
  ok "tree clean"
fi

echo
echo "=== building"
nixos-rebuild build --flake .#desk-main
FSTAB="$(readlink -f result)/etc/fstab"
[ -r "$FSTAB" ] || { echo "FAIL: no fstab at $FSTAB"; exit 1; }

echo
echo "=== generated fstab"
grep -v '^\s*#' "$FSTAB" | grep -v '^\s*$' | sed 's/^/  /'

echo
echo "=== checks"
BTRFS_N="$(awk '$3=="btrfs"' "$FSTAB" | wc -l)"
VFAT_N="$(awk '$3=="vfat"' "$FSTAB" | wc -l)"
[ "$BTRFS_N" = 4 ] && ok "4 btrfs lines" || fail "$BTRFS_N btrfs lines, expected 4"
[ "$VFAT_N"  = 1 ] && ok "1 vfat line"   || fail "$VFAT_N vfat lines, expected 1"

for mp in / /home /nix /.snapshots /boot /mnt/data; do
  awk -v m="$mp" '$2==m' "$FSTAB" | grep -q . \
    && ok "mount $mp present" || fail "mount $mp MISSING"
done

for sub in @ @home @nix @snapshots; do
  grep -q "subvol=$sub," "$FSTAB" && ok "subvol=$sub" || fail "subvol=$sub MISSING"
done

grep -q "by-label" "$FSTAB" \
  && fail "fstab still uses by-label — the Samsung is still attached" \
  || ok "no by-label devices"

for u in "$SAMSUNG_ROOT" "$SAMSUNG_BOOT"; do
  grep -qi "$u" "$FSTAB" && fail "SAMSUNG UUID $u still referenced" || ok "no reference to $u"
done

grep -q "ext4" "$FSTAB" && fail "stale ext4 entry" || ok "no ext4 entries"

echo
echo "=== bootloader"
grep -q 'systemd-boot' <(nix eval --raw .#nixosConfigurations.desk-main.config.system.boot.loader.id 2>/dev/null || echo "") \
  && ok "loader id = systemd-boot" || echo "  note  could not read loader id; boot.nix sets systemd-boot"
CANTOUCH="$(nix eval .#nixosConfigurations.desk-main.config.boot.loader.efi.canTouchEfiVariables)"
[ "$CANTOUCH" = "true" ] \
  && ok "canTouchEfiVariables = true (an NVRAM entry will be written)" \
  || fail "canTouchEfiVariables = $CANTOUCH — nixos-install writes NO NVRAM entry"
ESP="$(nix eval --raw .#nixosConfigurations.desk-main.config.boot.loader.efi.efiSysMountPoint)"
[ "$ESP" = "/boot" ] && ok "efiSysMountPoint = /boot" || fail "efiSysMountPoint = $ESP"

echo
echo "=== swap"
SWAP="$(nix eval --json .#nixosConfigurations.desk-main.config.swapDevices)"
[ "$SWAP" = "[]" ] && ok "swapDevices = [] (zram only)" || fail "swapDevices = $SWAP"

echo
echo "=== user"
UID_="$(nix eval .#nixosConfigurations.desk-main.config.users.users.aron.uid)"
[ "$UID_" = "1000" ] && ok "aron uid = 1000 (matches the source system)" || fail "aron uid = $UID_"
MUT="$(nix eval .#nixosConfigurations.desk-main.config.users.mutableUsers)"
[ "$MUT" = "true" ] \
  && ok "mutableUsers = true (passwd works after install)" \
  || fail "mutableUsers = false — aron needs hashedPassword or the system is unloggable"

echo
if [ "$pass" = 0 ]; then
  echo "G0 PASSED — safe to run:"
  echo "  sudo nixos-install --flake $REPO#desk-main"
else
  echo "G0 FAILED — do not run nixos-install."
  exit 1
fi
