{ inputs, ... }:
{
  home.file = {
    ".config/nvim".source = inputs.nvim-config;

    ".agents/skills" = {
      source = ../../dotfiles/agents/skills;
      recursive = true;
    };

    ".pi/skills" = {
      source = ../../dotfiles/pi/skills;
      recursive = true;
    };
    ".pi/agent/APPEND_SYSTEM.md".source = ../../dotfiles/pi/agent/APPEND_SYSTEM.md;
    ".pi/agent/settings.json".source = ../../dotfiles/pi/agent/settings.json;
    ".pi/agent/keybindings.json".source = ../../dotfiles/pi/agent/keybindings.json;
    ".pi/agent/configs" = {
      source = ../../dotfiles/pi/agent/configs;
      recursive = true;
    };
    ".pi/agent/extensions" = {
      source = ../../dotfiles/pi/agent/extensions;
      recursive = true;
    };

    ".codex/config.toml".source = ../../dotfiles/codex/config.toml;
    ".codex/caveman.config.toml".source = ../../dotfiles/codex/caveman.config.toml;
    ".codex/prompts" = {
      source = ../../dotfiles/codex/prompts;
      recursive = true;
    };
    ".codex/rules" = {
      source = ../../dotfiles/codex/rules;
      recursive = true;
    };
    ".codex/skills" = {
      source = ../../dotfiles/codex/skills;
      recursive = true;
    };
  };
}
