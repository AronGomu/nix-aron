{ pkgs, ... }:
let
  midscroll = pkgs.callPackage ../../pkgs/midscroll.nix { };
in
{
  environment.systemPackages = [ midscroll ];

  environment.etc."midscroll.conf".source = "${midscroll}/etc/midscroll.conf";

  systemd.services.midscroll = {
    description = "midscroll - Windows-style middle-drag autoscroll";
    wants = [ "modprobe@uinput.service" ];
    after = [ "modprobe@uinput.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${midscroll}/bin/midscroll";
      RuntimeDirectory = "midscroll";
      Restart = "always";
      RestartSec = 2;
      CPUSchedulingPolicy = "fifo";
      CPUSchedulingPriority = 20;
      NoNewPrivileges = true;
      CapabilityBoundingSet = [ ];
      AmbientCapabilities = [ ];
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateNetwork = true;
      IPAddressDeny = "any";
      RestrictAddressFamilies = [ "AF_UNIX" ];
      ProtectProc = "invisible";
      ProcSubset = "pid";
      ProtectKernelTunables = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectHostname = true;
      RestrictNamespaces = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      SystemCallArchitectures = "native";
      UMask = "0077";
      MemoryMax = "128M";
      TasksMax = 32;
      SystemCallFilter = [ "@system-service" ];
      SystemCallErrorNumber = "EPERM";
      MemoryDenyWriteExecute = true;
    };
  };
}
