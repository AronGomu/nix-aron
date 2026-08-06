{
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        # The Samsung ESP is 511 MB. Generations sharing a kernel are nearly
        # free, but a distinct kernel+initrd pair is ~41 MB, so 20 generations
        # across a run of nixpkgs bumps overflows it and `nixos-rebuild` then
        # fails at bootloader install — recoverable, but at the worst moment.
        # 10 leaves headroom on both ESPs (the NVMe's is 1 GB).
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
      timeout = 5;
    };
    supportedFilesystems = [
      "btrfs"
      "ntfs"
    ];
  };
}
