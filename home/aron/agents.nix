{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  nvimConfig = pkgs.runCommand "nvim-config" { } ''
    cp -R ${inputs.nvim-config} $out
    chmod -R u+w $out
    cp ${../../dotfiles/nvim/treesitter.lua} $out/lua/plugins/treesitter.lua
    cp ${../../dotfiles/nvim/ui.lua} $out/lua/plugins/ui.lua
  '';
in
{
  home.activation = {
    migrateTreesitterMain = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      treesitter_dir="${config.home.homeDirectory}/.local/share/nvim/lazy/nvim-treesitter"
      if [ -d "$treesitter_dir/.git" ] \
        && [ "$(${pkgs.git}/bin/git -C "$treesitter_dir" branch --show-current)" != main ]; then
        rm -rf "$treesitter_dir"
      fi
    '';

    installMutablePiSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      settings_dir="${config.home.homeDirectory}/.pi/agent"
      settings_file="$settings_dir/settings.json"
      settings_tmp="$settings_dir/settings.json.tmp"
      mkdir -p "$settings_dir"

      if [ -e "$settings_file" ]; then
        ${pkgs.jq}/bin/jq -s \
          '.[0] * (.[1] | with_entries(select(.key == "defaultProvider" or .key == "defaultModel" or .key == "defaultThinkingLevel")))' \
          ${../../dotfiles/pi/agent/settings.json} "$settings_file" > "$settings_tmp"
      else
        cp ${../../dotfiles/pi/agent/settings.json} "$settings_tmp"
      fi

      rm -f "$settings_file"
      mv "$settings_tmp" "$settings_file"
    '';
  };

  home.file = {
    ".config/nvim".source = nvimConfig;
    "NIX-CHEATSHEET.md" = {
      source = ../../NIX-CHEATSHEET.md;
      force = true;
    };

    ".agents/skills" = {
      source = ../../dotfiles/agents/skills;
      recursive = true;
    };

    ".pi/skills".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.agents/skills";
    ".pi/agent/APPEND_SYSTEM.md".source = ../../dotfiles/pi/agent/APPEND_SYSTEM.md;
    ".pi/agent/keybindings.json".source = ../../dotfiles/pi/agent/keybindings.json;
    ".pi/agent/configs" = {
      source = ../../dotfiles/pi/agent/configs;
      recursive = true;
    };
    ".pi/agent/extensions" = {
      source = ../../dotfiles/pi/agent/extensions;
      recursive = true;
    };

    # Writable: Codex TUI writes project trust into config.toml at runtime.
    ".codex/config.toml".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/coding/nix-aron/dotfiles/codex/config.toml";
    ".codex/caveman.config.toml".source = ../../dotfiles/codex/caveman.config.toml;
    ".codex/prompts" = {
      source = ../../dotfiles/codex/prompts;
      recursive = true;
    };
    ".codex/rules" = {
      source = ../../dotfiles/codex/rules;
      recursive = true;
    };
    ".codex/skills".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.agents/skills";
  };
}
