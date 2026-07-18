{ pkgs, ... }:
{
  services = {
    xserver = {
      enable = true;
      xkb.layout = "us";
      excludePackages = [ pkgs.xterm ];
      displayManager.lightdm.enable = true;
      desktopManager.xfce = {
        enable = true;
        enableScreensaver = true;
      };
    };
    gvfs.enable = true;
    tumbler.enable = true;
    printing.enable = false;
  };

  programs.xfconf.enable = true;

  environment.systemPackages = with pkgs; [
    thunar-archive-plugin
    thunar-volman
    xfce4-clipman-plugin
  ];

  fonts.packages = with pkgs; [
    dejavu_fonts
    liberation_ttf
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
  ];
}
