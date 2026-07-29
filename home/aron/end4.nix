{
  inputs,
  lib,
  osConfig ? null,
  pkgs,
  ...
}:
let
  enabled = osConfig != null && osConfig.desktop.end4.enable;
  system = pkgs.stdenv.hostPlatform.system;
  end4 = inputs.end4;
  qs = inputs.quickshell.packages.${system}.default;
  end4QuickshellConfig = pkgs.runCommand "end4-quickshell-config" { } ''
    cp -R --no-preserve=mode ${end4}/dots/.config/quickshell $out
    substituteInPlace $out/ii/services/Hyprsunset.qml \
      --replace-fail "property int defaultColorTemperature: 6000" "property int defaultColorTemperature: 4500"
  '';

  quickshell = pkgs.stdenvNoCC.mkDerivation {
    pname = "end4-quickshell";
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
      runHook postInstall
    '';
  };

  pythonEnv = pkgs.python312.withPackages (
    ps: with ps; [
      build
      click
      dbus-python
      google-auth
      kde-material-you-colors
      libsass
      loguru
      material-color-utilities
      materialyoucolor
      numpy
      opencv4
      pillow
      psutil
      pycairo
      pygobject3
      pywayland
      requests
      setproctitle
      setuptools-scm
      tqdm
    ]
  );
in
{
  config = lib.mkIf enabled {
    home.packages = with pkgs; [
      quickshell

      # end-4 shell integrations
      bc
      brightnessctl
      cliphist
      ddcutil
      easyeffects
      foot
      fuzzel
      geoclue2
      grim
      hypridle
      hyprlock
      hyprpicker
      hyprshot
      hyprsunset
      imagemagick
      kdePackages.bluedevil
      kdePackages.dolphin
      kdePackages.kconfig
      kdePackages.plasma-nm
      kdePackages.systemsettings
      libcava
      libnotify
      lxqt.pavucontrol-qt
      matugen
      playerctl
      libqalculate
      slurp
      songrec
      swappy
      tesseract
      translate-shell
      upower
      wf-recorder
      wl-clipboard
      wlogout
      wtype
      xdg-user-dirs
      ydotool

      # Fonts/themes expected by end-4.
      adw-gtk3
      bibata-cursors
      material-symbols
      nerd-fonts.jetbrains-mono
      rubik
      twemoji-color-font
    ];

    xdg.configFile = {
      "hypr/hyprland" = {
        source = "${end4}/dots/.config/hypr/hyprland";
        recursive = true;
      };
      "hypr/hyprland.lua".source = "${end4}/dots/.config/hypr/hyprland.lua";
      "hypr/hypridle.conf".source = "${end4}/dots/.config/hypr/hypridle.conf";
      "hypr/hyprlock.conf".source = "${end4}/dots/.config/hypr/hyprlock.conf";
      "hypr/hyprlock" = {
        source = "${end4}/dots/.config/hypr/hyprlock";
        recursive = true;
      };
      "hypr/custom/scripts" = {
        source = "${end4}/dots/.config/hypr/custom/scripts";
        recursive = true;
      };
      "hypr/custom/variables.lua".text = ''
        terminal = "ghostty"
        fileManager = "nautilus"
        browser = "brave"
      '';
      "hypr/custom/env.lua".text = ''
        hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", "${pythonEnv}")
      '';
      "hypr/custom/execs.lua".text = ''
        hl.on("hyprland.start", function ()
            hl.exec_cmd("ghostty")
            hl.exec_cmd("brave")
        end)
      '';
      "quickshell" = {
        source = end4QuickshellConfig;
        recursive = true;
      };
    };

    # Seed writable shell prefs once; end-4 GUI owns later changes.
    home.activation.end4InitialConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      config_dir="$HOME/.config/illogical-impulse"
      config_file="$config_dir/config.json"
      if [ ! -e "$config_file" ]; then
        mkdir -p "$config_dir"
        cat > "$config_file" <<'JSON'
      {
        "bar": {
          "screenList": ["HDMI-A-2"]
        },
        "light": {
          "night": {
            "automatic": true,
            "from": "19:00",
            "to": "06:30",
            "colorTemperature": 1000
          }
        }
      }
      JSON
      fi
    '';
  };
}
