{ pkgs, ... }:
let
  startStrawberryMinimized = pkgs.writeShellScript "start-strawberry-minimized" ''
    ${pkgs.strawberry}/bin/strawberry --pause &

    for _ in $(${pkgs.coreutils}/bin/seq 1 50); do
      window="$(${pkgs.xdotool}/bin/xdotool search --onlyvisible --class '[Ss]trawberry' 2>/dev/null | ${pkgs.coreutils}/bin/head -n1 || true)"
      if [ -n "$window" ]; then
        ${pkgs.xdotool}/bin/xdotool windowminimize "$window"
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 0.2
    done
  '';
in
{
  xfconf = {
    enable = true;
    settings = {
      "xfce4-session" = {
        "general/SaveOnExit" = false;
      };

      "xfce4-keyboard-shortcuts" = {
        "commands/custom/<Super>Return" = "ghostty";
        "commands/custom/<Super>e" = "thunar";
        "commands/custom/<Super>b" = "brave";
        "commands/custom/Print" = "flameshot gui";
        "commands/custom/<Super>l" = "xfce4-screensaver-command --lock";
      };

      "xfce4-power-manager" = {
        "xfce4-power-manager/inactivity-on-ac" = 0;
        "xfce4-power-manager/lock-screen-suspend-hibernate" = true;
      };

      "xfce4-screensaver" = {
        "lock/enabled" = true;
        "saver/enabled" = true;
        "saver/idle-activation/enabled" = true;
        "saver/idle-activation/delay" = 10;
      };

      "xfce4-clipman" = {
        "general/save-on-quit" = false;
      };

      xsettings = {
        "Net/ThemeName" = "Greybird-dark";
        "Net/IconThemeName" = "Papirus-Dark";
        "Gtk/FontName" = "Noto Sans 10";
        "Gtk/MonospaceFontName" = "JetBrainsMono Nerd Font 10";
        "Gtk/CursorThemeName" = "Adwaita";
      };

      # Window manager chrome (titlebars) — must match GTK dark theme
      xfwm4 = {
        "general/theme" = "Greybird-dark";
        "general/button_layout" = "O|HMC";
      };

      thunar = {
        "last-view" = "ThunarDetailsView";
      };
    };
  };

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
    brightness = {
      day = "1.0";
      night = "0.7";
    };
    tray = true;
  };

  gtk = {
    enable = true;
    theme = {
      name = "Greybird-dark";
      package = pkgs.greybird;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
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
    mimeApps = {
      enable = true;
      defaultApplications = {
        "application/pdf" = [ "org.gnome.Evince.desktop" ];
        "audio/mpeg" = [ "org.strawberrymusicplayer.strawberry.desktop" ];
        "image/jpeg" = [ "org.xfce.ristretto.desktop" ];
        "image/png" = [ "org.xfce.ristretto.desktop" ];
        "inode/directory" = [ "thunar.desktop" ];
        "message/rfc822" = [ "thunderbird.desktop" ];
        "text/html" = [ "brave-browser.desktop" ];
        "video/mp4" = [ "mpv.desktop" ];
        "x-scheme-handler/http" = [ "brave-browser.desktop" ];
        "x-scheme-handler/https" = [ "brave-browser.desktop" ];
        "x-scheme-handler/mailto" = [ "thunderbird.desktop" ];
      };
    };

    configFile = {
      "autostart/brave.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Brave
        Exec=brave --restore-last-session
        OnlyShowIn=XFCE;
        X-GNOME-Autostart-enabled=true
      '';

      "autostart/ghostty.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Ghostty
        Exec=ghostty
        OnlyShowIn=XFCE;
        X-GNOME-Autostart-enabled=true
      '';

      "autostart/strawberry.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Strawberry
        Exec=${startStrawberryMinimized}
        OnlyShowIn=XFCE;
        X-GNOME-Autostart-enabled=true
      '';

      "autostart/clipman.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Clipman
        Exec=xfce4-clipman
        OnlyShowIn=XFCE;
        X-GNOME-Autostart-enabled=true
      '';
    };
  };
}
