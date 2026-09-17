{ inputs, ... }:
{
  imports = [ inputs.noctalia.homeModules.default ];

  programs = {
    niri.settings.binds = {
      # Omarchy application bindings.
      "Mod+Return".action.spawn = [ "ghostty" ];
      "Mod+Shift+Return".action.spawn = [ "brave-origin" ];
      "Mod+Shift+F".action.spawn = [ "nautilus" ];
      "Mod+Shift+B".action.spawn = [ "brave-origin" ];
      "Mod+Shift+Alt+B".action.spawn = [
        "brave-origin"
        "--incognito"
      ];
      "Mod+Shift+W".action.spawn = [ "omawrite" ];
      "Mod+Ctrl+Q".action.spawn = [ "omacalc" ];

      # Omarchy menus and utilities.
      "Mod+Space".action.spawn-sh = "$OMARCHY_PATH/bin/omarchy-menu toggle";
      "Mod+Alt+Space".action.spawn-sh = "$OMARCHY_PATH/bin/omarchy-menu toggle apps";
      "Mod+Escape".action.spawn-sh = "$OMARCHY_PATH/bin/omarchy-menu toggle system";
      "Mod+K".action.spawn-sh = "$OMARCHY_PATH/bin/omarchy-menu-keybindings";
      "Mod+Ctrl+Space".action.spawn-sh = "$OMARCHY_PATH/bin/omarchy-menu toggle background";
      "Mod+Shift+Ctrl+Space".action.spawn-sh = "$OMARCHY_PATH/bin/omarchy-menu toggle theme";
      "Print".action.screenshot = { };
      "Mod+Print".action.spawn-sh = "pkill hyprpicker || hyprpicker -a";
      "Mod+Ctrl+Print".action.spawn-sh = "$OMARCHY_PATH/bin/omarchy-capture-text";

      # Omarchy window bindings, translated to Niri actions.
      "Mod+W".action.close-window = { };
      "Mod+Q".action.close-window = { };
      "Mod+T".action.toggle-window-floating = { };
      "Mod+F".action.fullscreen-window = { };
      "Mod+Ctrl+F".action.toggle-windowed-fullscreen = { };
      "Mod+Alt+F".action.maximize-column = { };
      "Mod+Left".action.focus-column-or-monitor-left = { };
      "Mod+Right".action.focus-column-or-monitor-right = { };
      "Mod+Up".action.focus-window-or-monitor-up = { };
      "Mod+Down".action.focus-window-or-monitor-down = { };
      "Mod+Shift+Left".action.move-column-left-or-to-monitor-left = { };
      "Mod+Shift+Right".action.move-column-right-or-to-monitor-right = { };
      "Mod+Shift+Up".action.move-window-up-or-to-workspace-up = { };
      "Mod+Shift+Down".action.move-window-down-or-to-workspace-down = { };
      "Alt+Tab".action.focus-column-right-or-first = { };
      "Alt+Shift+Tab".action.focus-column-left-or-last = { };

      # Omarchy workspace bindings.
      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;
      "Mod+7".action.focus-workspace = 7;
      "Mod+8".action.focus-workspace = 8;
      "Mod+9".action.focus-workspace = 9;
      "Mod+Shift+1".action.move-window-to-workspace = 1;
      "Mod+Shift+2".action.move-window-to-workspace = 2;
      "Mod+Shift+3".action.move-window-to-workspace = 3;
      "Mod+Shift+4".action.move-window-to-workspace = 4;
      "Mod+Shift+5".action.move-window-to-workspace = 5;
      "Mod+Shift+6".action.move-window-to-workspace = 6;
      "Mod+Shift+7".action.move-window-to-workspace = 7;
      "Mod+Shift+8".action.move-window-to-workspace = 8;
      "Mod+Shift+9".action.move-window-to-workspace = 9;
      "Mod+Tab".action.focus-workspace-down = { };
      "Mod+Shift+Tab".action.focus-workspace-up = { };
      "Mod+Ctrl+Tab".action.focus-workspace-previous = { };
      "Mod+WheelScrollDown".action.focus-workspace-down = { };
      "Mod+WheelScrollUp".action.focus-workspace-up = { };

      # Omarchy media bindings.
      "XF86AudioRaiseVolume" = {
        action.spawn-sh = "$OMARCHY_PATH/bin/omarchy-audio-output-volume raise";
        allow-when-locked = true;
      };
      "XF86AudioLowerVolume" = {
        action.spawn-sh = "$OMARCHY_PATH/bin/omarchy-audio-output-volume lower";
        allow-when-locked = true;
      };
      "XF86AudioMute" = {
        action.spawn-sh = "$OMARCHY_PATH/bin/omarchy-audio-output-volume mute-toggle";
        allow-when-locked = true;
      };
      "XF86AudioMicMute" = {
        action.spawn-sh = "$OMARCHY_PATH/bin/omarchy-audio-input-mute";
        allow-when-locked = true;
      };
      "XF86MonBrightnessUp" = {
        action.spawn-sh = "$OMARCHY_PATH/bin/omarchy-brightness-display +5%";
        allow-when-locked = true;
      };
      "XF86MonBrightnessDown" = {
        action.spawn-sh = "$OMARCHY_PATH/bin/omarchy-brightness-display 5%-";
        allow-when-locked = true;
      };
      "XF86AudioNext" = {
        action.spawn-sh = "$OMARCHY_PATH/bin/omarchy-shell media next";
        allow-when-locked = true;
      };
      "XF86AudioPlay" = {
        action.spawn-sh = "$OMARCHY_PATH/bin/omarchy-shell media playPause";
        allow-when-locked = true;
      };
      "XF86AudioPause" = {
        action.spawn-sh = "$OMARCHY_PATH/bin/omarchy-shell media playPause";
        allow-when-locked = true;
      };
      "XF86AudioPrev" = {
        action.spawn-sh = "$OMARCHY_PATH/bin/omarchy-shell media previous";
        allow-when-locked = true;
      };

      "Mod+Shift+E".action.quit.skip-confirmation = true;
    };

    noctalia = {
      enable = true;
      systemd.enable = true;
    };
  };
}
