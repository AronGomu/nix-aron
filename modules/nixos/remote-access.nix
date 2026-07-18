{ config, ... }:
{
  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedUDPPorts = [ config.services.tailscale.port ];
      checkReversePath = "loose";
      interfaces.tailscale0.allowedTCPPorts = [ 22 ];
    };
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
