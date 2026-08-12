# home/linux/Desktop/fcitx5.nix — Fcitx5 + Rime 雾凇拼音
#
# 参考：NixOS Wiki + 用户提供的 Arch 文档
#
# 架构说明：
#   - fcitx5-rime: Rime 引擎 addon（默认含 rime-data）
#   - rime-ice: 雾凇拼音数据包（通过 override 注入）
#   - default.yaml: 直接嵌入 rime-ice 的 suggestion.yaml 内容
#   - default.custom.yaml: 用户自定义补丁
{ config, lib, pkgs, ... }:
let
  cfg = config.modules-home-linux-desktop-fcitx5;

  # 万象语法模型
  wanxiang-gram = pkgs.fetchurl {
    url = "https://github.com/amzxyz/RIME-LMDG/releases/download/LTS/wanxiang-lts-zh-hans.gram";
    hash = "sha256-kNI4X2Uzf4uMexuly+h03z8tkbRi1o+i+f6QxXqjvGY=";
  };
in
{
  options.modules-home-linux-desktop-fcitx5 = {
    enable = lib.mkEnableOption "Fcitx5 + Rime 雾凇拼音";
  };

  config = lib.mkIf cfg.enable {
    # ==================== Fcitx5 框架 ====================
    # 参考 NixOS Wiki：fcitx5.addons 中加入 fcitx5-rime + rime-ice 数据
    i18n.inputMethod = {
      enabled = "fcitx5";
      fcitx5.waylandFrontend = true;
      fcitx5.addons = with pkgs; [
        (fcitx5-rime.override {
          rimeDataPkgs = [ rime-data rime-ice ];
        })
        fcitx5-rime
        fcitx5-gtk
        fcitx5-material-color  # 主题（来自 nixpkgs）
      ];
    };

    # ==================== 环境变量 ====================
    home.sessionVariables = {
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
      SDL_IM_MODULE = "fcitx";
    };

    # ==================== Rime 数据 ====================
    home.file = {
      # 万象语法模型
      ".local/share/fcitx5/rime/wanxiang-lts-zh-hans.gram".source = wanxiang-gram;

      # 🌟 直接嵌入 rime-ice 的 suggestion.yaml 作为 default.yaml
      ".local/share/fcitx5/rime/default.yaml".text =
        builtins.readFile "${pkgs.rime-ice}/share/rime-data/rime_ice_suggestion.yaml";

      # 用户自定义补丁
      ".local/share/fcitx5/rime/default.custom.yaml".text = ''
        patch:
          "schema_list/@after 0": __delete
          alternative_select_labels: [ ①, ②, ③, ④, ⑤, ⑥, ⑦, ⑧, ⑨, ⑩ ]
          "menu/page_size": 9
          "ascii_composer/switch_key/Shift_L": commit_code
          "ascii_composer/switch_key/Shift_R": commit_code
      '';

      # 万象语法模型配置
      ".local/share/fcitx5/rime/rime_ice.custom.yaml".text = ''
        patch:
          grammar:
            language: wanxiang-lts-zh-hans
            collocation_max_length: 5
            collocation_min_length: 2
            collocation_penalty: -10
            non_collocation_penalty: -17
            weak_collocation_penalty: -24
            rear_penalty: -18
          translator/contextual_suggestions: false
          translator/max_homophones: 7
          translator/max_homographs: 7
      '';
    };

    # ==================== Fcitx5 配置 ====================
    xdg.configFile = {
      "fcitx5/conf/classicui.conf".text = ''
        Theme=Material-Color-Pink
        Font="霞鹜文楷等宽 屏幕阅读版 14"
        MenuFont="OPPO Sans 4.0 14"
        TrayFont="OPPO Sans 4.0 14"
      '';

      "fcitx5/config".text = ''
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

      "fcitx5/profile".text = ''
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
    };

    # 清理 rime 自动生成的 installation.yaml
    home.activation.removeRimeInstallation = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      rm -f ${config.home.homeDirectory}/.local/share/fcitx5/rime/installation.yaml
    '';
  };
}
