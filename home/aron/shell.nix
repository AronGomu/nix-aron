{ pkgs, ... }:
{
  home.sessionVariables = {
    BROWSER = "brave";
    EDITOR = "nvim";
    TERMINAL = "ghostty";
    VISUAL = "nvim";
  };

  programs = {
    bash = {
      enable = true;
      enableCompletion = true;
      shellAliases = {
        cat = "bat";
        ll = "eza -lah --group-directories-first";
        rebuild = "sudo nixos-rebuild switch --flake ~/coding/nix-aron#desk-main";
        update-system = "nix flake update --flake ~/coding/nix-aron";
      };
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    git = {
      enable = true;
      settings = {
        user = {
          name = "AronGomu";
          email = "neverismine@gmail.com";
        };
        init.defaultBranch = "main";
        pull.rebase = false;
        push.autoSetupRemote = true;
      };
    };

    starship = {
      enable = true;
      enableBashIntegration = true;
    };

    tmux = {
      enable = true;
      baseIndex = 1;
      clock24 = true;
      escapeTime = 0;
      keyMode = "vi";
      mouse = true;
      terminal = "screen-256color";
      extraConfig = ''
        set -ga terminal-overrides ",xterm-ghostty:Tc"
        set -g focus-events on
        set -g history-limit 100000
      '';
    };
  };

  xdg.configFile."ghostty/config".text = ''
    font-family = JetBrainsMono Nerd Font
    font-size = 12
    background-opacity = 1.0
    window-decoration = true
    confirm-close-surface = false
    copy-on-select = clipboard
    command = ${pkgs.tmux}/bin/tmux new-session -A -s main
    keybind = alt+backspace=text:\x1b\x7f
  '';
}
