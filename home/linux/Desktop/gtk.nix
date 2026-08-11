# home/linux/Desktop/gtk.nix — GTK 主题
{ config, lib, ... }:
let
  cfg = config.modules-home-linux-desktop-gtk;
in
{
  options.modules-home-linux-desktop-gtk = {
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
        name = "Adwaita";
        package = null;
      };
    };
  };
}
