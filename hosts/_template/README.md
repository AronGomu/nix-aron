# New host checklist

```bash
cp -r hosts/_template hosts/<name>
# edit hosts/<name>/default.nix  (hostname + optional modules)

# on the machine, after disks mounted at /mnt (install) or on running system:
nixos-generate-config --show-hardware-config \
  > hosts/<name>/hardware-configuration.nix
# strip fileSystems/swapDevices from that file if present — mounts live in storage.nix

# write hosts/<name>/storage.nix (start from storage.btrfs.nix if using INSTALL.md layout)

# register in flake.nix:
#   nixosConfigurations.<name> = nixpkgs.lib.nixosSystem { modules = [ ./hosts/<name> ... ]; };

# install or switch
nixos-install --flake .#<name>
# or
sudo nixos-rebuild switch --flake .#<name>
```

**Do not** commit real secrets. Hardware + storage are machine-local but safe to commit (UUIDs/labels only).
