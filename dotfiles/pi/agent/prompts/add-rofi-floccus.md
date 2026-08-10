---
description: Add URL(s) to Rofi launchers, Floccus bookmarks, and Nix managed Brave folder via nix-aron
argument-hint: "<url> [url…]"
---
Read and follow the skill at `/home/aron/config/nix-aron/dotfiles/agents/skills/nix-aron/SKILL.md` (or `~/.agents/skills/nix-aron/SKILL.md` after rebuild).

User prompt for that skill:

add to rofi and floccus $@

Also pin each URL in the Nix managed Brave bookmarks folder (brave-policies) unless the user said otherwise. Defaults when unspecified: Rofi desktop entry + Floccus `Synced` folder + managed Brave `Daily` folder. Derive a short human title from the site when not given.
