# Shared stack. Host pulls optional modules (nvidia, gaming) itself.
{
  imports = [
    ./base.nix
    ./boot.nix
    ./desktop.nix
    ./end4.nix
    ./nix.nix
    ./remote-access.nix
  ];
}
