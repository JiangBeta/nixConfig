# home/linux/Desktop/xdg.nix — XDG 桌面集成（用户级）
{ config, lib, pkgs, ... }:
let
  cfg = config.modules-home-linux-desktop-xdg;
in
{
  options.modules-home-linux-desktop-xdg = {
    enable = lib.mkEnableOption "XDG 桌面集成";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      xdg-utils
      xdg-user-dirs
    ];

    xdg = {
      enable = true;
      userDirs = {
        enable = true;
        createDirectories = true;
        setSessionVariables = true;
      };
    };
  };
}
