# desk-main — Samsung (USB) → Crucial P310 NVMe migration

Companion to `nixos-crucial-migration-plan.md` (rev 3), which lives on the Data HDD at
`F:\rescue\nixos-migration-plan-REV3.md` and in Google Drive. That document is the
authority on *why*. This one is the authority on *what to run in this repo*.

State verified live on 2026-08-06 from the running system.

## What was already true (the plan assumed otherwise)

- `modules/nixos/boot.nix` already sets `systemd-boot.enable = true` **and**
  `efi.canTouchEfiVariables = true`. The plan's §5.1/§8 fear of a silent
  no-NVRAM-entry install does not apply here.
- `modules/nixos/base.nix` pins `users.users.aron.uid = 1000`, which matches the
  running system. The plan's §5.3 UID trap does not apply.
- `mutableUsers = true`, so `passwd` works after install — but `nixos-install`
  still sets **root only**. `aron` genuinely gets no password. Real problem.
- `modules/nixos/nix.nix` already has `gc.automatic`, `gc.dates = "weekly"` and
  `auto-optimise-store`; `base.nix` has `services.fstrim.enable`. §9's config
  block needs no work.
- `boot.initrd.availableKernelModules` already contains `nvme`.
- This flake never references `self.rev`, so a dirty tree still evaluates.
- `mkfs.btrfs` and `mkfs.fat` are already on PATH (`supportedFilesystems`
  includes btrfs). Only `sgdisk` and `partprobe` are missing.
- The 4 TB NTFS Data HDD is already mounted rw at `/mnt/data` and `rescue/` is
  readable. The plan's §5.4 is largely already done.

## What changed in this repo to prepare

- `hosts/desk-main/storage.btrfs.nix` — rewritten. Was `by-label`, now `by-uuid`
  with two placeholders. `/mnt/data` moved from `umask=0022` (which marks every
  file executable) to `fmask=0133` + `dmask=0022`, plus `windows_names`. Gained
  `services.btrfs.autoScrub`. All `lib.mkForce` on `fileSystems` removed, so
  importing both storage modules now fails loudly instead of silently resolving.
- `modules/nixos/base.nix` — the disabled `services.btrfs.autoScrub` block moved
  out to the host's Btrfs module, where the layout it describes actually exists.
- `hosts/desk-main/default.nix` — **unchanged for now**, still imports
  `./storage.nix`. `fill-uuids.sh` flips it at G0.

## Why the import is not flipped yet

`storage.nix` describes the *running* Samsung root. The moment `default.nix`
points at `storage.btrfs.nix`, any `nixos-rebuild switch` on the Samsung would
write an fstab for a disk that does not exist yet and break the rollback system
on its next boot. The flip belongs at G0, after the NVMe is formatted.

Between the flip and G3 the Samsung stays bootable — its existing generation and
its own `/boot` are untouched — but **do not run `nixos-rebuild switch` on the
Samsung after the flip.** To roll back, boot an older generation, or flip the
import back first.

## Order of operations

Everything before step 4 is non-destructive and reversible.

| # | Command | Plan § |
|---|---|---|
| 1 | `docs/migration/baseline.sh` | §3 |
| 2 | `nixos-rebuild build --flake .#desk-main` | §3 |
| 3 | `docs/migration/preflight-disk.sh` | §4 |
| 4 | **wipe + partition + format, by hand** (printed by step 3) | §4 |
| 5 | subvolumes + mounts (below) | §4 |
| 6 | `docs/migration/fill-uuids.sh` | §5.1 |
| 7 | `docs/migration/g0-verify.sh` — **G0** | §5.1 |
| 8 | `sudo nixos-install --flake /home/aron/coding/nix-aron#desk-main` | §5.2 |
| 9 | rsync home from a TTY (below) | §5.3 |
| 10 | `docs/migration/post-install-checks.sh` | §5.2, §5.3, §8 |
| 11 | shut down, unplug the Samsung, boot — **G3** | §8 |

Steps 1–3 can be run right now. Do not start step 4 until the §2.2 pre-flight
boxes are ticked: OneKey seed written down offline, the 62 Google-native docs
exported, `brain` committed **and pushed**, and the recovery USB written.

### Step 5 — subvolumes and mounts

```bash
sudo -i
export DISK=/dev/disk/by-id/nvme-CT1000P310SSD8_252550DB0A3E
export BOOT="$DISK-part1" ROOT="$DISK-part2"

mount "$ROOT" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@snapshots
umount /mnt

mount -o subvol=@,compress=zstd,noatime "$ROOT" /mnt
mkdir -p /mnt/{boot,home,nix,.snapshots,mnt/data}
mount -o subvol=@home,compress=zstd,noatime      "$ROOT" /mnt/home
mount -o subvol=@nix,compress=zstd,noatime       "$ROOT" /mnt/nix
mount -o subvol=@snapshots,compress=zstd,noatime "$ROOT" /mnt/.snapshots
mount "$BOOT" /mnt/boot
```

### Step 9 — home migration

From a TTY with the desktop session closed, or you are copying open browser and
sqlite state mid-write.

```bash
sudo rsync -aHAX --info=progress2 \
  --exclude '.cache/' --exclude '.local/share/Trash/' \
  /home/aron/ /mnt/home/aron/
```

## Known target values (verified 2026-08-06)

| Thing | Value |
|---|---|
| Crucial by-id | `/dev/disk/by-id/nvme-CT1000P310SSD8_252550DB0A3E` → `/dev/nvme0n1` |
| Ignore these aliases | the `…_1` variant and `nvme-eui.00a0750150db0a3e` |
| Samsung (rollback) | `sdb`, **USB**, ext4 root UUID `4c7138e6-…`, ESP `DFD1-432B` |
| Data HDD | `sda1`, NTFS UUID `B41E0A3F1E09FB5E`, label `Data` |
| `aron` uid | 1000 |

## Not covered by the plan

- `/etc/machine-id` and the host SSH keys are not migrated — `rsync` only copies
  `/home`. New host keys are generated on first boot, so anything that has this
  machine in a `known_hosts` will warn once. `~/.ssh` (your *user* keys) does
  come across with the home directory.
- After G3, `nix.gc.options` is `--delete-older-than 30d`, not the plan's `14d`.
  The longer window is a wider rollback net; left as-is deliberately.
