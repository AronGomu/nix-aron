{
  description = "Aron's NixOS daily-driver configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Pinned to source newer claude-code (2.1.224) and pi-coding-agent (0.84.0)
    # via the narrow overlay below.
    nixpkgs-claude.url = "github:NixOS/nixpkgs/f13ff45afd1bb73e640eaa08a7066dbed07e3238";

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

    # Pinned Omarchy tree (v4 "Quattro": Quickshell shell + Hyprland Lua config).
    # Pinned to a commit on purpose — Omarchy's own update machinery is
    # pacman-based and unused here; bump the rev to update.
    omarchy = {
      url = "github:omacom/omarchy/7eca64e2683d2a4d4620f36164f001693ae6a5b7";
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
        overlays = [
          # Surgical: only these packages come from the pinned nixpkgs-claude input.
          (_final: _prev: {
            claude-code =
              (import inputs.nixpkgs-claude {
                inherit system;
                config.allowUnfreePredicate = allowUnfree;
              }).claude-code;
            pi-coding-agent =
              (import inputs.nixpkgs-claude {
                inherit system;
                config.allowUnfreePredicate = allowUnfree;
              }).pi-coding-agent;
          })
        ];
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
      # One output per physical disk. There is deliberately no bare `desk-main`:
      # a rebuild has to name the disk it is for, so a stale `#desk-main` command
      # fails with "unknown flake output" instead of writing one disk's fstab
      # into the other disk's running system. Use `nixos-host` (or the `rebuild`
      # alias, which calls it) to get the output matching the running root.
      nixosConfigurations = {
        desk-main-samsung = mkNixos ./hosts/desk-main/samsung.nix; # sdb, ext4
        desk-main-nvme = mkNixos ./hosts/desk-main/nvme.nix; # nvme0n1, btrfs
        # laptop = mkNixos ./hosts/laptop;
      };

      # No homeConfigurations output. Home Manager is wired through the NixOS
      # module (see mkNixos above), and a standalone HM config gets no
      # `osConfig`, so home/aron/end4.nix evaluates `enabled = false` and emits
      # none of the hypr*/quickshell files — while writing the same
      # ~/.local/state/nix/profiles/home-manager the NixOS module owns. Running
      # it would wipe the desktop config. Removing the output makes every
      # spelling of that command fail with "unknown flake output" instead, the
      # same mechanism that protects the bare `desk-main` system output.
      # Apply HM changes with `rebuild`.

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-tree;
    };
}
