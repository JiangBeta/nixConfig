# home/linux/Desktop/fcitx5.nix — Fcitx5 + Rime 雾凇拼音
#
# 策略：将所有 rime-ice 文件 + 自定义配置打包到一个 derivation，
# 整个 symlink 到 ~/.local/share/fcitx5/rime/，与 Arch 安装效果一致。
{ config, lib, pkgs, ... }:
let
  cfg = config.modules-home-linux-desktop-fcitx5;

  fcitx5-theme = pkgs.fetchFromGitHub {
    owner = "witt-bit";
    repo = "fcitx5-theme-macos12";
    rev = "master";
    hash = "sha256-H0X3+/mJ8KH73cZhv3ilNz77CBviQma4D2cKQ/iNiVM=";
  };

  wanxiang-gram = pkgs.fetchurl {
    url = "https://github.com/amzxyz/RIME-LMDG/releases/download/LTS/wanxiang-lts-zh-hans.gram";
    hash = "sha256-kNI4X2Uzf4uMexuly+h03z8tkbRi1o+i+f6QxXqjvGY=";
  };

  # 整合 rime-ice 全部文件 + 自定义配置到一个目录
  rime-dir = pkgs.runCommand "rime-user-dir" { } ''
    mkdir -p $out

    # 1. 复制 rime-ice 全部数据文件
    cp -r ${pkgs.rime-ice}/share/rime-data/* $out/

    # 2. default.yaml 就是 rime_ice_suggestion（已在上一步复制）
    #    但 rime 只认 default.yaml，所以创建它
    cp $out/rime_ice_suggestion.yaml $out/default.yaml

    # 3. 万象语法模型
    cp ${wanxiang-gram} $out/

    # 4. 自定义补丁
    cat > $out/default.custom.yaml << 'YAML'
    patch:
      "menu/alternative_select_labels": [ ①, ②, ③, ④, ⑤, ⑥, ⑦, ⑧, ⑨, ⑩ ]
      "menu/page_size": 9
      "ascii_composer/switch_key/Shift_L": commit_code
      "ascii_composer/switch_key/Shift_R": commit_code
    YAML

    cat > $out/rime_ice.custom.yaml << 'YAML'
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
    YAML
  '';
in
{
  options.modules-home-linux-desktop-fcitx5 = {
    enable = lib.mkEnableOption "Fcitx5 + Rime 雾凇拼音";
  };

  config = lib.mkIf cfg.enable {
    i18n.inputMethod = {
      enabled = "fcitx5";
      fcitx5.waylandFrontend = true;
      fcitx5.addons = with pkgs; [
        (fcitx5-rime.override {
          rimeDataPkgs = [ rime-ice ];
        })
        fcitx5-gtk
        fcitx5-rime
        fcitx5-gtk
      ];
    };

    home.sessionVariables = {
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
      SDL_IM_MODULE = "fcitx";
    };

    # 🌟 整个 rime 目录 symlink（所有 rime-ice 文件 + 自定义配置）
    home.file.".local/share/fcitx5/rime" = {
      source = rime-dir;
      recursive = true;
    };

    home.file.".local/share/fcitx5/themes/macos12-dark" = {
      source = "${fcitx5-theme}/macos12-dark";
      recursive = true;
    };

    xdg.configFile = {
      "fcitx5/conf/classicui.conf".text = ''
        Theme=macos12-dark
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

    home.activation.removeRimeInstallation = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      rm -f ${config.home.homeDirectory}/.local/share/fcitx5/rime/installation.yaml
    '';
  };
}
