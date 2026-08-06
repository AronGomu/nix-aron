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

- `hosts/desk-main/storage.nvme.nix` (was `storage.btrfs.nix`) — rewritten. Was
  `by-label`, now `by-uuid`. `/mnt/data` moved from `umask=0022` (which marks
  every file executable) to `fmask=0133` + `dmask=0022`, plus `windows_names`.
  Gained `services.btrfs.autoScrub`.
- `modules/nixos/base.nix` — the disabled `services.btrfs.autoScrub` block moved
  out to the host's Btrfs module, where the layout it describes actually exists.
- `hosts/desk-main/disks.nix` — every UUID for both disks, one place.
  `fill-uuids.sh` writes the `nvme` block at G0.
- `hosts/desk-main/default.nix` — gone, split into `common.nix` (no storage) plus
  `samsung.nix` / `nvme.nix`. See the next section for why.

## There is no import to flip (post-incident, 2026-08-06)

The original design had one `desk-main` output whose `default.nix` was flipped
from `storage.nix` to `storage.btrfs.nix` at G0, guarded only by a written rule:
*do not run `nixos-rebuild switch` on the Samsung after the flip*.

That rule was broken twice on 2026-08-06 (generations 68 and 69). `switch` does
not merely stage a boot entry — it applies the new `fileSystems` to the running
system immediately. From the journal:

    home.mount: Directory /home to mount over is not empty, mounting anyway.
    Mounted /home.
    nix.mount: Directory /nix to mount over is not empty, mounting anyway.
    Mounted /nix.
    nixos-rebuild-switch-to-configuration.service: Main process exited, status=4

The NVMe's `@nix` was stacked over the live store, so every binary path resolved
into the wrong copy and the shell died mid-command; `@home` took the dotfiles
with it. `/boot` was unmounted from the Samsung ESP and the NVMe ESP mounted in
its place. Only `-.mount` failing (`status=32`) kept `/` on ext4. The boot entry
had already been written to the Samsung ESP by then, pointing at a store path
that exists only on the Samsung while `root=fstab` said NVMe — so the machine
did not come back either.

The layout choice is therefore no longer a line anyone can flip. Each disk is
its own flake output:

| Attr | Entry | Storage |
|---|---|---|
| `desk-main-samsung` | `hosts/desk-main/samsung.nix` | `storage.samsung.nix` (ext4) |
| `desk-main-nvme` | `hosts/desk-main/nvme.nix` | `storage.nvme.nix` (Btrfs) |

Both are always present and always buildable; neither can be reached without
naming it. There is no bare `desk-main`, so a stale command fails with "unknown
flake output" rather than switching disks under a running system. `nixos-host`
resolves the running root's UUID to its attr, and the `rebuild` alias calls it,
so the everyday command is correct on either disk without being edited at G3.

Building the other disk's output is safe — `nix build` and `nixos-rebuild build`
touch nothing.

`boot` is **not** safe for the other disk's output. It moves no mounts, but it
still runs the bootloader installer, which writes entries into whatever is
mounted at `/boot` — the running disk's ESP. The result is BRICK-1's shape:
an entry naming one disk's root with an `init=` that resolves only in the other
disk's store. `hosts/desk-main/esp-guard.nix` compares `/boot`'s UUID against
the output's own ESP and fails loudly with a recovery path, but only *after* the
entries are written, so the cleanup is manual. Use `rebuild-boot`, never a
hand-typed `--flake .#desk-main-<other>`.

### First rebuild after this restructure

`nixos-host` ships in the new generation, so it does not exist yet in whatever
generation you are running now. Until you switch once, the `rebuild` alias
resolves to nothing and errors out. Bootstrap it by naming the disk explicitly,
**once**, and only the one you are actually booted from:

```bash
sudo nixos-rebuild switch --flake ~/config/nix-aron#desk-main-samsung
```

Do not "fix" that first error by substituting `#desk-main-nvme`. That is the
2026-08-06 command.

## Order of operations

Everything before step 4 is non-destructive and reversible.

| # | Command | Plan § | 2026-08-06 |
|---|---|---|---|
| 1 | `docs/migration/baseline.sh` | §3 | done |
| 2 | `nixos-rebuild build --flake .#desk-main-nvme` | §3 | done |
| 3 | `docs/migration/preflight-disk.sh` | §4 | done |
| 4 | `sudo docs/migration/wipe-and-format.sh` | §4 | done |
| 5 | `sudo docs/migration/mount-target.sh` | §4 | done |
| 6 | `docs/migration/fill-uuids.sh` | §5.1 | done |
| 7 | `docs/migration/g0-verify.sh` — **G0** | §5.1 | PASSED |
| 8 | `sudo nixos-install --flake /home/aron/config/nix-aron#desk-main-nvme` | §5.2 | done |
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
