{ pkgs, lib, ... }:

{
  # KeePassXC's ini also holds its KeeShare private key and other runtime
  # state; managing it wholesale via programs.keepassxc.settings would make
  # it a read-only Nix-store symlink and wipe that key on every switch. Patch
  # just the theme line in place instead.
  home.activation.keepassxcDarkTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    conf="$HOME/.config/keepassxc/keepassxc.ini"
    mkdir -p "$(dirname "$conf")"
    touch "$conf"
    if ${pkgs.gnugrep}/bin/grep -q '^\[GUI\]' "$conf"; then
      if ${pkgs.gnugrep}/bin/grep -q '^ApplicationTheme=' "$conf"; then
        ${pkgs.gnused}/bin/sed -i 's/^ApplicationTheme=.*/ApplicationTheme=dark/' "$conf"
      else
        ${pkgs.gnused}/bin/sed -i '/^\[GUI\]/a ApplicationTheme=dark' "$conf"
      fi
    else
      printf '\n[GUI]\nApplicationTheme=dark\n' >> "$conf"
    fi
  '';
}
