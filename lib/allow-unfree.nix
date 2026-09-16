{ lib }:
pkg:
builtins.elem (lib.getName pkg) [
  "1password"
  "1password-gui"
  "brave"
  "claude-code"
  "davinci-resolve"
  "discord"
  "google-chrome"
  "nvidia-settings"
  "nvidia-x11"
  "obsidian"
  "steam"
  "steam-original"
  "steam-run"
  "steam-unwrapped"
  "unrar"
]
