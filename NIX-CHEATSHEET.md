# NixOS Cheat Sheet

Active config: `/home/aron/config/nix-aron`

Host flake outputs — one per disk, no bare `desk-main`:

| Attr | Disk | Root FS |
|---|---|---|
| `desk-main-samsung` | Samsung 860 EVO (`sdb`) | ext4 |
| `desk-main-nvme` | Crucial P310 (`nvme0n1`) | Btrfs |

`$(nixos-host)` below resolves to whichever one matches the running root disk.
Never hardcode the other disk's attr: `switch` applies the new `fileSystems`
live, so it would mount that disk's `/nix` and `/home` over the running ones and
kill the shell mid-command. Use `boot` + reboot for any mount change.

## Apply config

```bash
cd /home/aron/config/nix-aron

# Apply config now + make boot default
sudo nixos-rebuild switch --flake .#$(nixos-host)

# Build + activate until reboot only
sudo nixos-rebuild test --flake .#$(nixos-host)

# Build without activating
sudo nixos-rebuild build --flake .#$(nixos-host)

# Build + make boot default without activating now
sudo nixos-rebuild boot --flake .#$(nixos-host)
```

New untracked `.nix` files must enter Git before flake sees them:

```bash
git add path/to/new-file.nix
```

## Update system

```bash
cd /home/aron/config/nix-aron

# Update all flake inputs
nix flake update

# Apply updated config
sudo nixos-rebuild switch --flake .#$(nixos-host)

# Update one input only
nix flake update nixpkgs
```

Review `flake.lock` diff before rebuild:

```bash
git diff flake.lock
```

## Check config

```bash
cd /home/aron/config/nix-aron

# Validate flake outputs
nix flake check

# Show flake outputs
nix flake show

# Check formatting differences
nix fmt -- --check .

# Format Nix files
nix fmt

# Show pending Git changes
git status --short
git diff
```

## Rollback

```bash
# List system generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Roll back immediately
sudo nixos-rebuild switch --rollback

# Choose older generation during boot
# Select "NixOS - All configurations" in boot menu.
```

## Packages

Prefer declarative packages in Nix config. Temporary tools:

```bash
# Run package without installing
nix run nixpkgs#PACKAGE

# Open temp shell containing packages
nix shell nixpkgs#PACKAGE

# Example
nix shell nixpkgs#jq nixpkgs#curl
```

Search packages/options:

```bash
nix search nixpkgs PACKAGE
```

Web search:

- Packages: <https://search.nixos.org/packages>
- NixOS options: <https://search.nixos.org/options>
- Home Manager options: <https://home-manager-options.extranix.com/>

## Generations + cleanup

```bash
# List current system generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Show store usage
nix path-info -Sh /run/current-system
sudo du -sh /nix/store

# Delete old system generations older than 30 days
sudo nix-collect-garbage --delete-older-than 30d

# Delete old user generations older than 30 days
nix-collect-garbage --delete-older-than 30d

# Optimize store
nix-store --optimise
```

Cleanup is irreversible. Keep known-good generations until new config works.

## Troubleshooting

```bash
# Detailed rebuild error
sudo nixos-rebuild switch --flake .#$(nixos-host) --show-trace

# Current NixOS version
nixos-version

# Current system generation
readlink -f /run/current-system

# Failed system services
systemctl --failed

# Failed user services
systemctl --user --failed

# Current boot logs
journalctl -b -p warning

# Service logs
journalctl -u SERVICE -b
journalctl --user -u SERVICE -b
```

## Google Drive mount

```bash
# Initial Google login; remote name must be gdrive
rclone config

# Service status
systemctl --user status rclone-gdrive

# Restart mount
systemctl --user restart rclone-gdrive

# Follow logs
journalctl --user -u rclone-gdrive -f

# Mounted files
ls ~/GoogleDrive
```

## Common workflow

```bash
cd /home/aron/config/nix-aron
$EDITOR home/aron/packages.nix
git diff
sudo nixos-rebuild test --flake .#$(nixos-host)
sudo nixos-rebuild switch --flake .#$(nixos-host)
git status --short
```
