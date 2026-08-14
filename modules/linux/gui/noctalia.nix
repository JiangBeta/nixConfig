# modules/linux/gui/noctalia.nix — Noctalia Shell 系统级安装
{ config, lib, inputs, ... }:
let
  cfg = config.modules-nixos-gui-noctalia;
in
{
  options.modules-nixos-gui-noctalia = {
    enable = lib.mkEnableOption "Noctalia Shell（系统级）";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      inputs.noctalia.packages.x86_64-linux.default
    ];
  };
}
