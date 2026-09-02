{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # Pinned Omarchy source tree with bash shebangs patched: the 400+ bin
  # scripts are `#!/bin/bash`, which does not exist on NixOS. Everything in
  # Omarchy resolves through $OMARCHY_PATH, so pointing that at this
  # derivation is enough to relocate the whole distro out of /usr/share.
  omarchyPkg = pkgs.stdenvNoCC.mkDerivation {
    pname = "omarchy";
    version = "4.0.0.alpha";
    src = inputs.omarchy;
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -R . $out
      chmod -R u+w $out
      # Whole tree, not just bin/: shell plugins exec their own .sh helpers
      # (clipboard/capture.sh, image-picker/list.sh, services/hidden-entries.sh).
      patchShebangs $out
      # Arch first-run provisioning: fights HM-managed mimeapps/agent dirs and
      # its enable-user-units step can never succeed on NixOS, so it would
      # retry every login.
      sed -i '/omarchy-provision-first-run/d' $out/default/hypr/autostart.lua
      runHook postInstall
    '';
  };
in
{
  options.desktop.omarchy = {
    enable = lib.mkEnableOption "Omarchy Hyprland desktop (pinned, no pacman update machinery)";
    package = lib.mkOption {
      type = lib.types.package;
      default = omarchyPkg;
      description = "Patched Omarchy tree; becomes $OMARCHY_PATH.";
    };
  };

  config = lib.mkIf config.desktop.omarchy.enable {
    assertions = [
      {
        assertion = !config.desktop.end4.enable;
        message = "desktop.omarchy and desktop.end4 both own ~/.config/hypr and the Quickshell session; enable only one.";
      }
    ];

    programs.hyprland = {
      enable = true;
      # Omarchy assumes a uwsm session: o.launch and the omarchy-launch-*
      # scripts wrap commands in `uwsm-app --`, and its user units hang off
      # graphical-session.target.
      withUWSM = true;
      xwayland.enable = true;
    };

    services = {
      displayManager.defaultSession = lib.mkForce "hyprland-uwsm";
      gnome.gnome-keyring.enable = true;
      upower.enable = true;
      # omarchy-powerprofiles-init runs from Hyprland autostart.
      power-profiles-daemon.enable = true;
    };

    # ddcutil (external monitor brightness) needs i2c.
    hardware.i2c.enable = true;
    boot.kernelModules = [ "i2c-dev" ];
    users.users.aron.extraGroups = [
      "i2c"
      "input"
    ];

    # Omarchy's Quickshell lock screen authenticates against this PAM service
    # (shell/plugins/lock/Service.qml reads /etc/pam.d/omarchy-lock-password).
    security.pam.services.omarchy-lock-password = { };

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
    };

    # xdph segfaults when the compositor goes away (upstream, crash in
    # libwayland-client during exit) and its instant restarts hit the default
    # start limit, leaving the portal unit failed for the next session until a
    # manual reset-failed. Pace restarts and drop the limit so a fresh
    # Hyprland session can always D-Bus-activate it again.
    systemd.user.services.xdg-desktop-portal-hyprland = {
      overrideStrategy = "asDropin";
      serviceConfig.RestartSec = 2;
      unitConfig.StartLimitIntervalSec = 0;
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      # hyprland.lua and every omarchy-* script fall back to /usr/share/omarchy
      # when this is unset, so it must be in the session env before Hyprland
      # starts (envs.lua then propagates it and prepends $OMARCHY_PATH/bin to
      # PATH itself). pam_env fixes the value at login: a running session keeps
      # the pre-rebuild store path until re-login, and GC while logged in can
      # delete it mid-session.
      OMARCHY_PATH = "${config.desktop.omarchy.package}";
    };
  };
}
