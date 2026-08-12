# home/linux/Desktop/noctalia.nix — Noctalia Shell
{ config, lib, pkgs, ... }:
let
  cfg = config.modules-home-linux-desktop-noctalia;
  dotfile = ../../../../dotfile/config/noctalia;
in
{
  options.modules-home-linux-desktop-noctalia = {
    enable = lib.mkEnableOption "Noctalia Shell";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      brightnessctl
      cliphist
    ];

    home.sessionVariables = {
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_QPA_PLATFORMTHEME = "qt6ct";
    };

    # Noctalia 配置（来自 dotfile）
    xdg.configFile = {
      "noctalia/obsidian.toml".text = builtins.readFile (dotfile + "/obsidian.toml");
      "noctalia/Obisidian/obsidian.css".text = builtins.readFile (dotfile + "/Obisidian/obsidian.css");
    };
  };
}
