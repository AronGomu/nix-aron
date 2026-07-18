{
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 20;
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
