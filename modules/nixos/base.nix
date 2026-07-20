{ pkgs, ... }:
{
  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  users = {
    mutableUsers = true;
    users.aron = {
      isNormalUser = true;
      description = "AronGomu";
      uid = 1000;
      extraGroups = [
        "audio"
        "networkmanager"
        "video"
        "wheel"
      ];
      shell = pkgs.bashInteractive;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGSCUB7DqYG3cmwY90/NYyscO6+wGA/VdcmP4ePPWY0c aron@aron"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILgCeud0RH93LSxI9DE0ZHb5LLyROwfJ3dagxUiNYjjF aron@nixos"
      ];
    };
  };

  security = {
    sudo.wheelNeedsPassword = true;
    rtkit.enable = true;
  };

  hardware = {
    enableRedistributableFirmware = true;
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };

  services = {
    blueman.enable = true;
    fstrim.enable = true;
    fwupd.enable = true;
    # Enable after moving root to Btrfs (see hosts/desk-main/storage.btrfs.nix).
    btrfs.autoScrub = {
      enable = false;
      interval = "monthly";
      fileSystems = [ "/" ];
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };

  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  programs.nix-ld.enable = true;

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  environment.systemPackages = with pkgs; [
    git
    restic
    vim
    wget
  ];
}
