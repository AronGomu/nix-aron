{ pkgs, ... }:
{
  services = {
    xserver = {
      enable = true;
      xkb.layout = "us";
      # delay ms before repeat; interval ms between repeats (~58.8/s)
      autoRepeatDelay = 250;
      autoRepeatInterval = 17;
      excludePackages = [ pkgs.xterm ];
    };
    displayManager.gdm.enable = true;
    desktopManager.gnome = {
      enable = true;
      flashback.enableMetacity = true;
    };
    gvfs.enable = true;
    printing.enable = false;
  };

  security.polkit.enable = true;

  fonts.packages = with pkgs; [
    dejavu_fonts
    liberation_ttf
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
  ];
}
