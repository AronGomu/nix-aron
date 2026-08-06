# desk-main running from the Crucial P310 NVMe (Btrfs). Flake output:
# `desk-main-nvme`. This is the migration target.
{
  imports = [
    ./common.nix
    ./storage.nvme.nix
  ];
}
