{ inputs, ... }:
{
  imports = [ inputs.noctalia.homeModules.default ];

  programs = {
    niri.settings.binds = {
      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+Print".action.screenshot-screen.show-pointer = false;
      "Mod+Shift+E".action.quit.skip-confirmation = true;
    };

    noctalia = {
      enable = true;
      systemd.enable = true;
    };
  };
}
