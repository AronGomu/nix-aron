#!/usr/bin/env bash
# §5.2 / §5.3 / §8 — run from the Samsung system with the new system mounted at
# /mnt, immediately before shutting down for G3. Read-only.
set -euo pipefail

pass=0
fail() { echo "  FAIL  $*"; pass=1; }
ok()   { echo "  ok    $*"; }
note() { echo "  note  $*"; }

[ -d /mnt/etc ] || { echo "FAIL: nothing installed at /mnt"; exit 1; }

# Works whether or not efibootmgr is installed on the running system.
efibootmgr_v() {
  if command -v efibootmgr >/dev/null 2>&1; then
    sudo efibootmgr -v
  else
    nix-shell -p efibootmgr --run 'sudo efibootmgr -v'
  fi
}

echo "=== mounts under /mnt"
findmnt -R /mnt | sed 's/^/  /'
for mp in /mnt /mnt/boot /mnt/home /mnt/nix /mnt/.snapshots; do
  mountpoint -q "$mp" && ok "$mp mounted" || fail "$mp NOT mounted"
done

echo
echo "=== §5.2 passwords — both need a real hash, not '!' or '*'"
for u in root aron; do
  h="$(sudo awk -F: -v u="$u" '$1==u {print $2}' /mnt/etc/shadow)"
  case "$h" in
    ""|"!"|"*"|"!!") fail "$u has no password  ->  sudo nixos-enter --root /mnt -c 'passwd $u'" ;;
    *) ok "$u has a password hash" ;;
  esac
done

echo
echo "=== §5.3 uid"
SRC="$(id -u aron)"
TGT="$(awk -F: '$1=="aron" {print $3}' /mnt/etc/passwd)"
if [ "$SRC" = "$TGT" ]; then
  ok "aron uid $TGT matches source"
else
  fail "source uid $SRC != target uid $TGT"
  echo "        fix INSIDE the target, never from here:"
  echo "        sudo nixos-enter --root /mnt -c 'chown -R aron:users /home/aron'"
fi
if [ -d /mnt/home/aron ]; then
  OWNER="$(stat -c %u /mnt/home/aron)"
  [ "$OWNER" = "$TGT" ] && ok "/mnt/home/aron owned by uid $OWNER" \
    || fail "/mnt/home/aron owned by uid $OWNER, expected $TGT"
  for d in .ssh .gnupg .config; do
    [ -e "/mnt/home/aron/$d" ] && ok "home has $d" || note "home missing $d"
  done
else
  fail "/mnt/home/aron does not exist — rsync not run yet"
fi

echo
echo "=== §8 bootloader — the NVMe must be bootable on its own"
echo "  (this machine boots via the FALLBACK path, not a registered NVRAM entry —"
echo "   see baseline efi.txt: BootCurrent 0006 'UEFI OS' -> \\EFI\\BOOT\\BOOTX64.EFI)"

# blkid needs root and returns EMPTY with exit 0 for a normal user — silently
# passing an empty PARTUUID into a grep. Read the udev symlink instead.
partuuid_of() {
  local dev; dev="$(readlink -f "$1")"
  local l; for l in /dev/disk/by-partuuid/*; do
    [ "$(readlink -f "$l")" = "$dev" ] && { basename "$l"; return; }
  done
}

NVME_PARTUUID="$(partuuid_of /dev/nvme0n1p1)"
EFI_OUT="$(efibootmgr_v)"
echo "$EFI_OUT" | sed 's/^/  /'
echo
[ -n "$NVME_PARTUUID" ] && ok "NVMe ESP PARTUUID = $NVME_PARTUUID" \
  || fail "could not determine the NVMe ESP PARTUUID"

# Two independent ways the NVMe can boot. Either is sufficient; both is better.
NVRAM_OK=0; FALLBACK_OK=0
[ -n "$NVME_PARTUUID" ] && echo "$EFI_OUT" | grep -qi "$NVME_PARTUUID" && NVRAM_OK=1
[ -f /mnt/boot/EFI/BOOT/BOOTX64.EFI ] && FALLBACK_OK=1

[ "$NVRAM_OK" = 1 ] && ok "an NVRAM entry references the NVMe ESP" \
  || note "no NVRAM entry references the NVMe ESP"
[ "$FALLBACK_OK" = 1 ] && ok "fallback /mnt/boot/EFI/BOOT/BOOTX64.EFI present" \
  || note "no fallback BOOTX64.EFI on the NVMe ESP"

if [ "$NVRAM_OK" = 0 ] && [ "$FALLBACK_OK" = 0 ]; then
  fail "the NVMe has NEITHER an NVRAM entry NOR a fallback loader — it will not boot"
  echo "        Fix now, with the Samsung still attached:"
  echo "          sudo nixos-enter --root /mnt -c 'bootctl install'"
  echo "        or register the entry explicitly:"
  echo "          sudo efibootmgr --create --disk /dev/nvme0n1 --part 1 \\"
  echo "            --loader '\\EFI\\systemd\\systemd-bootx64.efi' --label 'NixOS'"
elif [ "$NVRAM_OK" = 0 ]; then
  note "booting will rely on firmware fallback detection, exactly as it does today."
  note "that is how this machine already boots, so it is expected — but if G3 fails,"
  note "this is the first thing to fix (see the efibootmgr --create line in §8)."
fi

ls /mnt/boot/loader/entries/*.conf >/dev/null 2>&1 \
  && ok "systemd-boot entries present in /mnt/boot" \
  || fail "no loader entries in /mnt/boot"

# Stale entries that will point at destroyed partitions after the wipe.
echo
echo "=== entries that will be dead after the migration (delete in §9)"
echo "$EFI_OUT" | grep -i 'Windows Boot Manager' \
  && note "Windows Boot Manager -> the wiped Crucial ESP. Dead. Remove in §9." \
  || ok "no Windows Boot Manager entry"

echo
if [ "$pass" = 0 ]; then
  cat <<'EOF'
READY FOR G3.

  1. Shut down.
  2. Unplug the Samsung USB cable.
  3. Boot. You must reach the NixOS login from the NVMe alone.
  4. Reconnect the Samsung only after a successful login.

The Samsung is the rollback system and is kept as-is. Nothing in this migration
writes to it. Leave it that way.
EOF
else
  echo "NOT ready for G3 — fix the failures above first."
  exit 1
fi
