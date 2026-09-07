{ ... }:
{
  systemd.user.services.cptr = {
    Unit.Description = "Open WebUI Computer";

    Service = {
      Type = "simple";
      ExecStart = "/home/aron/.local/bin/cptr run --host 127.0.0.1 --port 8000 --headless";
      WorkingDirectory = "/home/aron";
      Restart = "on-failure";
      RestartSec = 5;
      UMask = "0077";
      Environment = [
        "HOME=/home/aron"
        "CPTR_DATA_DIR=/home/aron/.cptr"
        "PATH=/home/aron/.local/bin:/home/aron/.dotnet/tools:/run/wrappers/bin:/etc/profiles/per-user/aron/bin:/run/current-system/sw/bin"
      ];
    };

    Install.WantedBy = [ "default.target" ];
  };
}
