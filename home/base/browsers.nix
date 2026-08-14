# home/base/browsers.nix — 浏览器（Zen Browser）
#
# 跨平台：Linux 与 macOS 共用。
# Zen Browser 本体由系统级（output/X86_64-linux 等）通过 symlinkJoin 安装，
# .desktop 文件也在那里完成 fcitx5 环境变量注入。
# 此处仅补充 session 级环境变量。
{ config, lib, ... }:
let
  cfg = config.modules-home-base-browsers;
in
{
  options.modules-home-base-browsers = {
    enable = lib.mkEnableOption "Zen Browser 环境变量";
  };

  config = lib.mkIf cfg.enable {
    # Wayland 原生模式（macOS 上无效果；fcitx 变量由 fcitx5.nix 的 home.sessionVariables 统一设置）
    home.sessionVariables.MOZ_ENABLE_WAYLAND = "1";
  };
}
