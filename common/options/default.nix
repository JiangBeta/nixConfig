# common/options/default.nix
{ ... }:

{
  imports = [
    ./user.nix
    ./hardware.nix
    ./system.nix
    ./ai.nix
  ];
}
