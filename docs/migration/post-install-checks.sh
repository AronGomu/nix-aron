#!/usr/bin/env bash
# §5.2 / §5.3 / §8 — run from the Samsung system with the new system mounted at
# /mnt, immediately before shutting down for G3. Read-only.
set -euo pipefail

pass=0
fail() { echo "  FAIL  $*"; pass=1; }
ok()   { echo "  ok    $*"; }
note() { echo "  note  $*"; }

[ -d /mnt/etc ] || { echo "FAIL: nothing installed at /mnt"; exit 1; }

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
echo "=== §8 bootloader — an NVRAM entry must point at the NVMe ESP"
sudo efibootmgr -v | sed 's/^/  /'
NVME_PARTUUID="$(blkid -s PARTUUID -o value /dev/nvme0n1p1 2>/dev/null || true)"
if [ -n "$NVME_PARTUUID" ] && sudo efibootmgr -v | grep -qi "${NVME_PARTUUID}"; then
  ok "an entry references the NVMe ESP PARTUUID $NVME_PARTUUID"
else
  fail "no EFI entry references the NVMe ESP — create it BEFORE unplugging the Samsung"
fi
[ -f /mnt/boot/EFI/BOOT/BOOTX64.EFI ] \
  && ok "fallback /mnt/boot/EFI/BOOT/BOOTX64.EFI present" \
  || note "no fallback BOOTX64.EFI — firmware must use the NVRAM entry"
ls /mnt/boot/loader/entries/*.conf >/dev/null 2>&1 \
  && ok "systemd-boot entries present in /mnt/boot" \
  || fail "no loader entries in /mnt/boot"

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
