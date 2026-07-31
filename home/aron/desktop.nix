{ lib, pkgs, ... }:
{
  # Hardest blue-light cut: night floor 1000K (redshift min).
  services.redshift = {
    enable = true;
    provider = "manual";
    latitude = "48.86";
    longitude = "2.35";
    temperature = {
      day = 4500;
      night = 1000;
    };
    settings.redshift = {
      brightness-day = "1.0";
      brightness-night = "0.7";
    };
    tray = true;
  };

  gtk = {
    enable = true;
    font = {
      name = "Noto Sans";
      size = 10;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # Qt apps follow dark too
  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "gtk2";
  };

  xdg = {
    enable = true;
    desktopEntries.obsidian = {
      name = "Obsidian";
      comment = "Knowledge base";
      exec = "${pkgs.obsidian}/bin/obsidian %U";
      icon = "obsidian";
      terminal = false;
      categories = [ "Office" ];
      mimeType = [ "x-scheme-handler/obsidian" ];
    };
    mimeApps = {
      enable = true;
      defaultApplications = {
        "application/pdf" = [ "org.gnome.Evince.desktop" ];
        "audio/mpeg" = [ "org.strawberrymusicplayer.strawberry.desktop" ];
        "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
        "image/png" = [ "org.gnome.Loupe.desktop" ];
        "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
        "message/rfc822" = [ "thunderbird.desktop" ];
        "text/html" = [ "brave-browser.desktop" ];
        "video/mp4" = [ "mpv.desktop" ];
        "x-scheme-handler/http" = [ "brave-browser.desktop" ];
        "x-scheme-handler/https" = [ "brave-browser.desktop" ];
        "x-scheme-handler/mailto" = [ "thunderbird.desktop" ];
      };
    };

    configFile = {
      "xdg-terminals.list".text = ''
        com.mitchellh.ghostty.desktop
      '';
    };
  };

  home.activation.addDataBookmark = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    bookmarks="$HOME/.config/gtk-3.0/bookmarks"
    backup="$bookmarks.hm-backup"
    mkdir -p "$(dirname "$bookmarks")"
    if [ ! -e "$bookmarks" ] && [ -e "$backup" ]; then
      cp "$backup" "$bookmarks"
    fi
    touch "$bookmarks"
    if ! ${pkgs.gnugrep}/bin/grep -qxF 'file:///mnt/data Data' "$bookmarks"; then
      printf '%s\n' 'file:///mnt/data Data' >> "$bookmarks"
    fi
  '';
}
