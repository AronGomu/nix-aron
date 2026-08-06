#!/usr/bin/env bash
# Step 11 — final home sync with the desktop stopped, then power off.
#
# sync-home.sh's second pass must run with the graphical session down, or open
# browser/dconf/sqlite state copies torn. The documented way is a TTY, but VT
# switching is not always usable: on 2026-08-06 the Wayland session was itself
# on tty2, so Ctrl+Alt+F2 was a no-op, and the other VTs were not reachable
# either.
#
# So run this instead, as a transient SYSTEM unit. It is not part of the user
# session, so stopping the display manager cannot kill it mid-rsync — which is
# exactly what would happen if you ran the same commands from a terminal inside
# Hyprland:
#
#   sudo systemd-run --unit=g3-finish --collect \
#     --setenv=PATH=/run/current-system/sw/bin:/run/wrappers/bin \
#     /home/aron/config/nix-aron/docs/migration/g3-finish.sh
#
# PATH must be set explicitly: systemd's manager environment does NOT contain
# /run/current-system/sw/bin, so `env bash`, rsync, install, du and stat all
# fail to resolve without it. findmnt happens to be there via util-linux-minimal
# — do not let that mislead you into thinking the rest are.
#
# You will be blind while this runs: the screen goes dark when the display
# manager stops and there may be no console to read. That is why the outcome is
# encoded in the machine's behaviour rather than in text you have to go find:
#
#   success -> the machine powers off. Unplug the Samsung and boot the NVMe.
#   failure -> the desktop comes BACK. Read the log, fix, run again.
#
# Either way the log is kept at /var/log/g3-sync.log, and on success a copy
# lands on the NVMe at /home/aron/g3-sync.log so it survives the migration.
set -uo pipefail

LOG=/var/log/g3-sync.log
REPO=/home/aron/config/nix-aron
SYNC="$REPO/docs/migration/sync-home.sh"

[ "$(id -u)" = 0 ] || { echo "must run as root (use the systemd-run line in the header)"; exit 1; }

# Preflight BEFORE touching the desktop. Everything below this point costs the
# user their session, so anything knowably wrong must fail while they can still
# read the error.
[ -x "$SYNC" ] || { echo "FATAL: $SYNC missing or not executable"; exit 1; }
for m in /mnt /mnt/home /mnt/nix /mnt/boot; do
  findmnt -rno TARGET "$m" >/dev/null || {
    echo "FATAL: $m is not mounted — run 'sudo $REPO/docs/migration/mount-target.sh' first"
    exit 1
  }
done
case "$(findmnt -rno OPTIONS /mnt/home)" in
  *subvol=/@home*) ;;
  *) echo "FATAL: /mnt/home is not the @home subvolume"; exit 1 ;;
esac

{
  echo "=== g3-finish starting"
  echo "--- stopping display-manager"
} >"$LOG" 2>&1

systemctl stop display-manager >>"$LOG" 2>&1

# Let the compositor's children actually exit and flush before rsync reads
# their files; `systemctl stop` returns when the unit is done, not when every
# orphaned client has finished writing.
sleep 5

"$SYNC" >>"$LOG" 2>&1
rc=$?
echo "=== sync-home.sh exit=$rc" >>"$LOG"

if [ "$rc" -eq 0 ]; then
  # Put the log where it survives the migration: the Samsung is about to be
  # unplugged, so a log only in its /var/log is a log you cannot read.
  cp "$LOG" /mnt/home/aron/g3-sync.log 2>/dev/null || true
  chown 1000:100 /mnt/home/aron/g3-sync.log 2>/dev/null || true
  sync
  echo "=== powering off" >>"$LOG"
  systemctl poweroff
else
  # Give the desktop back rather than leaving a black screen with no TTY. The
  # failure is reported by the session RETURNING, which is the one signal that
  # gets through without a console.
  echo "=== sync FAILED — restarting display-manager so the log is readable" >>"$LOG"
  systemctl start display-manager
  exit "$rc"
fi
