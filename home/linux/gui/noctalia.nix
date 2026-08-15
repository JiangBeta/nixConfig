# home/linux/gui/noctalia.nix — Noctalia Shell
{ config, lib, pkgs, ... }:
let
  cfg = config.modules-home-linux-gui-noctalia;
  dotfile = ../../../common/assets/noctalia;
in
{
  options.modules-home-linux-gui-noctalia = {
    enable = lib.mkEnableOption "Noctalia Shell";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      brightnessctl
      cliphist
    ];

    # Noctalia 配置（来自 dotfile）
    xdg.configFile = {
      "noctalia/obsidian.toml".text = builtins.readFile (dotfile + "/obsidian.toml");
      "noctalia/Obisidian/obsidian.css".text = builtins.readFile (dotfile + "/Obisidian/obsidian.css");
    };
  };
}
