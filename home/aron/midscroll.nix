{ pkgs, ... }:
let
  midscroll = pkgs.callPackage ../../pkgs/midscroll.nix { };
in
{
  home.packages = [ midscroll ];

  systemd.user.services.midscroll-overlay = {
    Unit = {
      Description = "midscroll session helper - autoscroll cursor and focus reporting";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${midscroll}/bin/midscroll-overlay";
      Restart = "on-failure";
      RestartSec = 2;
      NoNewPrivileges = true;
      CapabilityBoundingSet = [ ];
      AmbientCapabilities = [ ];
      ProtectSystem = "full";
      ProtectKernelTunables = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectHostname = true;
      RestrictNamespaces = true;
      RestrictSUIDSGID = true;
      RestrictRealtime = true;
      LockPersonality = true;
      SystemCallArchitectures = "native";
      RestrictAddressFamilies = [ "AF_UNIX" "AF_NETLINK" ];
      UMask = "0077";
      TasksMax = 64;
      SystemCallFilter = [ "@system-service" ];
      SystemCallErrorNumber = "EPERM";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
