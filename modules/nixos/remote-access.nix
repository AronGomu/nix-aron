{ config, ... }:
{
  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedUDPPorts = [ config.services.tailscale.port ];
      checkReversePath = "loose";
      interfaces.tailscale0 = {
        allowedTCPPorts = [ 22 ];
        # mosh roams across IP changes (phone LTE<->wifi, sleep/wake), so a
        # session survives what would kill a plain ssh conn.
        allowedUDPPortRanges = [
          {
            from = 60000;
            to = 61000;
          }
        ];
      };
    };
  };

  # openFirewall would punch 60000-61000 on every interface. The port range is
  # tailnet-only above, matching how ssh is already scoped.
  programs.mosh = {
    enable = true;
    openFirewall = false;
  };

  services = {
    tailscale.enable = true;
    openssh = {
      enable = true;
      openFirewall = false;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };
}
