{
  # Steam desktop app only. No gamescope login session (that added a LightDM
  # "Steam" entry and could soft-lock past XFCE).
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = false;
    dedicatedServer.openFirewall = false;
    localNetworkGameTransfers.openFirewall = false;
  };
}
