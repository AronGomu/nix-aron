{
  imports = [
    ./agents.nix
    ./desktop.nix
    ./end4.nix
    ./google-drive.nix
    ./herdr.nix
    ./kdenlive.nix
    ./keepassxc.nix
    ./packages.nix
    ./repos.nix
    ./shell.nix
  ];

  home = {
    username = "aron";
    homeDirectory = "/home/aron";
    stateVersion = "26.05";

    # HM already exports XDG_BIN_HOME=$HOME/.local/bin but never puts it on
    # PATH, so anything installed there — `uv tool install` shims such as
    # graphify, pipx, cargo-less one-offs — resolves only by absolute path.
    # sessionPath writes it into hm-session-vars.sh, the same file the rest of
    # the session variables above come from, so login shells and the shells
    # agent harnesses spawn both inherit it.
    # `dotnet tool install -g` (dotnet-stryker and friends) drops its shims in
    # ~/.dotnet/tools and is not packaged in nixpkgs, so that directory has to
    # be on PATH for the tools to resolve by name.
    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.dotnet/tools"
    ];
  };

  programs.home-manager.enable = true;
}
