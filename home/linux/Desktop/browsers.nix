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
    home.packages = with pkgs; [
      # zen-browser — 不在 nixpkgs 中，需要确认包名或从 flake 引入
      firefox  # 回退
    ];
  };
}
