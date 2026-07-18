{ lib }:
pkg:
builtins.elem (lib.getName pkg) [
  "brave"
  "davinci-resolve"
  "discord"
  "nvidia-settings"
  "nvidia-x11"
  "steam"
  "steam-original"
  "steam-run"
  "steam-unwrapped"
  "unrar"
]
