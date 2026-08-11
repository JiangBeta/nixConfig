# home/linux/Desktop/gtk.nix — GTK 主题（Catppuccin）
{ config, lib, catppuccin, ... }:
let
  cfg = config.modules-home-linux-desktop-gtk;
in
{
  imports = [ catppuccin.homeModules.catppuccin ];

  options.modules-home-linux-desktop-gtk = {
    enable = lib.mkEnableOption "GTK 主题（Catppuccin）";
  };

  config = lib.mkIf cfg.enable {
    gtk = {
      enable = true;
      catppuccin = {
        enable = true;
        flavor = "mocha";
        accent = "pink";
        size = "standard";
        tweaks = [ "rimless" ];
      };
    };
  };
}
