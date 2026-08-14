# modules/linux/gui/ly.nix — Ly 显示管理器
{ config, lib, ... }:
let
  cfg = config.modules-nixos-gui-ly;
in
{
  options.modules-nixos-gui-ly = {
    enable = lib.mkEnableOption "Ly 显示管理器";
  };

  config = lib.mkIf cfg.enable {
    services.displayManager.ly = {
      enable = true;
      settings = {
        animation = "matrix";
      };
    };
  };
}
