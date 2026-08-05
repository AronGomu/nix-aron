{ config, ... }:
{
  home.file = {
    # Writable: herdr rewrites config.toml at runtime (onboarding flag, theme, etc.).
    ".config/herdr/config.toml" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/coding/nix-aron/dotfiles/herdr/config.toml";
      force = true;
    };

    ".config/herdr/sounds" = {
      source = ../../dotfiles/herdr/sounds;
      recursive = true;
      force = true;
    };
  };
}
