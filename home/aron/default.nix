{
  imports = [
    ./agents.nix
    ./desktop.nix
    ./google-drive.nix
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
