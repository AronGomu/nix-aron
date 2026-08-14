{ pkgs, ... }:
{
  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  programs = {
    ydotool.enable = true;
  };

  hardware.uinput.enable = true;

  users = {
    # mutableUsers: every credential lives in the target's /etc/shadow, and no
    # initialHashedPassword is declared here. A FRESH /etc therefore has no
    # login at all — nixos-install sets root only, and sync-home.sh copies /home,
    # not /etc. docs/migration/post-install-checks.sh is the gate that catches
    # this; do not skip it after an install. Setting initialHashedPassword (from
    # `mkpasswd -m yescrypt`) is the only thing that makes a fresh /etc
    # self-sufficient — it applies at account creation only, so it does not
    # fight `passwd` on an existing system.
    mutableUsers = true;
    users.aron = {
      isNormalUser = true;
      description = "AronGomu";
      uid = 1000;
      extraGroups = [
        "audio"
        "networkmanager"
        "uinput"
        "video"
        "wheel"
        "ydotool"
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
    # btrfs.autoScrub is layout-specific — it lives in the host's Btrfs storage
    # module (hosts/desk-main/storage.btrfs.nix), not here.
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.extraConfig."51-audio-defaults" = {
        "monitor.alsa.rules" = [
          {
            # ALC897 jack detect lies (all ports "unavailable") → WP refuses
            # analog-stereo as default. pro-audio has no jack routes → works.
            matches = [ { "device.name" = "alsa_card.pci-0000_0e_00.6"; } ];
            actions = {
              update-props = {
                "device.profile" = "pro-audio";
              };
            };
          }
          {
            # Q2U is a mic — never pick its playback path as default sink
            matches = [
              { "device.name" = "~alsa_card.usb-Samson_Technologies_Samson_Q2U.*"; }
            ];
            actions = {
              update-props = {
                "device.profile" = "input:analog-stereo";
              };
            };
          }
          {
            # Prefer onboard Realtek over HDMI monitors
            matches = [
              { "node.name" = "~alsa_output.pci-0000_0e_00.6.*"; }
            ];
            actions = {
              update-props = {
                "priority.session" = 2000;
                "priority.driver" = 2000;
              };
            };
          }
          {
            matches = [
              { "node.name" = "~alsa_output.*.hdmi.*"; }
            ];
            actions = {
              update-props = {
                "priority.session" = 100;
                "priority.driver" = 100;
              };
            };
          }
        ];
      };
    };
  };

  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  # Shared libraries for FHS-style binaries that download their own runtime, most
  # notably the Chromium/Firefox/WebKit builds Playwright fetches into
  # ~/.cache/ms-playwright. Without these they die at load with libglib-2.0.so.0 /
  # libnss3.so / libnspr4.so missing, and no e2e suite can run on this host.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      dbus
      expat
      glib
      gtk3
      libdrm
      libgbm
      libx11
      libxcb
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxkbcommon
      libxrandr
      nspr
      nss
      pango
    ];
  };

  hardware.graphics.extraPackages = with pkgs; [ vulkan-loader ];
  environment.variables.SDL_VULKAN_LIBRARY = "/run/opengl-driver/lib/libvulkan.so.1";

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  environment.systemPackages = with pkgs; [
    # Inspecting and repairing UEFI boot entries. systemd ships bootctl, but only
    # efibootmgr can list and delete NVRAM entries — needed to tell two identically
    # labelled "Linux Boot Manager" entries apart after a disk migration.
    efibootmgr
    git
    gptfdisk
    restic
    vim
    wget
    yt-dlp
  ];
}
