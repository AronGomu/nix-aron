{
  inputs,
  lib,
  osConfig ? null,
  pkgs,
  pkgsUnstable,
  ...
}:
let
  enabled = osConfig != null && osConfig.desktop.omarchy.enable;
  omarchy = osConfig.desktop.omarchy.package;
  system = pkgs.stdenv.hostPlatform.system;
  qs = inputs.quickshell.packages.${system}.default;

  # Omarchy's own apps, built from their MIT sources (the Arch packages are
  # binary-only). Hermes Desktop is deliberately absent: closed binary from
  # Omarchy's pacman repo, no public source.
  omawrite = pkgs.callPackage ../../pkgs/omawrite.nix { };
  omacalc = pkgs.callPackage ../../pkgs/omacalc.nix { };
  # Unstable: cliamp's go.mod requires a Go newer than 26.05 carries.
  cliamp = pkgsUnstable.callPackage ../../pkgs/cliamp.nix { };

  # Same wrapping as end4.nix, but Omarchy's scripts invoke both `qs`
  # (omarchy-shell IPC) and `quickshell` (omarchy-launch-shell), so expose
  # both names.
  quickshell = pkgs.stdenvNoCC.mkDerivation {
    pname = "omarchy-quickshell";
    version = "unstable";
    dontUnpack = true;
    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.qt6.wrapQtAppsHook
    ];
    buildInputs = with pkgs; [
      qs
      gsettings-desktop-schemas
      kdePackages.kirigami
      kdePackages.kdialog
      kdePackages.qtlocation
      kdePackages.qtpositioning
      kdePackages.qtwayland
      kdePackages.syntax-highlighting
      qt6.qt5compat
      qt6.qtbase
      qt6.qtdeclarative
      qt6.qtimageformats
      qt6.qtmultimedia
      qt6.qtpositioning
      qt6.qtquicktimeline
      qt6.qtsensors
      qt6.qtsvg
      qt6.qttools
      qt6.qttranslations
      qt6.qtvirtualkeyboard
      qt6.qtwayland
    ];
    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      makeWrapper ${qs}/bin/qs $out/bin/qs \
        --prefix XDG_DATA_DIRS : ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}
      ln -s $out/bin/qs $out/bin/quickshell
      runHook postInstall
    '';
  };
in
{
  config = lib.mkIf enabled {
    home.packages = with pkgs; [
      quickshell
      # Runtime deps of the omarchy-* scripts and shell widgets. envs.lua puts
      # $OMARCHY_PATH/bin on PATH; these must resolve from the session profile.
      brightnessctl
      ddcutil
      fzf
      gpu-screen-recorder
      grim
      gum
      hyprpicker
      hyprsunset
      imagemagick
      inotify-tools # inotifywait: omarchy-shell plugins dir watcher
      jq
      libnotify
      libxkbcommon # xkbcli: keyboard-layout widget + keybindings menu
      playerctl
      pulseaudio # pactl only; audio itself stays pipewire-pulse
      slurp
      socat # omarchy-hyprland-monitor-watch (autostarted)
      tesseract
      udiskie
      wl-clipboard
      wtype # clipboard paste / emoji insert
      xdg-terminal-exec # SUPER+RETURN via omarchy-launch-terminal

      # Apps behind Omarchy default binds.
      nautilus # SUPER+SHIFT+F file manager
      _1password-gui # SUPER+SHIFT+SLASH
      omawrite # SUPER+SHIFT+W
      omacalc # SUPER+CTRL+Q
      cliamp # SUPER+SHIFT+ALT+M music TUI
    ];

    # Omarchy's own user-config seeds, linked read-only: Hyprland only reads
    # these, and personal overrides belong in this repo anyway.
    xdg.configFile = {
      "hypr/hyprland.lua".source = "${omarchy}/config/hypr/hyprland.lua";
      "hypr/monitors.lua".source = "${omarchy}/config/hypr/monitors.lua";
      "hypr/input.lua".source = "${omarchy}/config/hypr/input.lua";
      "hypr/bindings.lua".source = "${omarchy}/config/hypr/bindings.lua";
      "hypr/looknfeel.lua".source = "${omarchy}/config/hypr/looknfeel.lua";
      "hypr/autostart.lua".source = "${omarchy}/config/hypr/autostart.lua";
      "hypr/hyprsunset.conf".source = "${omarchy}/config/hypr/hyprsunset.conf";
      "hypr/xdph.conf".source = "${omarchy}/config/hypr/xdph.conf";
    };

    # shell.json is rewritten in place when the bar is edited from the UI, so it
    # has to be a writable seed, not a store symlink. The SystemUpdate widget is
    # dropped from the layout: it shells out to pacman. Redirections live inside
    # `run bash -c` because a bare `run … > file` writes the file even in an HM
    # dry run, and the existence guard would then skip the real seed forever.
    home.activation.omarchySeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -e "$HOME/.config/omarchy/shell.json" ]; then
        run mkdir -p "$HOME/.config/omarchy"
        run bash -c '${pkgs.jq}/bin/jq \
          "del(.bar.layout.center[] | select(.id == \"omarchy.system-update\"))" \
          ${omarchy}/config/omarchy/shell.json > "$HOME/.config/omarchy/shell.json"'
      fi
      if [ ! -s "$HOME/.local/state/omarchy/current/theme.name" ]; then
        run env OMARCHY_PATH=${omarchy} OMARCHY_THEME_HEADLESS=1 \
          PATH="${omarchy}/bin:${
            lib.makeBinPath [
              pkgs.jq
              pkgs.gum
              pkgs.gawk
              pkgs.util-linux
            ]
          }:$PATH" \
          ${omarchy}/bin/omarchy-theme-set "Tokyo Night" \
          || echo "omarchy: theme seed failed; run: omarchy-theme-set 'Tokyo Night'"
      fi
    '';
  };
}
