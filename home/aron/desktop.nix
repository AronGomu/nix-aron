{ lib, pkgs, ... }:
let
  # KDE/KIO indexes applications into ksycoca through an XDG menu file. Plasma ships
  # one; a bare Hyprland session ships none, so kbuildsycoca6 registered ZERO services
  # ("unknown service mpv.desktop in Default Applications") and every Dolphin
  # double-click silently did nothing. This minimal menu just says "index everything".
  applicationsMenu = ''
    <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN" "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
    <Menu>
      <Name>Applications</Name>
      <DefaultAppDirs/>
      <DefaultDirectoryDirs/>
      <DefaultMergeDirs/>
      <Include>
        <All/>
      </Include>
    </Menu>
  '';
in
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
        "video/3gpp" = [ "mpv.desktop" ];
        "video/mp2t" = [ "mpv.desktop" ];
        "video/mp4" = [ "mpv.desktop" ];
        "video/mpeg" = [ "mpv.desktop" ];
        "video/ogg" = [ "mpv.desktop" ];
        "video/quicktime" = [ "mpv.desktop" ];
        "video/vnd.avi" = [ "mpv.desktop" ];
        "video/webm" = [ "mpv.desktop" ];
        "video/x-flv" = [ "mpv.desktop" ];
        "video/x-m4v" = [ "mpv.desktop" ];
        "video/x-matroska" = [ "mpv.desktop" ];
        "video/x-ms-wmv" = [ "mpv.desktop" ];
        "video/x-msvideo" = [ "mpv.desktop" ];
        "x-scheme-handler/http" = [ "brave-browser.desktop" ];
        "x-scheme-handler/https" = [ "brave-browser.desktop" ];
        "x-scheme-handler/mailto" = [ "thunderbird.desktop" ];
      };
    };

    configFile = {
      # Both names: KDE packages set XDG_MENU_PREFIX=plasma-, plain KIO looks for the unprefixed one.
      "menus/applications.menu".text = applicationsMenu;
      "menus/plasma-applications.menu".text = applicationsMenu;

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

  # ksycoca caches are keyed by env hash and never self-heal once built empty:
  # drop them so KDE apps rebuild against the new menu + mime defaults.
  home.activation.rebuildKsycoca = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD rm -f "$HOME"/.cache/ksycoca6_*
    $DRY_RUN_CMD ${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental > /dev/null 2>&1 || true
  '';

  # Dolphin never shows image resolution out of the box: hover tooltips ship
  # disabled and the Dimensions column is off. Both live in files Dolphin keeps
  # rewriting at runtime, so seed them idempotently instead of symlinking them —
  # a read-only dolphinrc would stop Dolphin saving any other setting.
  home.activation.dolphinShowDimensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    kreadconfig=${pkgs.kdePackages.kconfig}/bin/kreadconfig6
    kwriteconfig=${pkgs.kdePackages.kconfig}/bin/kwriteconfig6

    # "Show item information on hover" — tooltip carries the preview + dimensions.
    $DRY_RUN_CMD "$kwriteconfig" --file dolphinrc --group General --key ShowToolTips true

    # GlobalViewProps defaults to true, so this one file drives the column set of
    # every folder.
    viewProps="$HOME/.local/share/dolphin/view_properties/global/.directory"
    roles=$("$kreadconfig" --file "$viewProps" --group Dolphin --key VisibleRoles 2>/dev/null || true)
    case ",$roles," in
      *,Details_dimensions,*)
        : # already there, leave the user's column order alone
        ;;
      *)
        if [ -z "$roles" ]; then
          roles="Details_text,Details_size,Details_modificationtime"
        fi
        $DRY_RUN_CMD mkdir -p "$(dirname "$viewProps")"
        $DRY_RUN_CMD "$kwriteconfig" --file "$viewProps" --group Dolphin \
          --key VisibleRoles "$roles,Details_dimensions"
        # Version 4 is what Dolphin 26.04 considers current; write anything lower
        # (or omit it) and Dolphin "converts" the file, blanking VisibleRoles and
        # then deleting it. Timestamp must not predate General/ViewPropsTimestamp
        # in dolphinrc, or the properties count as stale.
        $DRY_RUN_CMD "$kwriteconfig" --file "$viewProps" --group Dolphin --key Version 4
        $DRY_RUN_CMD "$kwriteconfig" --file "$viewProps" --group Dolphin \
          --key Timestamp "$(date +'%Y,%-m,%-d,%-H,%-M,%-S')"
        ;;
    esac
  '';

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
