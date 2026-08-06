#!/usr/bin/env bash
# §5.3 — copy /home/aron to the new system at /mnt/home/aron.
#
# Run TWICE:
#   1. bulk pass, desktop running. Copies ~everything. Files that are open
#      mid-write (browser sqlite, dconf) come across inconsistently — fine,
#      because of pass 2.
#   2. final pass, from a TTY with the graphical session logged out. rsync
#      only re-copies what changed, so it is short, and it is the consistent
#      one that actually counts.
#
# Run as root:  sudo ./docs/migration/sync-home.sh
set -euo pipefail

SRC="/home/aron/"
DST="/mnt/home/aron/"

[ "$(id -u)" = 0 ] || { echo "must run as root — rsync needs to read every file and set ownership"; exit 1; }

# /mnt/home must be the @home subvolume, not a directory inside @. If the mount
# is missing, this would silently fill up the root subvolume instead.
findmnt -rno TARGET /mnt      >/dev/null || { echo "FATAL: /mnt not mounted";      exit 1; }
findmnt -rno TARGET /mnt/home >/dev/null || { echo "FATAL: /mnt/home not mounted"; exit 1; }
[ "$(findmnt -rno FSTYPE /mnt/home)" = "btrfs" ] || { echo "FATAL: /mnt/home is not btrfs"; exit 1; }
case "$(findmnt -rno OPTIONS /mnt/home)" in
  *subvol=/@home*) ;;
  *) echo "FATAL: /mnt/home is not the @home subvolume"; exit 1 ;;
esac

mkdir -p "$DST"

# --exclude paths are also protected from --delete (that needs
# --delete-excluded), so re-running never removes what we chose to skip.
#
# .local/share/docker: 52 GB, and all of it is the containerd image content
# store — volumes are 100 KB of testcontainers leftovers and there are no
# containers. dockerd is live, so its boltdb metadata.db would copy torn and
# Docker might refuse to open the store on the new system, with no sign of
# trouble until after G3. Public images re-pull; the gones-* ones rebuild from
# source, which does come across.
# GoogleDrive is a fuse.rclone mount of gdrive:, not a directory. It is mounted
# without allow_root, so even root gets EACCES on stat() — rsync then aborts
# with code 23 AND skips all deletions for the run. Copying it would mean
# pulling the whole remote down anyway. ~/.config/rclone comes across with the
# rest of home, so the mount works again after G3; it just needs its mountpoint.
rsync -aHAX --info=progress2 --delete \
  --exclude '.cache/' \
  --exclude '.local/share/Trash/' \
  --exclude '.local/share/docker/' \
  --exclude 'GoogleDrive/' \
  "$SRC" "$DST"

install -d -o 1000 -g 100 "$DST/GoogleDrive"

echo
echo "=== copied"
du -sh "$DST" 2>/dev/null || true
echo "--- ownership of $DST (expect uid 1000)"
stat -c '%u %g %n' "$DST"
echo
echo "Next: run this again from a TTY after logging out, then post-install-checks.sh"
