# home/linux/gui/qt.nix — Qt 平台主题与图标
#
# Qt 应用走 qt6ct 平台主题，图标对齐 GTK 的 Tela-dark。
# 用 qt6ct（读 ~/.config/qt6ct/qt6ct.conf）而非 qgnomeplatform，
# 因为后者依赖 GSettings/dconf，在 Niri 环境读不到 settings.ini 里的图标主题。
{ config, lib, pkgs, ... }:
let
  cfg = config.modules-home-linux-gui-qt;
in
{
  options.modules-home-linux-gui-qt = {
    enable = lib.mkEnableOption "Qt 平台主题与图标";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      qt6Packages.qt6ct
    ];

    home.sessionVariables = {
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_QPA_PLATFORMTHEME = "qt6ct";
    };

    # Qt6 图标主题对齐 Tela-dark（与 GTK 一致）
    xdg.configFile."qt6ct/qt6ct.conf".text = ''
      [Appearance]
      icon_theme=Tela-dark
    '';
  };
}
