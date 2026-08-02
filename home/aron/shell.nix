{ lib, pkgs, ... }:
let
  shellAliases = {
    cat = "bat";
    gtbrain = "cd /home/aron/brain";
    gtnixconfig = "cd /home/aron/coding/nix-aron";
    gtygocube = "cd /home/aron/projects/YGO-x-MTG";
    gtygostory = "cd /home/aron/coding/ygo-story-duel-simulator";
    ll = "eza -lah --group-directories-first";
    rebuild = "sudo nixos-rebuild switch --flake ~/coding/nix-aron#desk-main";
    hm = "home-manager switch --flake ~/coding/nix-aron#desk-main";
    update-system = "nix flake update --flake ~/coding/nix-aron";
    v = "nvim";
  };

  # Shared by bash + zsh. Loads agent secrets for:
  # - GEMINI_API_KEY → pi web_search (pikit web-access)
  # - XAI_API_KEY / GROK_API_KEY → grok-cli + grok-imagine
  agentEnvInit = ''
    if [ -f "$HOME/.pi/agent/configs/.env" ]; then
      set -a
      # shellcheck disable=SC1090
      . "$HOME/.pi/agent/configs/.env"
      set +a
    fi
    # Keep xAI key names in sync for grok-cli (GROK_*) and official API (XAI_*).
    if [ -n "''${XAI_API_KEY:-}" ] && [ -z "''${GROK_API_KEY:-}" ]; then
      export GROK_API_KEY="$XAI_API_KEY"
    fi
    if [ -n "''${GROK_API_KEY:-}" ] && [ -z "''${XAI_API_KEY:-}" ]; then
      export XAI_API_KEY="$GROK_API_KEY"
    fi
  '';
in
{
  home.sessionVariables = {
    BROWSER = "brave";
    EDITOR = "nvim";
    TERMINAL = "ghostty";
    VISUAL = "nvim";
    GROK_BASE_URL = "https://api.x.ai/v1";
    GROK_MODEL = "grok-4-latest";
  };

  programs = {
    bash = {
      enable = true;
      enableCompletion = true;
      inherit shellAliases;
      initExtra = agentEnvInit;
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      inherit shellAliases;
      # vi-mode (from EDITOR=nvim): unbound ^[[1;5C/D → Esc → cmd mode → delete.
      # Bind ctrl/alt arrows for word jump in viins+vicmd+emacs.
      initContent = lib.mkMerge [
        (lib.mkBefore agentEnvInit)
        ''
          for keymap in emacs viins vicmd; do
            bindkey -M $keymap '^[[1;5C' forward-word
            bindkey -M $keymap '^[[1;5D' backward-word
            bindkey -M $keymap '^[f' forward-word
            bindkey -M $keymap '^[b' backward-word
            bindkey -M $keymap '^[[1;3C' forward-word
            bindkey -M $keymap '^[[1;3D' backward-word
          done
        ''
      ];
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
