# home/linux/Desktop/browsers.nix — 浏览器
{ config, lib, pkgs, ... }:
let
  cfg = config.modules-home-linux-desktop-browsers;
in
{
  options.modules-home-linux-desktop-browsers = {
    enable = lib.mkEnableOption "Zen Browser";
  };

  config = lib.mkIf cfg.enable {
    # Zen Browser 由系统级 flake input 安装（output/X86_64-linux）
    # 此处无需再装
  };
}
