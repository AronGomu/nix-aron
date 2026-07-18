{ pkgs, ... }:
{
  programs = {
    steam = {
      enable = true;
      gamescopeSession.enable = true;
      remotePlay.openFirewall = false;
      dedicatedServer.openFirewall = false;
      localNetworkGameTransfers.openFirewall = false;
    };
    gamemode.enable = true;
  };

  environment.systemPackages = with pkgs; [
    gamescope
    mangohud
  ];
}
