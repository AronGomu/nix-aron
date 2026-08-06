#!/usr/bin/env bash
# Will this config brick desk-main? Read-only; safe to run any time.
#
# The invariant that matters, and the one that was violated on 2026-08-06:
# `nixos-rebuild switch` applies the new fileSystems to the RUNNING system, so
# the output matching the running disk must not change the set of mounts. When
# it does, systemd stacks the other disk's @nix over the live store and the
# machine loses its shell mid-command. Check 4 is that invariant; everything
# else is supporting evidence.
#
# Run before any switch that touches storage, and before/after G3.
# Builds both outputs (a few minutes cold, seconds warm). Never writes anything,
# never needs sudo, never activates.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO" || exit 1

# UUIDs come from the same single source of truth the flake uses, so this
# script cannot drift from the config it is checking.
DISKS="$(nix eval --json --file hosts/desk-main/disks.nix)" || {
  echo "FAIL: cannot evaluate hosts/desk-main/disks.nix" >&2
  exit 1
}
jqd() { printf '%s' "$DISKS" | nix run nixpkgs#jq -- -r "$1"; }
SAMSUNG_ROOT="$(jqd .samsung.root)"
NVME_ROOT="$(jqd .nvme.root)"

bad=0
fail() { printf '  FAIL  %s\n' "$*"; bad=1; }
ok() { printf '  ok    %s\n' "$*"; }
ev() { nix eval --raw "$@" 2>/dev/null; }

echo "=== 1. running state"
RUN_UUID="$(findmnt -no UUID /)"
echo "        root UUID $RUN_UUID ($(findmnt -no FSTYPE /))"
case "$RUN_UUID" in
  "$SAMSUNG_ROOT") RUNNING_ATTR=desk-main-samsung ;;
  "$NVME_ROOT") RUNNING_ATTR=desk-main-nvme ;;
  *)
    echo "  FAIL  running root $RUN_UUID is in neither disks.nix entry" >&2
    exit 1
    ;;
esac
ok "running attr = $RUNNING_ATTR"

echo
echo "=== 2. output isolation"
nix eval '.#nixosConfigurations.desk-main' >/dev/null 2>&1 &&
  fail "bare .#desk-main output exists — a stale command can switch disks" ||
  ok "no bare .#desk-main output"
nix eval '.#homeConfigurations.desk-main' >/dev/null 2>&1 &&
  fail "homeConfigurations.desk-main exists — running it strips the desktop config" ||
  ok "no standalone homeConfigurations output"

S_ROOT="$(ev '.#nixosConfigurations.desk-main-samsung.config.fileSystems."/".device')"
N_ROOT="$(ev '.#nixosConfigurations.desk-main-nvme.config.fileSystems."/".device')"
[ "$S_ROOT" = "/dev/disk/by-uuid/$SAMSUNG_ROOT" ] &&
  ok "desk-main-samsung root -> Samsung" || fail "desk-main-samsung root = $S_ROOT"
[ "$N_ROOT" = "/dev/disk/by-uuid/$NVME_ROOT" ] &&
  ok "desk-main-nvme root -> NVMe" || fail "desk-main-nvme root = $N_ROOT"

echo
echo "=== 3. build both outputs"
TOP_SAMSUNG="$(nix build --no-link --print-out-paths '.#nixosConfigurations.desk-main-samsung.config.system.build.toplevel' 2>/dev/null)"
TOP_NVME="$(nix build --no-link --print-out-paths '.#nixosConfigurations.desk-main-nvme.config.system.build.toplevel' 2>/dev/null)"
[ -n "$TOP_SAMSUNG" ] && ok "desk-main-samsung builds" || fail "desk-main-samsung FAILED TO BUILD"
[ -n "$TOP_NVME" ] && ok "desk-main-nvme builds" || fail "desk-main-nvme FAILED TO BUILD"
if [ "$RUNNING_ATTR" = desk-main-samsung ]; then
  RUNNING_TOP="$TOP_SAMSUNG"
else
  RUNNING_TOP="$TOP_NVME"
fi
[ -n "$RUNNING_TOP" ] || { echo "cannot continue without a build of $RUNNING_ATTR" >&2; exit 1; }

echo
echo "=== 4. THE brick check: mounts must not change under the live system"
BOOTED="$(readlink -f /run/booted-system)"
if diff -q "$BOOTED/etc/fstab" "$RUNNING_TOP/etc/fstab" >/dev/null 2>&1; then
  ok "fstab identical to booted system"
else
  fail "fstab DIFFERS from the booted system — a switch would remount:"
  diff "$BOOTED/etc/fstab" "$RUNNING_TOP/etc/fstab" | sed 's/^/          /'
fi
# Compare mount POINTS from fstab, not units under etc/systemd/system — that
# directory holds only the 8 API filesystems (dev-mqueue, sys-kernel-debug, …)
# and is byte-identical in every generation, so comparing it always passes and
# proves nothing. The real units are produced by systemd-fstab-generator from
# fstab at runtime, and it is systemd starting a NEW one that stacks the other
# disk's @nix over the live store.
mountpoints() { grep -v '^[[:space:]]*#' "$1/etc/fstab" | awk 'NF>=3 {print $2}' | sort; }
if diff -q <(mountpoints "$BOOTED") <(mountpoints "$RUNNING_TOP") >/dev/null 2>&1; then
  ok "mount point set identical:$(mountpoints "$RUNNING_TOP" | tr '\n' ' ' | sed 's/ $//;s/^/ /')"
else
  fail "mount POINTS would change — a switch would start/stop mounts on the live system:"
  diff <(mountpoints "$BOOTED") <(mountpoints "$RUNNING_TOP") | sed 's/^/          /'
fi

echo
echo "=== 5. no cross-disk contamination"
grep -qi "$NVME_ROOT" "$TOP_SAMSUNG/etc/fstab" &&
  fail "samsung fstab references the NVMe" || ok "samsung fstab has no NVMe UUID"
grep -qi "$SAMSUNG_ROOT" "$TOP_NVME/etc/fstab" &&
  fail "nvme fstab references the Samsung" || ok "nvme fstab has no Samsung UUID"

echo
echo "=== 6. nixos-host resolves to the running disk"
if [ -x "$RUNNING_TOP/sw/bin/nixos-host" ]; then
  got="$("$RUNNING_TOP/sw/bin/nixos-host" 2>/dev/null)"
  [ "$got" = "$RUNNING_ATTR" ] && ok "nixos-host -> $got" ||
    fail "nixos-host -> '$got', expected $RUNNING_ATTR"
else
  fail "nixos-host not in $RUNNING_ATTR system path"
fi

echo
echo "=== 7. login is possible (TTY, not just GUI)"
for attr in desk-main-samsung desk-main-nvme; do
  sh="$(ev ".#nixosConfigurations.$attr.config.users.users.aron.shell")"
  { [ -n "$sh" ] && [ -x "$sh/bin/zsh" ]; } &&
    ok "$attr: aron shell $sh/bin/zsh exists" ||
    fail "$attr: aron shell '$sh' has no usable zsh"
  mut="$(nix eval ".#nixosConfigurations.$attr.config.users.mutableUsers" 2>/dev/null)"
  [ "$mut" = "true" ] && ok "$attr: mutableUsers = true" || fail "$attr: mutableUsers = $mut"
done
grep -q zsh "$RUNNING_TOP/etc/shells" 2>/dev/null &&
  ok "zsh listed in /etc/shells" || fail "zsh NOT in /etc/shells"

echo
echo "=== 8. stage-1 can reach each root"
for attr in desk-main-samsung desk-main-nvme; do
  mods="$(nix eval --json ".#nixosConfigurations.$attr.config.boot.initrd.availableKernelModules" 2>/dev/null)"
  case "$mods" in
    *'"nvme"'*) ok "$attr: initrd has nvme module" ;;
    *) fail "$attr: initrd lacks nvme module" ;;
  esac
done
ifs="$(nix eval --json '.#nixosConfigurations.desk-main-nvme.config.boot.initrd.supportedFilesystems' 2>/dev/null)"
case "$ifs" in
  *btrfs*) ok "desk-main-nvme: initrd supports btrfs" ;;
  *) fail "desk-main-nvme: initrd does NOT support btrfs — stage-1 cannot mount root" ;;
esac

echo
echo "=== 9. bootloader"
for attr in desk-main-samsung desk-main-nvme; do
  lid="$(ev ".#nixosConfigurations.$attr.config.system.boot.loader.id")"
  esp="$(ev ".#nixosConfigurations.$attr.config.boot.loader.efi.efiSysMountPoint")"
  [ "$lid" = "systemd-boot" ] && ok "$attr: loader = systemd-boot" || fail "$attr: loader = $lid"
  [ "$esp" = "/boot" ] && ok "$attr: ESP = /boot" || fail "$attr: ESP = $esp"
  # The ESP guard must be present, or a wrong-output rebuild writes entries to
  # the running disk's ESP with no warning. See hosts/desk-main/esp-guard.nix.
  ib="$(ev ".#nixosConfigurations.$attr.config.system.build.installBootLoader")"
  { [ -n "$ib" ] && [ -e "$ib" ] && grep -q 'WRONG ESP' "$ib"; } &&
    ok "$attr: ESP guard present in installer" ||
    fail "$attr: ESP guard MISSING from bootloader installer"
done
espfree="$(df --output=avail -k /boot | tail -1)"
[ "$espfree" -gt 102400 ] && ok "ESP has $((espfree / 1024)) MB free" ||
  fail "ESP only has $((espfree / 1024)) MB free — bootloader install may fail"

echo
echo "=== 10. home-manager activation builds (a failure here aborts switch)"
for attr in desk-main-samsung desk-main-nvme; do
  hf="$(nix build --no-link --print-out-paths ".#nixosConfigurations.$attr.config.home-manager.users.aron.home-files" 2>/dev/null)"
  [ -n "$hf" ] && ok "$attr: HM files build" || fail "$attr: HM files FAILED to build"
done

echo
if [ "$bad" = 0 ]; then
  echo "NO-BRICK CHECK PASSED — switching to .#$RUNNING_ATTR changes no mounts."
else
  echo "NO-BRICK CHECK FAILED — do not switch."
  exit 1
fi
