{ pkgs, ... }:

{
  home.packages = with pkgs; [
    fuse3
    rclone
  ];

  systemd.user.services.rclone-gdrive = {
    Unit = {
      Description = "Mount Google Drive";
      ConditionPathExists = "%h/.config/rclone/rclone.conf";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Type = "notify";
      ExecStartPre = [
        "-${pkgs.fuse3}/bin/fusermount3 -uz %h/GoogleDrive"
        "${pkgs.coreutils}/bin/mkdir -p %h/GoogleDrive"
      ];
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount gdrive: %h/GoogleDrive \
          --config=%h/.config/rclone/rclone.conf \
          --vfs-cache-mode=writes \
          --dir-cache-time=1h \
          --attr-timeout=1h
      '';
      ExecStartPost = "${pkgs.bash}/bin/bash -c '${pkgs.findutils}/bin/find %h/GoogleDrive -maxdepth 4 >/dev/null 2>&1 &'";
      ExecStop = "-${pkgs.fuse3}/bin/fusermount3 -uz %h/GoogleDrive";
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.paths.rclone-gdrive-config = {
    Unit.Description = "Watch for rclone configuration";
    Path = {
      PathExists = "%h/.config/rclone/rclone.conf";
      Unit = "rclone-gdrive.service";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
