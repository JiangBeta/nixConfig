# home/linux/Desktop/browsers.nix — 浏览器（Zen Browser）
#
# Zen Browser 本体由系统级 output/X86_64-linux 通过 symlinkJoin 安装，
# .desktop 文件也在那里完成 fcitx5 环境变量注入。
# 此处仅补充 session 级环境变量。
{ config, lib, ... }:
let
  cfg = config.modules-home-linux-desktop-browsers;
in
{
  options.modules-home-linux-desktop-browsers = {
    enable = lib.mkEnableOption "Zen Browser 环境变量";
  };

  config = lib.mkIf cfg.enable {
    # Wayland 原生模式（fcitx 变量由 fcitx5.nix 的 home.sessionVariables 统一设置）
    home.sessionVariables.MOZ_ENABLE_WAYLAND = "1";
  };
}
