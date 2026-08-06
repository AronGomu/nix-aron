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

| # | Command | Plan § | 2026-08-06 |
|---|---|---|---|
| 1 | `docs/migration/baseline.sh` | §3 | done |
| 2 | `nixos-rebuild build --flake .#desk-main` | §3 | done |
| 3 | `docs/migration/preflight-disk.sh` | §4 | done |
| 4 | `sudo docs/migration/wipe-and-format.sh` | §4 | done |
| 5 | `sudo docs/migration/mount-target.sh` | §4 | done |
| 6 | `docs/migration/fill-uuids.sh` | §5.1 | done |
| 7 | `docs/migration/g0-verify.sh` — **G0** | §5.1 | PASSED |
| 8 | `sudo nixos-install --flake /home/aron/config/nix-aron#desk-main` | §5.2 | done |
| 9 | `sudo docs/migration/sync-home.sh` (twice) | §5.3 | done, 22 GB |
| 10 | `docs/migration/post-install-checks.sh` | §5.2, §5.3, §8 | READY FOR G3 |
| 11 | shut down, unplug the Samsung, boot — **G3** | §8 | |

Steps 4 and 5 were hand-typed commands in rev 3 of the plan; they are scripts
here so the guards are auditable rather than dependent on typing correctly at
the one moment where a typo is unrecoverable.

## Result of the destructive phase (2026-08-06)

| | |
|---|---|
| `nvme0n1p1` | 1 GB vfat, `NIXBOOT`, UUID `61EA-07B3`, PARTUUID `1aed035f-d8cb-4448-8a96-b7facc556024` |
| `nvme0n1p2` | 930.5 GB btrfs, `NIXROOT`, UUID `5b251757-c14c-4641-aec5-cea83857290b` |
| Subvolumes | `@` 256, `@home` 257, `@nix` 258, `@snapshots` 259 |
| Home copied | 22 GB (73 GB before exclusions) |

btrfs-progs 6.19 enables `block-group-tree` by default. It needs kernel ≥ 6.1,
which every kernel this flake builds satisfies — but a pre-6.1 rescue ISO will
not mount this root. The recovery stick is 26.05 and is fine.

### Both boot paths exist on the NVMe

`nixos-install` wrote `\EFI\systemd\systemd-bootx64.efi` **and** the firmware
fallback `\EFI\BOOT\BOOTX64.EFI`, and registered `Boot0000 Linux Boot Manager`.
That entry was created *last* in `BootOrder`, behind Windows and PXE. With the
Samsung unplugged the firmware would have walked past a dead Windows entry and
sat in a DHCP timeout before reaching the real system. Reordered before G3:

    sudo efibootmgr -o 0000,0006,0003,0001,0002,0005

`0000` is the NVMe, `0006` is the Samsung's `UEFI OS` fallback entry — kept
second so the rollback still boots. `0003` (Windows) points at the PARTUUID
`c92098bf-…` that the wipe destroyed; it is dead and gets deleted in §9.

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
