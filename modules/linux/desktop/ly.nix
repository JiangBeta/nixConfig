# modules/linux/desktop/ly.nix — Ly 显示管理器
{ config, lib, ... }:
let
  cfg = config.modules-nixos-desktop-ly;
in
{
  options.modules-nixos-desktop-ly = {
    enable = lib.mkEnableOption "Ly 显示管理器";
  };

  config = lib.mkIf cfg.enable {
    services.displayManager.ly = {
      enable = true;
    };
  };
}
