{ pkgs, ... }:
let
  wifiStatus = pkgs.writeShellScript "i3blocks-wifi" ''
    if [ "''${BLOCK_BUTTON:-}" = 1 ]; then
      ${pkgs.networkmanager_dmenu}/bin/networkmanager_dmenu >/dev/null 2>&1 &
    fi

    device="$(${pkgs.networkmanager}/bin/nmcli -t -f DEVICE,TYPE device status | ${pkgs.gawk}/bin/awk -F: '$2 == "wifi" { print $1; exit }')"
    if [ -z "$device" ]; then
      printf 'WiFi: unavailable\n'
      exit
    fi

    connection="$(${pkgs.networkmanager}/bin/nmcli -g GENERAL.CONNECTION device show "$device")"
    if [ -z "$connection" ] || [ "$connection" = "--" ]; then
      printf 'WiFi: disconnected\n'
    else
      printf 'WiFi: %s\n' "$connection"
    fi
  '';

  volumeStatus = pkgs.writeShellScript "i3blocks-volume" ''
    case "''${BLOCK_BUTTON:-}" in
      1) ${pkgs.pavucontrol}/bin/pavucontrol >/dev/null 2>&1 & ;;
      3) ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
      4) ${pkgs.wireplumber}/bin/wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
      5) ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
    esac

    status="$(${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SINK@)"
    if printf '%s' "$status" | ${pkgs.gnugrep}/bin/grep -q MUTED; then
      printf 'Volume: muted\n'
    else
      printf '%s\n' "$status" | ${pkgs.gawk}/bin/awk '{ printf "Volume: %.0f%%\n", $2 * 100 }'
    fi
  '';

  focusedAppStatus = pkgs.writeShellScript "i3blocks-focused-app" ''
    app="$(${pkgs.i3}/bin/i3-msg -t get_tree | ${pkgs.jq}/bin/jq -r \
      '.. | objects | select(.type? == "con" and .focused? == true) | .name // .window_properties.class // .app_id // empty' \
      | ${pkgs.coreutils}/bin/head -n1)"
    printf '%s\n' "''${app:-Desktop}"
  '';

  openTerminal = pkgs.writeShellScript "i3-open-terminal" ''
    ${pkgs.i3}/bin/i3-msg "workspace number 1" >/dev/null
    ${pkgs.i3}/bin/i3-msg '[class="^com\.mitchellh\.ghostty$"] focus' >/dev/null 2>&1 || exec ghostty
  '';
in
{
  home.file = {
    ".config/i3/config".text = ''
      set $mod Mod4
      font pango:JetBrainsMono Nerd Font 10
      floating_modifier $mod

      # Applications
      bindsym $mod+Return exec --no-startup-id ${openTerminal}
      bindsym $mod+d exec ${pkgs.rofi}/bin/rofi -show drun
      bindsym $mod+e exec nautilus
      bindsym $mod+b exec brave
      bindsym Print exec flameshot gui
      bindsym $mod+l exec ${pkgs.i3lock}/bin/i3lock -c 1d2021

      # Window control
      bindsym $mod+Shift+q kill
      bindsym $mod+Left focus left
      bindsym $mod+Down focus down
      bindsym $mod+Up focus up
      bindsym $mod+Right focus right
      bindsym $mod+Shift+Left move left
      bindsym $mod+Shift+Down move down
      bindsym $mod+Shift+Up move up
      bindsym $mod+Shift+Right move right
      bindsym $mod+h split h
      bindsym $mod+v split v
      bindsym $mod+s layout stacking
      bindsym $mod+w layout tabbed
      bindsym $mod+t layout toggle split
      bindsym $mod+f fullscreen toggle
      bindsym $mod+Shift+space floating toggle
      bindsym $mod+space focus mode_toggle
      bindsym $mod+a focus parent

      # Workspaces
      set $ws1 "1"
      set $ws2 "2"
      set $ws3 "3"
      set $ws4 "4"
      set $ws5 "5"
      set $ws6 "6"
      set $ws7 "7"
      set $ws8 "8"
      set $ws9 "9"
      set $ws10 "10"
      assign [class="^com\.mitchellh\.ghostty$"] $ws1
      assign [class="^Brave-browser$"] $ws2
      bindsym $mod+1 workspace number $ws1
      bindsym $mod+2 workspace number $ws2
      bindsym $mod+3 workspace number $ws3
      bindsym $mod+4 workspace number $ws4
      bindsym $mod+5 workspace number $ws5
      bindsym $mod+6 workspace number $ws6
      bindsym $mod+7 workspace number $ws7
      bindsym $mod+8 workspace number $ws8
      bindsym $mod+9 workspace number $ws9
      bindsym $mod+0 workspace number $ws10
      bindsym Mod1+Tab workspace next
      bindsym Mod1+Shift+Tab workspace prev
      bindsym $mod+Shift+1 move container to workspace number $ws1
      bindsym $mod+Shift+2 move container to workspace number $ws2
      bindsym $mod+Shift+3 move container to workspace number $ws3
      bindsym $mod+Shift+4 move container to workspace number $ws4
      bindsym $mod+Shift+5 move container to workspace number $ws5
      bindsym $mod+Shift+6 move container to workspace number $ws6
      bindsym $mod+Shift+7 move container to workspace number $ws7
      bindsym $mod+Shift+8 move container to workspace number $ws8
      bindsym $mod+Shift+9 move container to workspace number $ws9
      bindsym $mod+Shift+0 move container to workspace number $ws10

      # Audio keys
      bindsym XF86AudioRaiseVolume exec --no-startup-id ${pkgs.wireplumber}/bin/wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
      bindsym XF86AudioLowerVolume exec --no-startup-id ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
      bindsym XF86AudioMute exec --no-startup-id ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      bindsym XF86AudioMicMute exec --no-startup-id ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

      # Session
      bindsym $mod+Shift+c reload
      bindsym $mod+Shift+r restart
      bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'Exit i3?' -B 'Yes' 'i3-msg exit'"

      mode "resize" {
        bindsym h resize shrink width 10 px or 10 ppt
        bindsym j resize grow height 10 px or 10 ppt
        bindsym k resize shrink height 10 px or 10 ppt
        bindsym l resize grow width 10 px or 10 ppt
        bindsym Left resize shrink width 10 px or 10 ppt
        bindsym Down resize grow height 10 px or 10 ppt
        bindsym Up resize shrink height 10 px or 10 ppt
        bindsym Right resize grow width 10 px or 10 ppt
        bindsym Return mode "default"
        bindsym Escape mode "default"
      }
      bindsym $mod+r mode "resize"

      # Startup applications
      exec --no-startup-id ghostty
      exec --no-startup-id brave

      # Standalone desktop services
      exec --no-startup-id ${pkgs.dunst}/bin/dunst
      exec --no-startup-id ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
      exec --no-startup-id ${pkgs.copyq}/bin/copyq

      for_window [class="Pavucontrol"] floating enable
      for_window [class="Brave-browser"] border pixel 1

      bar {
        position top
        status_command ${pkgs.i3blocks}/bin/i3blocks -c /home/aron/.config/i3blocks/config
        tray_output primary
        font pango:JetBrainsMono Nerd Font 10
      }
    '';

    ".config/i3blocks/config".text = ''
      separator=true
      separator_block_width=15

      [application]
      command=${focusedAppStatus}
      interval=1

      [wifi]
      command=${wifiStatus}
      interval=5

      [volume]
      command=${volumeStatus}
      interval=2

      [time]
      command=${pkgs.coreutils}/bin/date '+%a %Y-%m-%d %H:%M:%S'
      interval=1
    '';

    ".config/networkmanager-dmenu/config.ini".text = ''
      [dmenu]
      dmenu_command = ${pkgs.rofi}/bin/rofi -dmenu -i
      compact = True
    '';
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
}
