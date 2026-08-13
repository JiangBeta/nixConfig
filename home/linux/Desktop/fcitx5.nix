# home/linux/Desktop/fcitx5.nix — Fcitx5 Linux 专属（IM 注册 + 环境变量）
#
# 通用配置（rime 数据 / 主题 / fcitx5 主配置）在 home/base/fcitx5.nix，
# 本文件仅负责 Linux 特有的输入法前端注册与 session 环境变量。
{ config, lib, pkgs, ... }:
let
  cfg = config.modules-home-linux-desktop-fcitx5;
in
{
  options.modules-home-linux-desktop-fcitx5 = {
    enable = lib.mkEnableOption "Fcitx5 Linux IM 注册与环境变量";
  };

  config = lib.mkIf cfg.enable {
    i18n.inputMethod = {
      enabled = "fcitx5";
      fcitx5.waylandFrontend = true;
      fcitx5.addons = with pkgs; [
        (fcitx5-rime.override {
          rimeDataPkgs = [ rime-ice ];
        })
        fcitx5-gtk
        fcitx5-rime
        fcitx5-gtk
      ];
    };

    # Arch Wiki：Wayland 下勿设 GTK_IM_MODULE 环境变量（GTK 改用 gtk-3.0/settings.ini 的 gtk-im-module）。
    # Qt 保留 QT_IM_MODULE=fcitx（Qt5/Xwayland）；QT_IM_MODULES 让 Qt6 优先走 wayland 文本输入协议。
    home.sessionVariables = {
      QT_IM_MODULE = "fcitx";
      QT_IM_MODULES = "wayland;fcitx";
      XMODIFIERS = "@im=fcitx";
      SDL_IM_MODULE = "fcitx";
    };
  };
}
