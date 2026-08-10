{
  config,
  inputs,
  lib,
  pkgs,
  pkgsUnstable,
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

    # lastChangelogVersion is pinned to the pi version this generation ships:
    # pi only shows "What's New" for changelog entries newer than that value, so
    # rewriting settings.json from the repo without it would replay the changelog
    # after every rebuild.
    installMutablePiSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      settings_dir="${config.home.homeDirectory}/.pi/agent"
      settings_file="$settings_dir/settings.json"
      settings_tmp="$settings_dir/settings.json.tmp"
      mkdir -p "$settings_dir"

      if [ -e "$settings_file" ]; then
        ${pkgs.jq}/bin/jq -s --arg piVersion ${pkgsUnstable.pi-coding-agent.version} \
          '.[0] * (.[1] | with_entries(select(.key == "defaultProvider" or .key == "defaultModel" or .key == "defaultThinkingLevel"))) | .lastChangelogVersion = $piVersion' \
          ${../../dotfiles/pi/agent/settings.json} "$settings_file" > "$settings_tmp"
      else
        ${pkgs.jq}/bin/jq --arg piVersion ${pkgsUnstable.pi-coding-agent.version} \
          '.lastChangelogVersion = $piVersion' \
          ${../../dotfiles/pi/agent/settings.json} > "$settings_tmp"
      fi

      rm -f "$settings_file"
      mv "$settings_tmp" "$settings_file"
    '';

    removeDuplicatePiGraphifySkill = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      canonical="${config.home.homeDirectory}/.agents/skills/graphify/SKILL.md"
      duplicate="${config.home.homeDirectory}/.pi/agent/skills/graphify"
      if [ -f "$canonical" ] && [ -e "$duplicate" ]; then
        rm -rf "$duplicate"
      fi
    '';

    # Files the agents rewrite at runtime (Claude /config /model /effort and
    # the `#` memory shortcut, Codex project trust). home.file cannot host
    # them: even mkOutOfStoreSymlink goes through
    # /nix/store/...-home-manager-files/, and the agents write a temp file
    # next to the *first* symlink target -> EROFS. Link straight to the repo
    # file so writes land in a writable directory.
    linkMutableAgentFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      link_mutable() {
        target="${config.home.homeDirectory}/config/nix-aron/dotfiles/$1"
        dest="${config.home.homeDirectory}/$2"
        mkdir -p "$(dirname "$dest")"
        rm -f "$dest"
        ln -s "$target" "$dest"
      }

      link_mutable claude/settings.json .claude/settings.json
      link_mutable claude/CLAUDE.md .claude/CLAUDE.md
      link_mutable codex/config.toml .codex/config.toml
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

    # Harness-neutral subagent roles. Skills reference them by absolute path
    # (~/.agents/roles/*.md), so any harness that can spawn a child with a
    # prompt can use them — no per-harness registry required.
    ".agents/roles" = {
      source = ../../dotfiles/agents/roles;
      recursive = true;
    };

    ".pi/skills".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.agents/skills";
    ".pi/agent/APPEND_SYSTEM.md".source = ../../dotfiles/pi/agent/APPEND_SYSTEM.md;
    ".pi/agent/keybindings.json".source = ../../dotfiles/pi/agent/keybindings.json;
    ".pi/agent/claude-bridge.json".source = ../../dotfiles/pi/agent/claude-bridge.json;
    ".pi/agent/configs" = {
      source = ../../dotfiles/pi/agent/configs;
      recursive = true;
    };
    ".pi/agent/prompts" = {
      source = ../../dotfiles/pi/agent/prompts;
      recursive = true;
    };
    ".pi/agent/extensions" = {
      source = ../../dotfiles/pi/agent/extensions;
      recursive = true;
    };

    # config.toml is NOT managed here: see linkMutableAgentFiles above.
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

    # Claude Code reads ~/.claude/skills; share same hub as pi/codex.
    ".claude/skills".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.agents/skills";

    # settings.json and CLAUDE.md (global memory: caveman ultra by default) are
    # NOT managed here: see linkMutableAgentFiles above.
    # Slash commands, e.g. /caveman on|off to toggle caveman mode.
    ".claude/commands" = {
      source = ../../dotfiles/claude/commands;
      recursive = true;
    };

    # Claude-native subagent registry. Each file is a one-line adapter that
    # reads the harness-neutral role in ~/.agents/roles — no duplicated text.
    ".claude/agents" = {
      source = ../../dotfiles/claude/agents;
      recursive = true;
    };
  };
}
