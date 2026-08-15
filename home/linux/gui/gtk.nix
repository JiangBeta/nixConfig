# home/linux/gui/gtk.nix — GTK 主题
{ config, lib, pkgs, ... }:
let
  cfg = config.modules-home-linux-gui-gtk;
in
{
  options.modules-home-linux-gui-gtk = {
    enable = lib.mkEnableOption "GTK 主题";
  };

  config = lib.mkIf cfg.enable {
    gtk = {
      enable = true;
      theme = {
        name = "Adwaita-dark";
        package = null;  # 使用系统自带
      };
      iconTheme = {
        name = "Tela-dark";
        package = pkgs.tela-icon-theme;
      };
      gtk3.extraConfig = {
        # Xwayland 的 GTK 应用使用 fcitx（勿设 GTK_IM_MODULE 环境变量）
        "gtk-im-module" = "fcitx";
      };
    };
  };
}
