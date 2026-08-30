{
  inputs,
  lib,
  pkgs,
  pkgsUnstable,
  ...
}:
let
  braveExtensionIds = [
    "khncfooichmfjbepaaaebmommgaepoid" # Unhook — kill YT distractions
    "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock
    "ponfpcnoihfmfllpaingbgckeeldkhle" # Enhancer for YouTube
    "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
    "fnaicdffflnofjppbagibeoednhnbjhg" # Floccus — bookmark sync (git/WebDAV)
  ];
  davinciResolve = pkgs.symlinkJoin {
    name = "davinci-resolve-wrapped";
    paths = [ pkgsUnstable.davinci-resolve ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/davinci-resolve \
        --unset QT_PLUGIN_PATH \
        --unset QT_STYLE_OVERRIDE \
        --unset QT_QPA_PLATFORMTHEME
    '';
  };
  herdrUnwrapped = pkgs.callPackage "${inputs.herdr-src}/nix/package.nix" { };
  herdrNotifyShim = pkgs.callPackage ../../pkgs/herdr-notify-shim.nix { };
  # Upstream toasts are plain `notify-send -- <title> <body>`, i.e. no D-Bus
  # action to invoke on click. Prefixing herdr's PATH with the shim makes its
  # notifications focus the workspace/tab that raised them.
  herdr = pkgs.symlinkJoin {
    name = "herdr-wrapped";
    paths = [ herdrUnwrapped ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/herdr \
        --prefix PATH : ${herdrNotifyShim}/bin
    '';
  };
  grokImagine = pkgs.callPackage ../../pkgs/grok-imagine.nix { };
  onekeyWallet = pkgs.callPackage ../../pkgs/onekey-wallet.nix { };
  openwhisprHyprlandCancelPatch = pkgs.writeText "openwhispr-hyprland-cancel.patch" ''
    diff --git a/src/helpers/hotkeyManager.js b/src/helpers/hotkeyManager.js
    index 6931e82..abab7d1 100644
    --- a/src/helpers/hotkeyManager.js
    +++ b/src/helpers/hotkeyManager.js
    @@ -253,6 +253,26 @@ class HotkeyManager extends EventEmitter {
           return { success: true, hotkey };
         }

    +    // On Hyprland, register temporary cancel natively because Electron globalShortcut
    +    // cannot capture Escape reliably under Wayland.
    +    if (this.useHyprland && this.hyprlandManager && slotName === "cancel") {
    +      this.unregisterSlot(slotName);
    +      const success = await this.hyprlandManager.registerCancelKeybinding(hotkey, callback);
    +      if (!success) {
    +        return {
    +          success: false,
    +          error: i18nMain.t("hotkey.errors.registrationFailed", { hotkey }),
    +        };
    +      }
    +
    +      const slot = this._ensureSlot(slotName);
    +      slot.hotkeys = [hotkey];
    +      slot.callback = callback;
    +      slot.accelerators = [];
    +      this.slots.set(slotName, slot);
    +      return { success: true, hotkey };
    +    }
    +
         // On KDE (X11 or Wayland), route persistent slots through KGlobalAccel D-Bus.
         // Temporary slots like "cancel" stay on globalShortcut to avoid stale
         // KGlobalAccel registrations after crash (Escape would stop working system-wide).
    @@ -298,6 +318,15 @@ class HotkeyManager extends EventEmitter {
         const slot = this.slots.get(slotName);
         if (!slot || !(slot.hotkeys && slot.hotkeys.length)) return;

    +    if (this.useHyprland && this.hyprlandManager && slotName === "cancel") {
    +      this.hyprlandManager.unregisterCancelKeybinding().catch((err) => {
    +        debugLogger.warn("[HotkeyManager] Error unregistering Hyprland cancel keybinding:", err.message);
    +      });
    +      slot.hotkeys = [];
    +      slot.accelerators = [];
    +      return;
    +    }
    +
         // On KDE (X11 or Wayland), persistent slots are managed via KGlobalAccel
         if (this.useKDE && this.kdeManager && slotName !== "cancel") {
           this.kdeManager.unregisterKeybinding(slotName).catch((err) => {
    diff --git a/src/helpers/clipboard.js b/src/helpers/clipboard.js
    --- a/src/helpers/clipboard.js
    +++ b/src/helpers/clipboard.js
    @@ -1250,7 +1250,9 @@ class ClipboardManager {
         const wtypeExists = this.commandExists("wtype");
         const ydotoolExists = this.commandExists("ydotool");
         const ydotoolDaemonRunning = ydotoolExists && this._isYdotoolDaemonRunning();
    -    const linuxFastPaste = this.resolveLinuxFastPasteBinary();
    +    // Hyprland can drop modifiers from the helper's short-lived uinput device,
    +    // producing a bare "v" or no input. Use persistent ydotoold instead.
    +    const linuxFastPaste = isHyprland ? null : this.resolveLinuxFastPasteBinary();

         debugLogger.debug(
           "Linux paste environment",
    @@ -1715,6 +1717,9 @@ class ClipboardManager {
         if (!isWayland) {
           // X11: xdotool is native and needs no daemon; ydotool as fallback
           candidates = [...xdotoolEntry, ...ydotoolEntry];
    +    } else if (isHyprland) {
    +      // Prefer persistent uinput device; wtype may emit bare "v".
    +      candidates = [...ydotoolEntry, ...wtypeEntry, ...xdotoolEntry];
         } else if (isWlroots) {
           // wlroots (Sway, Hyprland, etc.): wtype is native; then xdotool for XWayland; ydotool last
           candidates = [...wtypeEntry, ...xdotoolEntry, ...ydotoolEntry];
    diff --git a/src/helpers/hyprlandShortcut.js b/src/helpers/hyprlandShortcut.js
    index e2bacc6..cca2ba0 100644
    --- a/src/helpers/hyprlandShortcut.js
    +++ b/src/helpers/hyprlandShortcut.js
    @@ -96,8 +96,10 @@ class HyprlandShortcutManager {
       constructor() {
         this.bus = null;
         this.callback = null;
    +    this.cancelCallback = null;
         this.isRegistered = false;
         this.currentBinding = null; // Store the current Hyprland bind string for unbinding
    +    this.cancelBinding = null;
       }

       /**
    @@ -157,12 +159,18 @@ class HyprlandShortcutManager {
                   this.callback();
                 }
               },
    +          Cancel: () => {
    +            if (this.cancelCallback) {
    +              this.cancelCallback();
    +            }
    +          },
             },
             DBUS_OBJECT_PATH,
             {
               name: DBUS_INTERFACE,
               methods: {
                 Toggle: ["", ""],
    +            Cancel: ["", ""],
               },
             }
           );
    @@ -421,6 +429,45 @@ class HyprlandShortcutManager {
         }
       }

    +  async registerCancelKeybinding(hotkey, callback) {
    +    const converted = HyprlandShortcutManager.convertToHyprlandFormat(hotkey);
    +    if (!converted) return false;
    +
    +    await this.unregisterCancelKeybinding();
    +    this.cancelCallback = callback;
    +    const dbusCommand = `dbus-send --session --type=method_call --dest=''${DBUS_SERVICE_NAME} ''${DBUS_OBJECT_PATH} ''${DBUS_INTERFACE}.Cancel`;
    +    const bindValue = `''${converted.bindKey}, exec, ''${dbusCommand}`;
    +
    +    try {
    +      execFileSync("hyprctl", ["keyword", "bind", bindValue], {
    +        stdio: "pipe",
    +        timeout: 5000,
    +      });
    +      this.cancelBinding = converted.bindKey;
    +      return true;
    +    } catch (err) {
    +      this.cancelCallback = null;
    +      debugLogger.log("[HyprlandShortcut] Failed to register cancel keybinding:", err.message);
    +      return false;
    +    }
    +  }
    +
    +  async unregisterCancelKeybinding() {
    +    if (this.cancelBinding) {
    +      try {
    +        execFileSync("hyprctl", ["keyword", "unbind", this.cancelBinding], {
    +          stdio: "pipe",
    +          timeout: 5000,
    +        });
    +      } catch (err) {
    +        debugLogger.log("[HyprlandShortcut] Failed to unregister cancel keybinding:", err.message);
    +      }
    +    }
    +    this.cancelBinding = null;
    +    this.cancelCallback = null;
    +    return true;
    +  }
    +
       /**
        * Update the keybinding to a new hotkey.
        */
    @@ -465,6 +512,7 @@ class HyprlandShortcutManager {
        * Clean up D-Bus connection.
        */
       close() {
    +    void this.unregisterCancelKeybinding();
         if (this.bus) {
           this.bus.connection.end();
           this.bus = null;
  '';
  openwhisprVersion = "1.7.6";
  openwhisprAppImage = pkgs.fetchurl {
    url = "https://github.com/OpenWhispr/openwhispr/releases/download/v${openwhisprVersion}/OpenWhispr-${openwhisprVersion}-linux-x86_64.AppImage";
    hash = "sha256-8c1bE3ZfJTb0ZXQb3mRAfj7QtMoUkaby8N3133Gg3z4=";
  };
  openwhisprContents = pkgs.appimageTools.extractType2 {
    pname = "openwhispr";
    version = openwhisprVersion;
    src = openwhisprAppImage;
  };
  openwhisprPatchedContents =
    pkgs.runCommand "openwhispr-${openwhisprVersion}-patched"
      {
        nativeBuildInputs = [
          pkgs.asar
          pkgs.patch
        ];
      }
      ''
        cp -a ${openwhisprContents} $out
        chmod -R u+w $out
        while ! asar extract $out/resources/app.asar app 2>asar-error.log; do
          missing=$(grep -o "'/nix/store/[^']*'" asar-error.log | head -1 | tr -d "'")
          test -n "$missing"
          mkdir -p "$(dirname "$missing")"
          touch "$missing"
        done
        patch -d app -p1 < ${openwhisprHyprlandCancelPatch}
        rm -rf $out/resources/app.asar $out/resources/app.asar.unpacked
        asar pack app $out/resources/app.asar --unpack "**"
      '';
  openwhisprApp = pkgs.appimageTools.wrapAppImage {
    pname = "openwhispr";
    version = openwhisprVersion;
    src = openwhisprPatchedContents;
    extraInstallCommands = ''
      install -m 444 -D ${openwhisprPatchedContents}/open-whispr.desktop $out/share/applications/open-whispr.desktop
      install -m 444 -D ${openwhisprPatchedContents}/open-whispr.png $out/share/icons/hicolor/512x512/apps/open-whispr.png
      substituteInPlace $out/share/applications/open-whispr.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=openwhispr'
    '';
  };
  openwhispr = pkgs.symlinkJoin {
    name = "openwhispr-${openwhisprVersion}";
    paths = [ openwhisprApp ];
    postBuild = ''
      rm $out/bin/openwhispr
      cat > $out/bin/openwhispr <<'EOF'
      #!${pkgs.bash}/bin/bash
      export YDOTOOL_SOCKET=/run/ydotoold/socket
      printf -v quoted_args ' %q' "$@"
      exec /run/wrappers/bin/sg ydotool -c "exec ${openwhisprApp}/bin/openwhispr''${quoted_args}"
      EOF
      chmod 755 $out/bin/openwhispr
    '';
  };
  # The essentia repo drives its whole Python toolchain (.script/, tests/, and
  # the website's `npm run cards:rebuild`) through the plain `python` on PATH,
  # and those modules import Pillow, lxml and requests. The bare python3 has
  # none of them. nixpkgs' pillow is 12.3.0, which is the version essentia's
  # requirements-dev.lock pins.
  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      lxml
      pillow
      requests
    ]
  );
  # ytmusic-sync drives ytmusicapi from Python; it is what tells the account's
  # YouTube *Music* playlists apart from its ordinary video playlists, which the
  # channel's /playlists page lists together.
  ytmusicPythonEnv = pkgs.python3.withPackages (ps: with ps; [ ytmusicapi ]);
  ytmusic-sync = pkgs.writeShellApplication {
    name = "ytmusic-sync";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.ffmpeg-full # yt-dlp shells out to it for opus extraction and cover art
      pkgs.procps # pgrep/pkill, to guard --relink and flush Strawberry cleanly
      pkgs.strawberry
      pkgs.yt-dlp
    ];
    text = ''
      exec ${ytmusicPythonEnv}/bin/python3 ${./scripts/ytmusic-sync.py} "$@"
    '';
  };
  remove-silence = pkgs.writeShellApplication {
    name = "remove-silence";
    runtimeInputs = [
      pkgs.auto-editor
      pkgs.coreutils
    ];
    text = builtins.readFile ./scripts/remove-silence.sh;
  };
  social-square = pkgs.writeShellApplication {
    name = "social-square";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.imagemagick
      pkgs.oxipng # lossless pass after quantisation
      pkgs.pngquant # lossy palette pass, the one that actually shrinks photos
    ];
    text = builtins.readFile ./scripts/social-square.sh;
  };
in
{
  home.packages =
    with pkgs;
    [
      # Daily desktop
      copyq
      evince
      ffmpeg-full
      ffmpegthumbnailer # Nautilus video thumbs via share/thumbnailers
      sushi # Nautilus Space quick preview (org.gnome.NautilusPreviewer)
      file-roller
      flameshot
      gimp
      keepassxc
      qbittorrent
      mediainfo
      mpv
      obsidian
      p7zip
      pavucontrol
      strawberry
      thunderbird
      unrar

      # Gaming. StarCraft: Brood War lives in ~/Games/Starcraft and runs from
      # there under wine; winetricks is for prefix surgery when it misbehaves.
      # StarCraft.exe is a 32-bit binary, so it needs a WoW64-capable wine —
      # wineWowPackages is the multilib predecessor and is deprecated upstream.
      # gamescope upscales the game's fixed 640x480 output to the monitor with
      # the aspect ratio intact; without it the game sits in a corner of a
      # tiled wine desktop.
      gamescope
      lutris
      wineWow64Packages.stable
      winetricks

      # Development
      bat
      btop
      cargo
      clippy
      # C#/.NET toolchain for the Neovim setup. netcoredbg and csharpier come
      # from nixpkgs rather than Mason: Mason ships prebuilt ELF binaries that
      # do not run on NixOS. The roslyn language server stays on Mason since it
      # is a .NET DLL launched through `dotnet`.
      csharpier
      curl
      direnv
      dotnet-sdk_10
      eza
      fastfetch
      fd
      fzf
      gcc
      gh
      git
      gnumake
      go
      htop
      jq
      lazygit
      neovim
      netcoredbg
      nodejs_24
      pythonEnv
      ripgrep
      rofi
      rustc
      rustfmt
      # bash-language-server shells out to shellcheck for diagnostics. Mason's
      # shellcheck is a prebuilt binary that does not run on NixOS, so the
      # Neovim bashls setup takes it from here instead.
      shellcheck
      smartmontools
      tree
      tree-sitter
      unzip
      uv
      wget
      xclip
      xsel
      yq-go
      zip
      zoxide
      # home-manager: provided by programs.home-manager.enable (default.nix).
      # Listing it here too collides in buildEnv once the flake input and
      # nixpkgs ship different versions.
      davinciResolve
      herdr
      openwhispr
      grokImagine
      onekeyWallet
      auto-editor
      remove-silence
      social-square
      ytmusic-sync
    ]
    ++ (with pkgsUnstable; [
      brave-origin
      claude-code
      codex
      ghostty
      grok-cli
      obs-studio
      pi-coding-agent
    ]);

  # Brave + Chrome Web Store extensions (auto-install on launch)
  programs.brave = {
    enable = true;
    package = pkgsUnstable.brave;
    extensions = map (id: { inherit id; }) braveExtensionIds;
  };

  # programs.brave writes its extension manifests under Brave-Browser only.
  # Brave Origin keeps its own data dir, so it needs the same manifests there.
  home.file = lib.listToAttrs (
    map (
      id:
      lib.nameValuePair ".config/BraveSoftware/Brave-Origin/External Extensions/${id}.json" {
        text = builtins.toJSON {
          external_update_url = "https://clients2.google.com/service/update2/crx";
        };
      }
    ) braveExtensionIds
  );
}
