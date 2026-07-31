{ pkgs, ... }:
let
  shellAliases = {
    cat = "bat";
    gtbrain = "cd /home/aron/brain";
    gtygocube = "cd /home/aron/projects/YGO-x-MTG";
    ll = "eza -lah --group-directories-first";
    rebuild = "sudo nixos-rebuild switch --flake ~/coding/nix-aron#desk-main";
    hm = "home-manager switch --flake ~/coding/nix-aron#desk-main";
    update-system = "nix flake update --flake ~/coding/nix-aron";
    v = "nvim";
  };
in
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
      inherit shellAliases;
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      inherit shellAliases;
      plugins = [
        {
          name = "zsh-autocomplete";
          src = pkgs.zsh-autocomplete;
          file = "share/zsh-autocomplete/zsh-autocomplete.plugin.zsh";
        }
      ];
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
      enableZshIntegration = true;
    };

    yazi = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      settings.opener.edit = [
        {
          run = ''nvim "$@"'';
          block = true;
          desc = "Neovim";
        }
      ];
    };

  };

  xdg.configFile."ghostty/config".text = ''
    font-family = JetBrainsMono Nerd Font
    font-size = 12
    background-opacity = 1.0
    window-decoration = true
    confirm-close-surface = false
    copy-on-select = clipboard
    keybind = alt+backspace=text:\x1b\x7f
    # free ctrl+enter for apps (pi newline); fullscreen on F11
    keybind = ctrl+enter=unbind
    keybind = f11=toggle_fullscreen
  '';
}
