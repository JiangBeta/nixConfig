# home/linux/Desktop/fcitx5.nix — Fcitx5 + Rime 雾凇拼音
#
# 参考：用户提供的 Arch 安装文档
{ config, lib, pkgs, ... }:
let
  cfg = config.modules-home-linux-desktop-fcitx5;

  # macOS 风格主题（不在 nixpkgs 中）
  fcitx5-theme = pkgs.fetchFromGitHub {
    owner = "witt-bit";
    repo = "fcitx5-theme-macos12";
    rev = "master";
    hash = "sha256-H0X3+/mJ8KH73cZhv3ilNz77CBviQma4D2cKQ/iNiVM=";
  };

  # 万象语法模型（不在 nixpkgs 中）
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
    i18n.inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; [
        (fcitx5-rime.override {
          rimeDataPkgs = [ rime-data rime-ice ];
        })
        qt6Packages.fcitx5-configtool
        fcitx5-gtk
      ];
    };

    # ==================== 环境变量 ====================
    home.sessionVariables = {
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
      SDL_IM_MODULE = "fcitx";
    };

    # ==================== Rime 数据与配置 ====================
    home.file = {
      # 万象语法模型
      ".local/share/fcitx5/rime/wanxiang-lts-zh-hans.gram".source = wanxiang-gram;

      # 雾凇拼音方案（从 nixpkgs rime-ice 直接 symlink）
      ".local/share/fcitx5/rime/rime_ice_suggestion.yaml".source =
        "${pkgs.rime-ice}/share/rime-data/rime_ice_suggestion.yaml";
      ".local/share/fcitx5/rime/rime_ice.dict.yaml".source =
        "${pkgs.rime-ice}/share/rime-data/rime_ice.dict.yaml";
      ".local/share/fcitx5/rime/rime_ice.schema.yaml".source =
        "${pkgs.rime-ice}/share/rime-data/rime_ice.schema.yaml";

      # 默认方案（雾凇拼音 + 小鹤双拼）
      ".local/share/fcitx5/rime/default.custom.yaml".text = ''
        patch:
          schema_list:
            - schema: double_pinyin_flypy
            - schema: rime_ice
          __include: rime_ice_suggestion:/
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
      # 外观配置
      "fcitx5/conf/classicui.conf".text = ''
        Theme=macos12-dark
        DarkTheme=macos12-dark
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

    # ==================== 主题 ====================
    home.file.".local/share/fcitx5/themes/macos12-dark".source =
      "${fcitx5-theme}/macos12-dark";

    # GTK IM + 环境变量 — 由 home.sessionVariables 和 gtk.enable 处理
  };
}
