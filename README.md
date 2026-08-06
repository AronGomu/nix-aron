# nix-aron

Reproducible NixOS 26.05 daily-driver config for user `aron`.

Hosts (one `main` branch, not per-machine branches):

| Flake attr | Path | Notes |
|---|---|---|
| `desk-main-samsung` | `hosts/desk-main/samsung.nix` | desktop on the Samsung 860 EVO (ext4) — the rollback system |
| `desk-main-nvme` | `hosts/desk-main/nvme.nix` | desktop on the Crucial P310 (Btrfs) — the migration target |
| — | `hosts/_template` | copy to add a machine |

One flake output **per disk**, sharing `hosts/desk-main/common.nix`. There is no
bare `desk-main` attr on purpose: `nixos-rebuild switch` applies the new
`fileSystems` to the *running* system immediately, so a config carrying the
other disk's layout mounts that disk's `/nix` and `/home` over the live ones and
the machine loses its shell mid-command. Naming the disk makes that a typo you
cannot make; a stale `#desk-main` fails with "unknown flake output".

`nixos-host` reads the running root's UUID and prints the matching attr, so the
usual command never needs to know which disk booted:

```bash
sudo nixos-rebuild switch --flake ~/config/nix-aron#$(nixos-host)   # = the `rebuild` alias
```

Home Manager changes apply through the same command — there is no standalone
`homeConfigurations` output, because running one would strip the desktop config.

Changing `fileSystems`? Use `nixos-rebuild boot` (the `rebuild-boot` alias) and
reboot. `switch` is never safe for a mount change.

`boot` is not a safety net for the *wrong output* though — it still installs
bootloader entries into the running disk's ESP. `hosts/desk-main/esp-guard.nix`
catches that and fails loudly. Only `nix build` / `nixos-rebuild build` are
unconditionally safe.

**First rebuild after the per-disk split:** `nixos-host` lives in the new
generation, so it is absent from the one you are running and `rebuild` errors
until you switch once. Bootstrap by naming the disk you are booted from —
`sudo nixos-rebuild switch --flake ~/config/nix-aron#desk-main-samsung` — and
never by substituting the other disk's name.

## Design

- NixOS stable base; selected fast-moving desktop/agent apps from unstable
- XFCE on X11, LightDM, Ghostty, tmux, Neovim
- NVIDIA RTX 5060 Ti using open kernel module plus proprietary userspace
- systemd-boot, Btrfs, zram; no disk encryption; no Secure Boot
- Home Manager for user apps, dotfiles, Pi, Codex
- Rootless Docker, Steam/Proton, OBS/NVENC, DaVinci Resolve Free
- Tailscale plus key-only SSH restricted to `tailscale0`

## Safety boundary

This repo does not partition disks or install NixOS automatically. `hardware-configuration.nix` is generic until regenerated on target hardware.

**Disk setup below destroys every partition on selected target disk. Verify target by model, serial, and size. Never select Windows NVMe or 4 TB data HDD. Keep backups.**

## Target disk layout

Expected labels:

| Label | Size | FS | Purpose |
|---|---:|---|---|
| `NIXBOOT` | 1 GiB | FAT32 | EFI system partition |
| `NIXROOT` | remaining | Btrfs | NixOS subvolumes |
| `Data` | existing | NTFS | shared 4 TB HDD, mounted `/mnt/data` |

Example from NixOS installer ISO. Replace `/dev/nvmeXn1` only after checking `lsblk`.

```bash
sudo -i
lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,LABEL,MOUNTPOINTS
export DISK=/dev/nvmeXn1

# DESTRUCTIVE: stop unless DISK is new dedicated NixOS NVMe.
sgdisk --zap-all "$DISK"
sgdisk -n 1:0:+1G -t 1:ef00 -c 1:NIXBOOT "$DISK"
sgdisk -n 2:0:0 -t 2:8300 -c 2:NIXROOT "$DISK"
mkfs.fat -F 32 -n NIXBOOT "${DISK}p1"
mkfs.btrfs -f -L NIXROOT "${DISK}p2"

mount /dev/disk/by-label/NIXROOT /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@snapshots
umount /mnt

mount -o subvol=@,compress=zstd,noatime /dev/disk/by-label/NIXROOT /mnt
mkdir -p /mnt/{boot,home,nix,.snapshots,mnt/data}
mount -o subvol=@home,compress=zstd,noatime /dev/disk/by-label/NIXROOT /mnt/home
mount -o subvol=@nix,compress=zstd,noatime /dev/disk/by-label/NIXROOT /mnt/nix
mount -o subvol=@snapshots,compress=zstd,noatime /dev/disk/by-label/NIXROOT /mnt/.snapshots
mount /dev/disk/by-label/NIXBOOT /mnt/boot
```

## Install

Place this repo at `/mnt/etc/nixos` by cloning its private remote or copying it from USB. SSH cloning requires your GitHub key loaded in installer session.

```bash
mkdir -p /mnt/etc
git clone git@github.com:AronGomu/nix-aron.git /mnt/etc/nixos
cd /mnt/etc/nixos

# Replace generic HW scan. storage.<disk>.nix remains authoritative for mount layout.
nixos-generate-config --root /mnt --show-hardware-config > hosts/desk-main/hardware-configuration.nix

nixos-install --flake .#desk-main-nvme
nixos-enter --root /mnt -c 'passwd aron'
reboot
```

Use motherboard UEFI menu to select NixOS or Windows. Windows EFI remains untouched. For dual-boot clock consistency, configure Windows `RealTimeIsUniversal=1`; keep Linux hardware clock in UTC.

## First login

```bash
sudo tailscale up
pi
# Run /login inside Pi.
codex
# Complete Codex login.
gh auth login
```

Manual GUI setup:

1. Brave Sync; install Bitwarden extension. Bitwarden Desktop is omitted because current stable and unstable packages depend on EOL Electron 39; do not permit that insecure runtime.
2. Install WhatsApp as Brave PWA.
3. Sign into Discord, Telegram, Teams, Thunderbird, Steam.
4. XFCE Display settings: Philips primary/left, Samsung right, both 1920x1080@60.
5. Confirm OBS NVENC encoder.
6. Keep Steam library on Linux Btrfs NVMe, not NTFS `Data`.
7. Configure Restic destination before enabling automated backups.

## Rebuild/update

```bash
sudo nixos-rebuild switch --flake ~/config/nix-aron#$(nixos-host)
nix flake update --flake ~/config/nix-aron
```

Updates stay manual. Nix GC runs weekly, deleting generations older than 30 days.

## Validation from current WSL host

Current WSL has no Nix. Validate through disposable Docker container:

```bash
docker run --rm -v "$PWD:/work" -w /work nixos/nix \
  nix --extra-experimental-features 'nix-command flakes' flake check path:/work
```

## Deliberately excluded

- Auth tokens, API keys, agent sessions/history/cache/SQLite state
- Password hash
- LUKS, Secure Boot/Lanzaboote, hibernation
- Disko, printer/scanner, VM stack
- Steam Remote Play firewall ports
- Automatic OS upgrades
