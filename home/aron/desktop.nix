{ lib, pkgs, ... }:
let
  # KDE/KIO indexes applications into ksycoca through an XDG menu file. Plasma ships
  # one; a bare Hyprland session ships none, so kbuildsycoca6 registered ZERO services
  # ("unknown service mpv.desktop in Default Applications") and every Dolphin
  # double-click silently did nothing. This minimal menu just says "index everything".
  # The MSE menu launcher is a tkinter GUI; the bare system python3 has no _tkinter.
  msePython = pkgs.python3.withPackages (ps: [ ps.tkinter ]);
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
      youtube = {
        name = "YouTube";
        icon = "brave-origin";
        exec = "brave-origin https://www.youtube.com/";
        terminal = false;
        categories = [ "Network" ];
      };
      linkedin = {
        name = "link - LinkedIn";
        icon = "brave-origin";
        exec = "brave-origin https://www.linkedin.com/feed/";
        terminal = false;
        categories = [ "Network" ];
      };
      instagram = {
        name = "Instagram";
        icon = "brave-origin";
        exec = "brave-origin https://www.instagram.com/";
        terminal = false;
        categories = [ "Network" ];
      };
      x-twitter = {
        name = "X";
        icon = "brave-origin";
        exec = "brave-origin https://x.com/";
        terminal = false;
        categories = [ "Network" ];
      };
      youtube-music = {
        name = "YouTube Music";
        icon = "brave-origin";
        exec = "brave-origin https://music.youtube.com/";
        terminal = false;
        categories = [ "AudioVideo" "Network" ];
      };
      youtube-studio = {
        name = "YouTube Studio";
        icon = "brave-origin";
        exec = "brave-origin https://studio.youtube.com/";
        terminal = false;
        categories = [ "Network" ];
      };
      canva = {
        name = "can - Canva";
        icon = "brave-origin";
        exec = "brave-origin https://www.canva.com/";
        terminal = false;
        categories = [ "Graphics" "Network" ];
      };
      grok = {
        name = "Grok";
        icon = "brave-origin";
        exec = "brave-origin https://grok.com/";
        terminal = false;
        categories = [ "Network" ];
      };
      chatgpt = {
        name = "ChatGPT";
        icon = "brave-origin";
        exec = "brave-origin https://chatgpt.com/";
        terminal = false;
        categories = [ "Network" ];
      };
      scryfall = {
        name = "Scryfall";
        icon = "brave-origin";
        exec = "brave-origin https://scryfall.com/";
        terminal = false;
        categories = [ "Network" ];
      };
      siinergy-erp = {
        name = "Siinergy ERP";
        icon = "brave-origin";
        exec = "brave-origin http://erpcloud.siinergy.net/";
        terminal = false;
        categories = [ "Network" ];
      };
      siinergy-portail = {
        name = "Siinergy Portail";
        icon = "brave-origin";
        exec = "brave-origin https://monportail.siinergy.net/";
        terminal = false;
        categories = [ "Network" ];
      };
      outlook = {
        name = "Outlook";
        icon = "brave-origin";
        exec = "brave-origin https://outlook.live.com/mail/";
        terminal = false;
        categories = [ "Network" ];
      };
      discord = {
        name = "Discord";
        icon = "brave-origin";
        exec = "brave-origin https://discord.com/channels/@me";
        terminal = false;
        categories = [ "Network" ];
      };
      messenger = {
        name = "Messenger";
        icon = "brave-origin";
        exec = "brave-origin https://www.facebook.com/messages/e2ee/t/8160697540693740/";
        terminal = false;
        categories = [ "Network" ];
      };
      mtgtop8-legacy = {
        name = "MTGTop8 - Legacy";
        icon = "brave-origin";
        exec = ''brave-origin "https://mtgtop8.com/format?f=LE"'';
        terminal = false;
        categories = [ "Network" ];
      };
      facebook = {
        name = "Facebook";
        icon = "brave-origin";
        exec = "brave-origin https://facebook.com/";
        terminal = false;
        categories = [ "Network" ];
      };
      maps = {
        name = "Maps";
        icon = "brave-origin";
        exec = "brave-origin https://www.google.com/maps";
        terminal = false;
        categories = [ "Network" ];
      };
      github-essentia = {
        name = "Essentia";
        icon = "nvim";
        exec = "nvim /home/aron/projects/essentia";
        terminal = true;
        categories = [ "Development" ];
      };
      file-explorer-dev = {
        name = "File Explorer (dev)";
        comment = "Run FileExplorer feature-build checkout";
        icon = "file-explorer";
        exec = "${pkgs.coreutils}/bin/env WEBKIT_DISABLE_DMABUF_RENDERER=1 /home/aron/projects/FileExplorer/target/release/src-tauri";
        terminal = false;
        categories = [ "Utility" "FileManager" "Development" ];
      };
      brood-war = {
        name = "StarCraft: Brood War";
        comment = "Retail 1.16.1 client under wine";
        icon = "applications-games";
        # The Mono/Gecko overrides stop wine from opening an installer dialog
        # the game does not need; gamescope scales 640x480 up to the monitor.
        exec = ''env WINEPREFIX=/home/aron/Games/prefixes/starcraft WINEDLLOVERRIDES="mscoree,mshtml=" gamescope -w 640 -h 480 -W 1920 -H 1080 -f -- wine /home/aron/Games/Starcraft/StarCraft.exe'';
        terminal = false;
        categories = [ "Game" ];
      };
      openbw = {
        name = "OpenBW (BWAPI)";
        comment = "Run a BWAPI bot on the OpenBW engine";
        icon = "applications-games";
        # run.sh is quiet while the game runs and prints its diagnostics on
        # failure, so keep a terminal attached rather than losing them.
        exec = "/home/aron/projects/openbw-env/run.sh";
        terminal = true;
        categories = [ "Game" "Development" ];
      };
      ygo-mtg-mse-menu = {
        name = "YGO X MTG: Essentia - MSE Menu";
        comment = "Open Essentia projects in Magic Set Editor";
        exec = "${pkgs.coreutils}/bin/env MSE_LIBRARY_PATH=${pkgs.wxwidgets_3_2}/lib ${msePython}/bin/python3 /home/aron/projects/essentia/launcher/mse_project_menu.pyw";
        terminal = false;
        categories = [ "Graphics" "Development" ];
        startupNotify = true;
        settings = {
          Path = "/home/aron/projects/essentia";
        };
      };
      github-repos = {
        name = "github-repos";
        icon = "brave-origin";
        exec = "brave-origin \"https://github.com/AronGomu?tab=repositories\"";
        terminal = false;
        categories = [ "Network" ];
      };
      github-nix-aron = {
        name = "github-nix-aron";
        icon = "brave-origin";
        exec = "brave-origin https://github.com/AronGomu/nix-aron";
        terminal = false;
        categories = [ "Network" ];
      };
      impeccable = {
        name = "Impeccable";
        icon = "brave-origin";
        exec = "brave-origin https://github.com/pbakaus/impeccable";
        terminal = false;
        categories = [ "Network" ];
      };
      ascencio-duel-simulator = {
        name = "ASCENCIO - Duel Simulator";
        icon = "brave-origin";
        exec = "brave-origin http://localhost:4300/";
        terminal = false;
        categories = [ "Network" ];
      };
      ascencio-deckbuilder = {
        name = "ASCENCIO - Deckbuilder";
        icon = "brave-origin";
        exec = "brave-origin http://localhost:4301/";
        terminal = false;
        categories = [ "Network" ];
      };
      ascencio-vn = {
        name = "ASCENCIO - VN";
        icon = "brave-origin";
        exec = "brave-origin http://localhost:4302/";
        terminal = false;
        categories = [ "Network" ];
      };
      github-brain = {
        name = "github-brain";
        icon = "brave-origin";
        exec = "brave-origin https://github.com/AronGomu/brain";
        terminal = false;
        categories = [ "Network" ];
      };
      github-ygo-story = {
        name = "github-ygo-story";
        icon = "brave-origin";
        exec = "brave-origin https://github.com/AronGomu/ygo-story-duel-simulator";
        terminal = false;
        categories = [ "Network" ];
      };
      github-gones = {
        name = "github-gones";
        icon = "brave-origin";
        exec = "brave-origin https://github.com/AronGomu/gones";
        terminal = false;
        categories = [ "Network" ];
      };
      github-matt-pocock = {
        name = "github-matt-pocock";
        icon = "brave-origin";
        exec = "brave-origin https://github.com/mattpocock/skills";
        terminal = false;
        categories = [ "Network" ];
      };
      github-agentsystemlabs-core = {
        name = "github-agentsystemlabs-core";
        icon = "brave-origin";
        exec = "brave-origin https://github.com/AgentSystemLabs/core";
        terminal = false;
        categories = [ "Network" ];
      };
      github-essentia-page = {
        name = "github - Essentia";
        icon = "brave-origin";
        exec = "brave-origin https://github.com/AronGomu/Essentia";
        terminal = false;
        categories = [ "Network" ];
      };
      google-drive = {
        name = "Google Drive";
        icon = "brave-origin";
        exec = "brave-origin https://drive.google.com/drive/my-drive";
        terminal = false;
        categories = [ "Network" ];
      };
      claude-ai = {
        name = "Claude";
        icon = "brave-origin";
        exec = "brave-origin https://claude.ai/";
        terminal = false;
        categories = [ "Network" ];
      };
      gones-local = {
        name = "Gones - http://localhost:4200";
        icon = "brave-origin";
        exec = "brave-origin http://localhost:4200";
        terminal = false;
        categories = [ "Development" "Network" ];
      };
      essentia-local = {
        name = "Essentia - http://localhost:4201";
        icon = "brave-origin";
        exec = "brave-origin http://localhost:4201";
        terminal = false;
        categories = [ "Development" "Network" ];
      };
      ascensio-local = {
        name = "Ascensio - http://localhost:4202";
        icon = "brave-origin";
        exec = "brave-origin http://localhost:4202";
        terminal = false;
        categories = [ "Development" "Network" ];
      };
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
        "text/html" = [ "brave-origin.desktop" ];
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
        "x-scheme-handler/http" = [ "brave-origin.desktop" ];
        "x-scheme-handler/https" = [ "brave-origin.desktop" ];
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
