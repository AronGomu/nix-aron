{
  description = "Aron's NixOS daily-driver configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvim-config = {
      url = "github:AronGomu/TRULY_CUSTOM_NVIM_WINDOWS_LINUX";
      flake = false;
    };

    end4 = {
      url = "git+https://github.com/end-4/dots-hyprland.git?submodules=1";
      flake = false;
    };

    herdr-src = {
      url = "github:herdrdev/herdr/v0.7.5";
      flake = false;
    };

    quickshell = {
      url = "github:quickshell-mirror/quickshell/7511545ee20664e3b8b8d3322c0ffe7567c56f7a";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      ...
    }:
    let
      system = "x86_64-linux";
      allowUnfree = import ./lib/allow-unfree.nix { lib = nixpkgs.lib; };
      pkgsUnstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfreePredicate = allowUnfree;
      };

      # Shared HM + specialArgs wiring for every host.
      mkNixos =
        hostPath:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs pkgsUnstable allowUnfree;
          };
          modules = [
            hostPath
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "hm-backup";
              home-manager.extraSpecialArgs = {
                inherit inputs pkgsUnstable;
              };
              home-manager.users.aron = import ./home/aron;
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        desk-main = mkNixos ./hosts/desk-main;
        # laptop = mkNixos ./hosts/laptop;
      };

      homeConfigurations.desk-main = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsUnstable;
        extraSpecialArgs = {
          inherit inputs pkgsUnstable;
        };
        modules = [ ./home/aron ];
      };

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-tree;
    };
}
