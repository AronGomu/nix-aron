{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.desktop.end4.enable = lib.mkEnableOption "end-4 Hyprland desktop";

  config = lib.mkIf config.desktop.end4.enable {

    programs = {
      hyprland = {
        enable = true;
        withUWSM = false;
        xwayland.enable = true;
      };
      ydotool.enable = true;
    };

    # Keep i3 and GNOME available in GDM while making Hyprland the default.
    services = {
      displayManager.defaultSession = lib.mkForce "hyprland";
      gnome.gnome-keyring.enable = true;
      upower.enable = true;
    };

    hardware.i2c.enable = true;
    boot.kernelModules = [ "i2c-dev" ];
    users.users.aron.extraGroups = [
      "i2c"
      "input"
    ];

    security.pam.services.hyprlock = { };

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };
  };
}
