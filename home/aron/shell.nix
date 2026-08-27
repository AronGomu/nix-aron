{ lib, pkgs, ... }:
let
  shellAliases = {
    cat = "bat";
    ll = "eza -lah --group-directories-first";
    v = "nvim";
    lz = "lazygit";

    # gt* = "go to". One per config dir and per project; keep in sync by hand
    # (nix cannot list $HOME at eval time without going impure).
    gtbrain = "cd /home/aron/brain";
    gtconfig = "cd /home/aron/config";
    gtbookmarks = "cd /home/aron/config/bookmarks";
    gtnixconfig = "cd /home/aron/config/nix-aron";
    gtprojects = "cd /home/aron/projects";
    gtascencio = "cd /home/aron/projects/ascencio";
    gtessentia = "cd /home/aron/projects/essentia";
    gtgones = "cd /home/aron/projects/gones";
    gtmillions = "cd /home/aron/projects/millions_must_die";

    # $(nixos-host) resolves the flake output from the running root disk, so a
    # rebuild can never carry the other disk's fileSystems. Never hardcode it:
    # there is no bare `desk-main`, only `desk-main-nvme` / `desk-main-samsung`.
    rebuild = "sudo nixos-rebuild switch --flake ~/config/nix-aron#$(nixos-host)";
    # No homeConfigurations output — HM is wired through the NixOS module, so
    # `home-manager switch` would apply a different config or none. Refuse loudly.
    hm = "echo 'no standalone HM output — HM applies via nixos-rebuild; run: rebuild' >&2";
    update-system = "nix flake update --flake ~/config/nix-aron";

    brave-personal = "brave --profile-directory=Default";
    brave-mtgones = "brave --profile-directory='Profile 1'";
  };

  # Loads agent secrets for:
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
    # The roslyn language server and csharpier resolve the SDK through this.
    DOTNET_ROOT = "${pkgs.dotnet-sdk_10}/share/dotnet";
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    # OpenBW reimplements the Brood War engine but ships no game data, so
    # BWAPILauncher (~/projects/openbw-env) reads StarCraft's MPQ archives from
    # the game directory instead of its own working directory.
    OPENBW_MPQ_PATH = "/home/aron/Games/Starcraft";
  };

  programs = {
    # Replaces zsh. ble.sh supplies the only zsh feature that was worth keeping:
    # inline autosuggestion, syntax highlighting, and a menu completion UI —
    # without leaving POSIX/bash syntax.
    bash = {
      enable = true;
      enableCompletion = true;
      inherit shellAliases;
      initExtra = lib.mkMerge [
        # After bash-completion (mkOrder 100), before everything that touches
        # PROMPT_COMMAND. --noattach defers the takeover until the very end.
        (lib.mkOrder 200 ''
          [[ $- == *i* ]] && . "${pkgs.blesh}/share/blesh/ble.sh" --noattach
        '')
        agentEnvInit
        # Last: after starship's init (mkOrder 1900), so ble.sh wraps the final
        # prompt rather than being overwritten by it.
        (lib.mkOrder 2000 ''
          [[ ''${BLE_VERSION-} ]] && ble-attach
        '')
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
    };

    yazi = {
      enable = true;
      enableBashIntegration = true;
      settings.opener.edit = [
        {
          run = ''nvim "$@"'';
          block = true;
          desc = "Neovim";
        }
      ];
      keymap.mgr.prepend_keymap = [
        {
          run = [ "escape" "quit" ];
          on = [ "<Esc>" ];
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
