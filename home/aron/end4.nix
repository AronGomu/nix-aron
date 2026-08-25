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
  # The MSE menu launcher is a tkinter GUI; the bare system python3 has no _tkinter.
  msePython = pkgs.python3.withPackages (ps: [ ps.tkinter ]);
  qs = inputs.quickshell.packages.${system}.default;
  wallpaper = ../../assets/wallpapers/black-hole-interstellar.png;
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

  smartRofi = pkgs.writeTextFile {
    name = "rofi-smart-apps";
    destination = "/bin/rofi-smart-apps";
    executable = true;
    text = ''
      #!${pkgs.python3}/bin/python3
      import base64
      import configparser
      import json
      import os
      import re
      import subprocess
      import sys
      from pathlib import Path

      hyprctl = "${pkgs.hyprland}/bin/hyprctl"
      gio = "${pkgs.glib}/bin/gio"

      if len(sys.argv) > 1:
          info = os.environ.get("ROFI_INFO", "")
          if not info:
              raise SystemExit(0)
          action = json.loads(base64.urlsafe_b64decode(info).decode())
          if action[0] == "focus":
              subprocess.Popen([hyprctl, "dispatch", "focuswindow", "address:" + action[1]])
          else:
              subprocess.Popen([gio, "launch", action[1]])
          raise SystemExit(0)

      def normalized(value):
          return re.sub(r"[^a-z0-9]", "", value.lower())

      clients = json.loads(subprocess.check_output([hyprctl, "clients", "-j"]))
      windows = []
      for client in clients:
          keys = {
              normalized(client.get("class", "")),
              normalized(client.get("initialClass", "")),
          }
          windows.append((keys - {""}, client.get("address", "")))

      data_dirs = [Path.home() / ".local/share"]
      data_dirs += [Path(p) for p in os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":")]
      seen = set()
      apps = []
      for data_dir in data_dirs:
          app_dir = data_dir / "applications"
          if not app_dir.is_dir():
              continue
          for desktop_file in app_dir.rglob("*.desktop"):
              desktop_id = str(desktop_file.relative_to(app_dir)).replace("/", "-")
              if desktop_id in seen:
                  continue
              seen.add(desktop_id)
              parser = configparser.ConfigParser(interpolation=None, strict=False)
              try:
                  parser.read(desktop_file, encoding="utf-8")
                  entry = parser["Desktop Entry"]
              except (KeyError, configparser.Error, UnicodeError):
                  continue
              if entry.get("Type") != "Application" or entry.getboolean("Hidden", fallback=False) or entry.getboolean("NoDisplay", fallback=False):
                  continue
              name = entry.get("Name", desktop_id.removesuffix(".desktop"))
              icon = entry.get("Icon", "application-x-executable")
              startup_class = entry.get("StartupWMClass", "")
              executable = entry.get("Exec", "").split(maxsplit=1)[0].rsplit("/", 1)[-1]
              match_keys = {
                  normalized(startup_class),
                  normalized(desktop_id.removesuffix(".desktop")),
                  normalized(executable),
              } - {""}
              address = next((address for keys, address in windows if keys & match_keys), "")
              action = ["focus", address] if address else ["launch", str(desktop_file)]
              info = base64.urlsafe_b64encode(json.dumps(action).encode()).decode()
              apps.append((name.casefold(), name, icon, info))

      for _, name, icon, info in sorted(apps):
          print(f"{name}\0icon\x1f{icon}\x1finfo\x1f{info}")
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
      kdePackages.breeze
      kdePackages.breeze-icons
      kdePackages.dolphin
      kdePackages.ffmpegthumbs # Dolphin video thumbs
      kdePackages.kde-cli-tools # kioclient/kde-open for Dolphin open-with
      kdePackages.kdegraphics-thumbnailers # PDF/image thumbs
      kdePackages.kimageformats # QImageReader plugins (webp, avif...) for Dolphin previews
      kdePackages.kconfig
      kdePackages.kio-extras # previews, network, thumbnails
      kdePackages.kservice # kbuildsycoca6: without it KIO can't (re)build its app cache
      kdePackages.plasma-integration
      kdePackages.plasma-nm
      kdePackages.qqc2-breeze-style
      kdePackages.systemsettings
      libcava
      libnotify
      lxqt.pavucontrol-qt
      matugen
      nautilus-python
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
      "hypr/hypridle.conf".text = ''
        $lock_cmd = hyprctl dispatch 'hl.dsp.global("quickshell:lock")' & pidof qs quickshell hyprlock || hyprlock

        general {
            lock_cmd = $lock_cmd
            before_sleep_cmd = loginctl lock-session
            after_sleep_cmd = hyprctl dispatch 'hl.dsp.global("quickshell:lockFocus")'
            inhibit_sleep = 3
        }

        listener {
            timeout = 600 # 10mins
            on-timeout = loginctl lock-session
        }
      '';
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
        fileManager = "dolphin"
        browser = "brave"
      '';
      "hypr/custom/env.lua".text = ''
        hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", "${pythonEnv}")
      '';
      "hypr/custom/general.lua".text = ''
        -- Fixed monitor layout: Philips (main) left, Samsung right.
        hl.monitor({
            output = "HDMI-A-2",
            mode = "1920x1080@60",
            position = "0x0",
            scale = 1
        })
        hl.monitor({
            output = "DP-5",
            mode = "1920x1080@60",
            position = "1920x0",
            scale = 1
        })

        hl.config({
            general = {
                gaps_in = 0,
                gaps_out = 2,
                border_size = 1,
                col = {
                    active_border = "rgba(00D9FFFF)"
                }
            },
            decoration = {
                rounding = 0
            },
            input = {
                follow_mouse = 1,
                sensitivity = -0.6
            },
            cursor = {
                no_hardware_cursors = false
            }
        })
      '';
      "hypr/custom/execs.lua".text = ''
        hl.on("hyprland.start", function ()
            hl.exec_cmd("ghostty -e herdr", { workspace = "1 silent" })
            hl.exec_cmd("brave --new-window", { workspace = "2 silent" })
            hl.exec_cmd("openwhispr")
        end)
      '';
      "hypr/custom/keybinds.lua".text = ''
        hl.unbind("SUPER + A")
        hl.unbind("SUPER + ALT + A")
        hl.unbind("SUPER + B")
        hl.unbind("SUPER + O")
        hl.unbind("SUPER + P")
        hl.unbind("SUPER + SHIFT + ALT + mouse:273")

        hl.bind("SUPER + O", hl.dsp.exec_cmd("rofi -matching fuzzy -sorting-method fzf -drun-match-fields name -show drun"), { description = "Rofi: Launch new app window" })
        hl.bind("SUPER + P", hl.dsp.exec_cmd("rofi -matching fuzzy -sorting-method fzf -show smart -modi 'smart:${smartRofi}/bin/rofi-smart-apps'"), { description = "Rofi: Focus existing app or launch" })
        hl.bind("CTRL + Space", hl.dsp.exec_cmd("dbus-send --session --type=method_call --dest=com.openwhispr.App /com/openwhispr/App com.openwhispr.App.Toggle"), { description = "OpenWhispr: Toggle dictation" })
      '';
      "quickshell" = {
        source = end4QuickshellConfig;
        recursive = true;
      };
    };

    xdg.desktopEntries = {
      youtube = {
        name = "YouTube";
        icon = "brave-browser";
        exec = "brave https://www.youtube.com/";
        terminal = false;
        categories = [ "Network" ];
      };
      linkedin = {
        name = "link - LinkedIn";
        icon = "brave-browser";
        exec = "brave https://www.linkedin.com/feed/";
        terminal = false;
        categories = [ "Network" ];
      };
      instagram = {
        name = "Instagram";
        icon = "brave-browser";
        exec = "brave https://www.instagram.com/";
        terminal = false;
        categories = [ "Network" ];
      };
      x-twitter = {
        name = "X";
        icon = "brave-browser";
        exec = "brave https://x.com/";
        terminal = false;
        categories = [ "Network" ];
      };
      youtube-music = {
        name = "YouTube Music";
        icon = "brave-browser";
        exec = "brave https://music.youtube.com/";
        terminal = false;
        categories = [ "AudioVideo" "Network" ];
      };
      youtube-studio = {
        name = "YouTube Studio";
        icon = "brave-browser";
        exec = "brave https://studio.youtube.com/";
        terminal = false;
        categories = [ "Network" ];
      };
      canva = {
        name = "can - Canva";
        icon = "brave-browser";
        exec = "brave https://www.canva.com/";
        terminal = false;
        categories = [ "Graphics" "Network" ];
      };
      grok = {
        name = "Grok";
        icon = "brave-browser";
        exec = "brave https://grok.com/";
        terminal = false;
        categories = [ "Network" ];
      };
      chatgpt = {
        name = "ChatGPT";
        icon = "brave-browser";
        exec = "brave https://chatgpt.com/";
        terminal = false;
        categories = [ "Network" ];
      };
      scryfall = {
        name = "Scryfall";
        icon = "brave-browser";
        exec = "brave https://scryfall.com/";
        terminal = false;
        categories = [ "Network" ];
      };
      siinergy-erp = {
        name = "Siinergy ERP";
        icon = "brave-browser";
        exec = "brave http://erpcloud.siinergy.net/";
        terminal = false;
        categories = [ "Network" ];
      };
      outlook = {
        name = "Outlook";
        icon = "brave-browser";
        exec = "brave https://outlook.live.com/mail/";
        terminal = false;
        categories = [ "Network" ];
      };
      discord = {
        name = "Discord";
        icon = "brave-browser";
        exec = "brave https://discord.com/channels/@me";
        terminal = false;
        categories = [ "Network" ];
      };
      messenger = {
        name = "Messenger";
        icon = "brave-browser";
        exec = "brave https://www.facebook.com/messages/e2ee/t/8160697540693740/";
        terminal = false;
        categories = [ "Network" ];
      };
      mtgtop8-legacy = {
        name = "MTGTop8 - Legacy";
        icon = "brave-browser";
        exec = ''brave "https://mtgtop8.com/format?f=LE"'';
        terminal = false;
        categories = [ "Network" ];
      };
      facebook = {
        name = "Facebook";
        icon = "brave-browser";
        exec = "brave https://facebook.com/";
        terminal = false;
        categories = [ "Network" ];
      };
      maps = {
        name = "Maps";
        icon = "brave-browser";
        exec = "brave https://www.google.com/maps";
        terminal = false;
        categories = [ "Network" ];
      };
      github-essentia = {
        name = "Essentia";
        icon = "nvim";
        exec = "nvim /home/aron/projects/essentia";
        terminal = true;
        categories = [ "Development" ];
      };
      brood-war = {
        name = "StarCraft: Brood War";
        comment = "Retail 1.16.1 client under wine";
        icon = "applications-games";
        # The Mono/Gecko overrides stop wine from opening an installer dialog
        # the game does not need; gamescope scales 640x480 up to the monitor.
        exec = ''env WINEPREFIX=/home/aron/Games/prefixes/starcraft WINEDLLOVERRIDES="mscoree,mshtml=" gamescope -w 640 -h 480 -W 1920 -H 1080 -f -- wine /home/aron/Games/Starcraft/StarCraft.exe'';
        terminal = false;
        categories = [ "Game" ];
      };
      openbw = {
        name = "OpenBW (BWAPI)";
        comment = "Run a BWAPI bot on the OpenBW engine";
        icon = "applications-games";
        # run.sh is quiet while the game runs and prints its diagnostics on
        # failure, so keep a terminal attached rather than losing them.
        exec = "/home/aron/projects/openbw-env/run.sh";
        terminal = true;
        categories = [ "Game" "Development" ];
      };
      ygo-mtg-mse-menu = {
        name = "YGO X MTG: Essentia - MSE Menu";
        comment = "Open Essentia projects in Magic Set Editor";
        exec = "${pkgs.coreutils}/bin/env MSE_LIBRARY_PATH=${pkgs.wxwidgets_3_2}/lib ${msePython}/bin/python3 /home/aron/projects/essentia/launcher/mse_project_menu.pyw";
        terminal = false;
        categories = [ "Graphics" "Development" ];
        startupNotify = true;
        settings = {
          Path = "/home/aron/projects/essentia";
        };
      };
      github-repos = {
        name = "github-repos";
        icon = "brave-browser";
        exec = "brave \"https://github.com/AronGomu?tab=repositories\"";
        terminal = false;
        categories = [ "Network" ];
      };
      github-nix-aron = {
        name = "github-nix-aron";
        icon = "brave-browser";
        exec = "brave https://github.com/AronGomu/nix-aron";
        terminal = false;
        categories = [ "Network" ];
      };
      impeccable = {
        name = "Impeccable";
        icon = "brave-browser";
        exec = "brave https://github.com/pbakaus/impeccable";
        terminal = false;
        categories = [ "Network" ];
      };
      ascencio-duel-simulator = {
        name = "ASCENCIO - Duel Simulator";
        icon = "brave-browser";
        exec = "brave http://localhost:4300/";
        terminal = false;
        categories = [ "Network" ];
      };
      ascencio-deckbuilder = {
        name = "ASCENCIO - Deckbuilder";
        icon = "brave-browser";
        exec = "brave http://localhost:4301/";
        terminal = false;
        categories = [ "Network" ];
      };
      ascencio-vn = {
        name = "ASCENCIO - VN";
        icon = "brave-browser";
        exec = "brave http://localhost:4302/";
        terminal = false;
        categories = [ "Network" ];
      };
      github-brain = {
        name = "github-brain";
        icon = "brave-browser";
        exec = "brave https://github.com/AronGomu/brain";
        terminal = false;
        categories = [ "Network" ];
      };
      github-ygo-story = {
        name = "github-ygo-story";
        icon = "brave-browser";
        exec = "brave https://github.com/AronGomu/ygo-story-duel-simulator";
        terminal = false;
        categories = [ "Network" ];
      };
      github-gones = {
        name = "github-gones";
        icon = "brave-browser";
        exec = "brave https://github.com/AronGomu/gones";
        terminal = false;
        categories = [ "Network" ];
      };
      github-matt-pocock = {
        name = "github-matt-pocock";
        icon = "brave-browser";
        exec = "brave https://github.com/mattpocock/skills";
        terminal = false;
        categories = [ "Network" ];
      };
      github-agentsystemlabs-core = {
        name = "github-agentsystemlabs-core";
        icon = "brave-browser";
        exec = "brave https://github.com/AgentSystemLabs/core";
        terminal = false;
        categories = [ "Network" ];
      };
      github-essentia-page = {
        name = "github - Essentia";
        icon = "brave-browser";
        exec = "brave https://github.com/AronGomu/Essentia";
        terminal = false;
        categories = [ "Network" ];
      };
      google-drive = {
        name = "Google Drive";
        icon = "brave-browser";
        exec = "brave https://drive.google.com/drive/my-drive";
        terminal = false;
        categories = [ "Network" ];
      };
      claude-ai = {
        name = "Claude";
        icon = "brave-browser";
        exec = "brave https://claude.ai/";
        terminal = false;
        categories = [ "Network" ];
      };
      gones-local = {
        name = "Gones - http://localhost:4200";
        icon = "brave-browser";
        exec = "brave http://localhost:4200";
        terminal = false;
        categories = [ "Development" "Network" ];
      };
      essentia-local = {
        name = "Essentia - http://localhost:4201";
        icon = "brave-browser";
        exec = "brave http://localhost:4201";
        terminal = false;
        categories = [ "Development" "Network" ];
      };
      ascensio-local = {
        name = "Ascensio - http://localhost:4202";
        icon = "brave-browser";
        exec = "brave http://localhost:4202";
        terminal = false;
        categories = [ "Development" "Network" ];
      };
    };

    home.file.".local/share/nautilus/scripts/Copy Path" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        printf '%s' "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" | ${pkgs.gnused}/bin/sed '/^$/d' | ${pkgs.wl-clipboard}/bin/wl-copy
      '';
    };

    # Seed writable shell prefs once; keep wallpaper declarative.
    home.activation.end4InitialConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      config_dir="$HOME/.config/illogical-impulse"
      config_file="$config_dir/config.json"
      if [ ! -e "$config_file" ]; then
        mkdir -p "$config_dir"
        cat > "$config_file" <<'JSON'
      {
        "bar": {
          "screenList": []
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

      # The shell rewrites config.json at runtime and can leave it malformed.
      # Under activation's `set -e` a jq failure would abort the whole switch
      # before linkGeneration, so warn and leave the file alone instead.
      tmp_file="$(${pkgs.coreutils}/bin/mktemp)"
      # audio.protection latches lastVolume at 0 when PipeWire recreates the
      # sink (headphone unplug), then rewrites every raise back to 0 — silence
      # no volume tool can undo. Upstream default is false; keep it false.
      if ${pkgs.jq}/bin/jq --arg wallpaper "${wallpaper}" \
        'if .bar.screenList == ["HDMI-A-2"] then .bar.screenList = [] else . end
        | .background.wallpaperPath = $wallpaper
        | .audio.protection.enable = false' "$config_file" > "$tmp_file"; then
        ${pkgs.coreutils}/bin/mv -f "$tmp_file" "$config_file"
      else
        echo "warning: $config_file is not valid JSON — leaving it untouched" >&2
        ${pkgs.coreutils}/bin/rm -f "$tmp_file"
      fi
    '';
  };
}
