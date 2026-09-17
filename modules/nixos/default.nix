# Shared stack. Host pulls optional modules (nvidia, gaming) itself.
{
  imports = [
    ./base.nix
    ./boot.nix
    ./brave-policies.nix
    ./desktop.nix
    ./forgejo.nix
    ./mullvad.nix
    ./niri.nix
    ./omarchy.nix
    ./nix.nix
    ./remote-access.nix
  ];
}
