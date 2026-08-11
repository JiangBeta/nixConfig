# home/linux/Desktop/noctalia.nix — Noctalia Shell（状态栏/启动器/锁屏）
{ config, lib, pkgs, ... }:
let
  cfg = config.modules-home-linux-desktop-noctalia;
in
{
  options.modules-home-linux-desktop-noctalia = {
    enable = lib.mkEnableOption "Noctalia Shell";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      brightnessctl  # 亮度控制
      cliphist       # 剪贴板历史
    ];

    home.sessionVariables = {
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_QPA_PLATFORMTHEME = "qt6ct";
    };
  };
}
