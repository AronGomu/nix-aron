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
    };

    Service = {
      Type = "notify";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/GoogleDrive";
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount gdrive: %h/GoogleDrive \
          --config=%h/.config/rclone/rclone.conf \
          --vfs-cache-mode=writes
      '';
      ExecStop = "${pkgs.fuse3}/bin/fusermount3 -u %h/GoogleDrive";
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
