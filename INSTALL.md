# NixOS installation on a new SSD

This guide installs the configuration from this repository onto a dedicated new NVMe SSD.

## Assumptions

- New SSD is dedicated to NixOS.
- Existing Windows NVMe must remain untouched.
- Existing 4 TB NTFS HDD must remain untouched.
- NixOS uses systemd-boot, Btrfs, zram, X11, and XFCE.
- Disk encryption and Secure Boot are intentionally disabled.
- Repository is private on GitHub.

## 1. Prepare

1. Back up all important data.
2. Download the NixOS 26.05 ISO.
3. Write the ISO to a USB drive.
4. Power off the computer.
5. For maximum safety, temporarily disconnect the Windows NVMe and 4 TB HDD.
6. Install the new NVMe SSD.
7. Enter UEFI settings and disable Secure Boot.
8. Boot the NixOS USB in UEFI mode.
9. Connect to the network from the live environment.

## 2. Identify the new SSD

Open a terminal and become root:

```bash
sudo -i
lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,LABEL,MOUNTPOINTS
```

> **Destructive-action warning:** Commands below erase every partition on the selected disk. Verify model, serial number, and size. Never select the Windows NVMe or 4 TB data HDD.

Set the new NVMe path. `/dev/nvme0n1` is only an example:

```bash
export DISK=/dev/nvme0n1
export BOOT="${DISK}p1"
export ROOT="${DISK}p2"

lsblk -o NAME,SIZE,MODEL,SERIAL "$DISK"
```

Stop if displayed disk is not the new dedicated NixOS SSD.

## 3. Partition and format

The layout uses:

| Partition | Size | Type | Label | Purpose |
|---|---:|---|---|---|
| 1 | 1 GiB | EFI System Partition | `NIXBOOT` | systemd-boot |
| 2 | Remaining space | Linux filesystem | `NIXROOT` | Btrfs system data |

Erase and partition the selected disk:

```bash
sgdisk --zap-all "$DISK"
sgdisk -n 1:0:+1G -t 1:ef00 -c 1:NIXBOOT "$DISK"
sgdisk -n 2:0:0 -t 2:8300 -c 2:NIXROOT "$DISK"

partprobe "$DISK"
lsblk -o NAME,SIZE,PARTTYPE,PARTLABEL "$DISK"
```

Format both partitions:

```bash
mkfs.fat -F 32 -n NIXBOOT "$BOOT"
mkfs.btrfs -f -L NIXROOT "$ROOT"
```

## 4. Create the Btrfs layout

Create Btrfs subvolumes:

```bash
mount "$ROOT" /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@snapshots

umount /mnt
```

Mount the final layout:

```bash
mount -o subvol=@,compress=zstd,noatime "$ROOT" /mnt
mkdir -p /mnt/{boot,home,nix,.snapshots,mnt/data}

mount -o subvol=@home,compress=zstd,noatime "$ROOT" /mnt/home
mount -o subvol=@nix,compress=zstd,noatime "$ROOT" /mnt/nix
mount -o subvol=@snapshots,compress=zstd,noatime "$ROOT" /mnt/.snapshots
mount "$BOOT" /mnt/boot
```

Verify mounts:

```bash
findmnt /mnt
findmnt /mnt/home
findmnt /mnt/nix
findmnt /mnt/.snapshots
findmnt /mnt/boot
```

## 5. Clone the private repository

Authenticate using GitHub device flow. Credentials remain in the temporary live environment and disappear after reboot.

```bash
nix --extra-experimental-features "nix-command flakes" \
  shell nixpkgs#gh nixpkgs#git -c gh auth login
```

Clone the repository:

```bash
mkdir -p /mnt/etc

nix --extra-experimental-features "nix-command flakes" \
  shell nixpkgs#gh nixpkgs#git -c \
  gh repo clone AronGomu/nix-aron /mnt/etc/nixos

cd /mnt/etc/nixos
```

Alternative: copy the repository from another USB drive into `/mnt/etc/nixos`.

## 6. Generate the machine-specific hardware configuration

Replace the generic hardware scan with one generated on the target machine:

```bash
cd /mnt/etc/nixos

nixos-generate-config \
  --root /mnt \
  --show-hardware-config \
  > hosts/desk-main/hardware-configuration.nix
```

`hosts/desk-main/storage.nix` remains authoritative for Btrfs labels, subvolumes, and mount options.

Review generated hardware configuration:

```bash
less hosts/desk-main/hardware-configuration.nix
```

## 7. Optional pre-install evaluation

Evaluate the flake before installing:

```bash
nix --extra-experimental-features "nix-command flakes" \
  flake check --no-build
```

This validates the NixOS and Home Manager configuration without installing it.

## 8. Install NixOS

Run the installer:

```bash
nixos-install --flake .#desk-main-nvme   # name the target disk; nixos-host does not exist yet at install time
```

The installer may request a root password. Set the `aron` user password before rebooting:

```bash
nixos-enter --root /mnt -c 'passwd aron'
```

Confirm the repository and boot files exist:

```bash
ls /mnt/etc/nixos
ls /mnt/boot
```

## 9. Power off and reconnect existing disks

Flush pending writes and power off:

```bash
sync
poweroff
```

After shutdown:

1. Reconnect the Windows NVMe.
2. Reconnect the 4 TB NTFS HDD.
3. Enter UEFI settings.
4. Select the new NixOS SSD as the preferred boot device.
5. Keep Secure Boot disabled.
6. Use the motherboard UEFI boot menu when selecting Windows manually.

Windows EFI remains on the Windows disk. NixOS EFI remains on the new NixOS disk.

## 10. First login

Log in as `aron` using the password created during installation.

Connect Tailscale:

```bash
sudo tailscale up
```

Authenticate development tools:

```bash
gh auth login
pi
codex
```

Inside Pi, run `/login`. Complete the Codex login flow when prompted. Credentials
land in `~/.pi/agent/auth.json`, which `.gitignore` keeps out of this repo.

`/login anthropic` is optional and only powers the `/opus`, `/sonnet` and
`/claude` switches. A Claude subscription does **not** cover them: Anthropic
meters third-party harnesses against extra usage, per token, so those switches
return HTTP 400 until extra usage is funded at `claude.ai/settings/usage` (or
`ANTHROPIC_API_KEY` is set in `~/.pi/agent/configs/.env` to bill API credits
instead). The LLM council therefore keeps a Codex chairman.

## 11. Verify the installation

Check NixOS version and mounts:

```bash
nixos-version
findmnt /
findmnt /home
findmnt /nix
findmnt /boot
findmnt /mnt/data
```

Check NVIDIA support:

```bash
nvidia-smi
```

Check X11/XFCE:

```bash
echo "$XDG_SESSION_TYPE"
echo "$XDG_CURRENT_DESKTOP"
```

Expected values include:

```text
x11
XFCE
```

Check remote-access services:

```bash
systemctl status tailscaled --no-pager
systemctl status sshd --no-pager
```

Check rootless Docker:

```bash
systemctl --user status docker --no-pager
docker info
```

## 12. Complete desktop setup

1. Open XFCE Display settings.
2. Set Philips monitor as primary/left.
3. Set Samsung monitor as right.
4. Set both monitors to `1920x1080@60`.
5. Sign into Brave Sync.
6. Install the Bitwarden Brave extension.
7. Install WhatsApp as a Brave PWA.
8. Sign into Discord, Telegram, Teams, Thunderbird, and Steam.
9. Confirm OBS offers the NVIDIA NVENC encoder.
10. Keep the Steam library on the Linux Btrfs NVMe, not the NTFS data disk.
11. Configure a Restic backup destination before enabling automated backups.

## 13. Rebuild and update later

Rebuild after configuration changes:

```bash
sudo nixos-rebuild switch --flake ~/config/nix-aron#$(nixos-host)
```

Update pinned flake inputs manually:

```bash
cd ~/config/nix-aron
nix flake update
sudo nixos-rebuild switch --flake .#$(nixos-host)
```

The configuration runs weekly Nix garbage collection and removes generations older than 30 days.

## Troubleshooting

### Repository clone fails

The repository is private. Confirm GitHub authentication:

```bash
gh auth status
```

Otherwise copy the repository from USB.

### NixOS boot entry is missing

Boot the NixOS USB again, mount the installed layout, then reinstall systemd-boot through `nixos-install`. Confirm the live environment was booted in UEFI mode:

```bash
test -d /sys/firmware/efi && echo UEFI || echo Legacy-BIOS
```

### NTFS data disk does not mount

Check the label after reconnecting the HDD:

```bash
lsblk -f
```

Expected label: `Data`. Windows Fast Startup must be disabled before mounting Windows-managed NTFS filesystems read/write from Linux.

### NVIDIA does not initialize

Confirm monitors are connected to the RTX 5060 Ti, not motherboard display outputs. Then inspect:

```bash
nvidia-smi
journalctl -b -k | grep -i nvidia
```
