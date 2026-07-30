{
  inputs,
  pkgs,
  pkgsUnstable,
  ...
}:
let
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
  herdrTerminalsPatch = pkgs.writeText "herdr-terminals.patch" ''
    diff --git a/src/ui/sidebar.rs b/src/ui/sidebar.rs
    index 0ecfb65..a75d792 100644
    --- a/src/ui/sidebar.rs
    +++ b/src/ui/sidebar.rs
    @@ -130,6 +130,7 @@ fn agent_panel_entries_with_runtimes(
     ) -> Vec<AgentPanelEntry> {
         let mut entries = collect_agent_panel_entries_with_runtimes(app, terminal_runtimes);
         crate::app::agent_view::apply_agent_view(app, &mut entries);
    +    entries.sort_by_key(|entry| entry.agent.is_some());
         entries
     }

    @@ -1327,7 +1328,7 @@ fn render_agent_detail(

         frame.render_widget(
             Paragraph::new(Line::from(vec![Span::styled(
    -            " agents",
    +            " terminals / agents",
                 Style::default().fg(p.overlay0).add_modifier(Modifier::BOLD),
             )])),
             Rect::new(area.x, area.y + 1, area.width, 1),
    diff --git a/src/workspace/aggregate.rs b/src/workspace/aggregate.rs
    index 79b5a02..4f6c28a 100644
    --- a/src/workspace/aggregate.rs
    +++ b/src/workspace/aggregate.rs
    @@ -50,7 +50,8 @@ impl Tab {
                     let fallback_agent_label = terminal
                         .agent_name
                         .as_deref()
    -                    .or(agent_kind_label.as_deref())?
    +                    .or(agent_kind_label.as_deref())
    +                    .unwrap_or("terminal")
                         .to_string();
                     let agent_label = terminal
                         .effective_display_agent()
  '';
  herdrSource = pkgs.applyPatches {
    name = "herdr-0.7.5-terminals-source";
    src = inputs.herdr-src;
    patches = [ herdrTerminalsPatch ];
  };
  herdr = pkgs.callPackage "${herdrSource}/nix/package.nix" { };
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
in
{
  home.packages =
    with pkgs;
    [
      # Daily desktop
      copyq
      evince
      ffmpeg-full
      file-roller
      flameshot
      keepassxc
      mediainfo
      mpv
      obsidian
      p7zip
      pavucontrol
      strawberry
      thunderbird
      unrar

      # Development
      bat
      btop
      cargo
      curl
      direnv
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
      nodejs_24
      python3
      ripgrep
      rofi
      rustc
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
      home-manager
      davinciResolve
      herdr
      openwhispr
    ]
    ++ (with pkgsUnstable; [
      brave
      codex
      ghostty
      obs-studio
      pi-coding-agent
    ]);
}
