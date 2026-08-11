# home/linux/Desktop/fcitx5.nix — Fcitx5 输入法 + Rime
#
# 参考：dotfile/config/fcitx5/（Ctrl+Space 切换，rime 默认输入法）
{ config, lib, pkgs, ... }:
let
  cfg = config.modules-home-linux-desktop-fcitx5;
in
{
  options.modules-home-linux-desktop-fcitx5 = {
    enable = lib.mkEnableOption "Fcitx5 中文输入法（Rime）";
  };

  config = lib.mkIf cfg.enable {
    # Fcitx5 输入法框架
    i18n.inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-rime
        fcitx5-configtool
        fcitx5-gtk
      ];
    };

    # 环境变量（Wayland + GTK/Qt 集成）
    home.sessionVariables = {
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
    };

    # Fcitx5 配置（来自 dotfile/config/fcitx5/）
    xdg.configFile."fcitx5/profile".text = ''
      [Groups/0]
      Name=默认
      Default Layout=us
      DefaultIM=rime

      [Groups/0/Items/0]
      Name=keyboard-us
      Layout=

      [Groups/0/Items/1]
      Name=rime
      Layout=

      [GroupOrder]
      0=默认
    '';

    xdg.configFile."fcitx5/config".text = ''
      [Hotkey]
      EnumerateWithTriggerKeys=True
      [Hotkey/TriggerKeys]
      0=Control+space
      [Hotkey/EnumerateGroupForwardKeys]
      0=Super+space
      [Hotkey/EnumerateGroupBackwardKeys]
      0=Shift+Super+space
      [Behavior]
      ActiveByDefault=False
      ShowInputMethodInformation=True
      CompactInputMethodInformation=True
      DefaultPageSize=5
    '';
  };
}
