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

  # KDE/Qt apps (Dolphin) on Hyprland: Breeze, not broken gtk2 bridge
  qt = {
    enable = true;
    platformTheme.name = "kde";
    style.name = "breeze";
  };

  xdg = {
    enable = true;
    desktopEntries = {
      obsidian = {
        name = "Obsidian";
        comment = "Knowledge base";
        exec = "${pkgs.obsidian}/bin/obsidian %U";
        icon = "obsidian";
        terminal = false;
        categories = [ "Office" ];
        mimeType = [ "x-scheme-handler/obsidian" ];
      };
      # Absolute Exec: Dolphin/KIO on NixOS often resolves bare `mpv` → /usr/bin/mpv (missing).
      mpv = {
        name = "mpv Media Player";
        genericName = "Multimedia player";
        comment = "Play movies and songs";
        exec = "${pkgs.mpv}/bin/mpv --player-operation-mode=pseudo-gui -- %U";
        icon = "mpv";
        terminal = false;
        categories = [
          "AudioVideo"
          "Audio"
          "Video"
          "Player"
        ];
        mimeType = [
          "video/mp4"
          "video/x-matroska"
          "video/webm"
          "video/quicktime"
          "video/x-msvideo"
          "video/x-ms-wmv"
          "video/mpeg"
          "video/ogg"
          "video/mp2t"
          "video/3gpp"
          "video/x-flv"
          "audio/mpeg"
          "audio/flac"
          "audio/ogg"
          "audio/mp4"
          "audio/x-wav"
        ];
        settings = {
          StartupWMClass = "mpv";
          TryExec = "${pkgs.mpv}/bin/mpv";
        };
      };
    };
    mimeApps = {
      enable = true;
      defaultApplications = {
        "application/pdf" = [ "org.gnome.Evince.desktop" ];
        "audio/mpeg" = [ "org.strawberrymusicplayer.strawberry.desktop" ];
        "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
        "image/png" = [ "org.gnome.Loupe.desktop" ];
        "inode/directory" = [ "org.kde.dolphin.desktop" ];
        "message/rfc822" = [ "thunderbird.desktop" ];
        "text/html" = [ "brave-browser.desktop" ];
        "video/mp4" = [ "mpv.desktop" ];
        "video/x-matroska" = [ "mpv.desktop" ];
        "video/webm" = [ "mpv.desktop" ];
        "video/quicktime" = [ "mpv.desktop" ];
        "video/x-msvideo" = [ "mpv.desktop" ];
        "video/mpeg" = [ "mpv.desktop" ];
        "x-scheme-handler/http" = [ "brave-browser.desktop" ];
        "x-scheme-handler/https" = [ "brave-browser.desktop" ];
        "x-scheme-handler/mailto" = [ "thunderbird.desktop" ];
      };
    };

    configFile = {
      "xdg-terminals.list".text = ''
        com.mitchellh.ghostty.desktop
      '';
      kdeglobals.text = ''
        [General]
        ColorScheme=BreezeDark

        [Icons]
        Theme=breeze-dark

        [KDE]
        LookAndFeelPackage=org.kde.breezedark.desktop

        [UiSettings]
        ColorScheme=*Dark*
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
