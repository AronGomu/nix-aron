{
  imports = [
    ./agents.nix
    ./desktop.nix
    ./end4.nix
    ./google-drive.nix
    ./herdr.nix
    ./packages.nix
    ./shell.nix
  ];

  home = {
    username = "aron";
    homeDirectory = "/home/aron";
    stateVersion = "26.05";
  };

  programs.home-manager.enable = true;
}
