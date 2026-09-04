# Everything about desk-main that is not disk-specific.
#
# Deliberately NOT a complete host and deliberately not named default.nix: it
# declares no fileSystems, so it cannot be built on its own. The storage layout
# arrives from ./samsung.nix or ./nvme.nix, which are the real flake entries.
{ pkgs, ... }:
let
  disks = import ./disks.nix;

  # Prints the flake output for the disk this system is actually running from.
  # The `rebuild` alias in home/aron/shell.nix calls it, so a rebuild always
  # targets the running disk. On 2026-08-06 a `switch` carrying the NVMe layout
  # ran on the Samsung and mounted the NVMe's @nix over the live store; this is
  # what makes that unreachable rather than one line of config away.
  nixos-host = pkgs.writeShellApplication {
    name = "nixos-host";
    runtimeInputs = [ pkgs.util-linux ];
    text = ''
      root_uuid="$(findmnt -no UUID /)"
      case "$root_uuid" in
        ${disks.samsung.root}) echo desk-main-samsung ;;
        ${disks.nvme.root}) echo desk-main-nvme ;;
        *)
          echo "nixos-host: root UUID $root_uuid is not a known desk-main disk." >&2
          echo "            Add it to hosts/desk-main/disks.nix before rebuilding." >&2
          exit 1
          ;;
      esac
    '';
  };
in
{
  imports = [
    ./hardware-configuration.nix

    # shared
    ../../modules/nixos

    # this machine only
    ../../modules/nixos/nvidia.nix
    ../../modules/nixos/gaming.nix
    ../../modules/nixos/openrazer.nix
  ];

  networking.hostName = "desk-main";

  desktop.omarchy.enable = true;

  environment.systemPackages = [ nixos-host ];

  system.stateVersion = "26.05";
}
