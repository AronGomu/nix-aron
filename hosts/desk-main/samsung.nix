# desk-main running from the Samsung 860 EVO (ext4). Flake output:
# `desk-main-samsung`. This is the rollback system.
{
  imports = [
    ./common.nix
    ./storage.samsung.nix
  ];
}
