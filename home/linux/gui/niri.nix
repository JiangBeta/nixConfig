# home/linux/gui/niri.nix — Niri 用户配置（直接引用 dotfile KDL 原文）
#
# 参考：dotfile/config/niri/*.kdl + script/
{ config, lib, ... }:
let
  cfg = config.modules-home-linux-gui-niri;
  dotfile = ../../../common/assets/niri;
in
{
  options.modules-home-linux-gui-niri = {
    enable = lib.mkEnableOption "Niri 窗口管理器（用户配置）";
  };

  config = lib.mkIf cfg.enable {
    # Wayland 会话（Ly 需要）
    home.file.".wayland-session".text = ''
      #!/bin/sh
      exec /run/current-system/sw/bin/niri-session
    '';

    xdg.configFile = {
      "niri/config.kdl".text = builtins.readFile (dotfile + "/config.kdl");
      "niri/binds.kdl".text = builtins.readFile (dotfile + "/binds.kdl");
      "niri/input.kdl".text = builtins.readFile (dotfile + "/input.kdl");
      "niri/layout.kdl".text = builtins.readFile (dotfile + "/layout.kdl");
      "niri/miscellaneous.kdl".text = builtins.readFile (dotfile + "/miscellaneous.kdl");
      "niri/output.kdl".text = builtins.readFile (dotfile + "/output.kdl");
      "niri/windows-rule.kdl".text = builtins.readFile (dotfile + "/windows-rule.kdl");
    };

    # Niri 启动脚本（wechat/wps/obsidian/typora/notepadqq/tailscale/idle）
    home.file = {
      ".config/niri/script/notepadqq.sh" = {
        source = dotfile + "/script/notepadqq.sh";
        executable = true;
      };
      ".config/niri/script/obsidian.sh" = {
        source = dotfile + "/script/obsidian.sh";
        executable = true;
      };
      ".config/niri/script/typora.sh" = {
        source = dotfile + "/script/typora.sh";
        executable = true;
      };
      ".config/niri/script/wechat.sh" = {
        source = dotfile + "/script/wechat.sh";
        executable = true;
      };
      ".config/niri/script/wps.sh" = {
        source = dotfile + "/script/wps.sh";
        executable = true;
      };
      ".config/niri/script/tailscale.sh" = {
        source = dotfile + "/script/tailscale.sh";
        executable = true;
      };
      ".config/niri/script/idle.sh" = {
        source = dotfile + "/script/idle.sh";
        executable = true;
      };
    };
  };
}
