# modules/base/fonts.nix — 跨平台系统字体（NixOS / nix-darwin）
#
# 参考：
#   - dotfile/config/fontconfig/fonts.conf（渲染设置 + 字体族优先级）
#   - COMPONENTS.md 字体选型
#
# 注意：fonts.fontconfig 配置仅 NixOS 生效，macOS 使用 CoreText。
{ config, pkgs, lib, ... }:

let
  # OPPO Sans V4 — 不在 nixpkgs 中，从 OPPO 官网下载
  oppo-sans = pkgs.stdenvNoCC.mkDerivation {
    pname = "oppo-sans";
    version = "4.0";
    src = pkgs.fetchzip {
      url = "https://coloros-website-cn.allawnfs.com/font/OPPO_Sans_4.0.zip";
      sha256 = "0000000000000000000000000000000000000000000000000000"; # ⚠️ 首次构建后替换
    };
    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      find . \( -name "*.ttf" -o -name "*.otf" \) -exec cp {} $out/share/fonts/truetype/ \;
    '';
  };

  # LXGW Neo ZhiSong Plus — 不在 nixpkgs 中，从 GitHub 获取
  lxgw-neozhisong = pkgs.stdenvNoCC.mkDerivation {
    pname = "lxgw-neozhisong";
    version = "1.0";
    src = pkgs.fetchzip {
      url = "https://github.com/lxgw/LxgwNeoZhiSong/archive/refs/heads/main.zip";
      sha256 = "cWK8n1hkw6EKnXaprBqj8Ir896nZR5mt7+g4MWUgUI4=";
    };
    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      find . \( -name "*.ttf" -o -name "*.otf" \) -exec cp {} $out/share/fonts/truetype/ \;
    '';
  };
in
{
  # ==================== 字体包安装 ====================
  fonts.packages = with pkgs; [
    # Noto 家族
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji

    # 霞鹜文楷（屏幕优化版）
    lxgw-wenkai-screen

    # Maple Mono NF CN（注意属性名含连字符，需引号）
    (maple-mono."NF-CN")

    # 自定义 derivation（不在 nixpkgs）
    oppo-sans
    lxgw-neozhisong
  ];

  # ==================== Fontconfig 配置 ====================
  fonts.fontconfig = {
    enable = true;

    # 抗锯齿 + Hinting + 亚像素渲染（对齐 dotfile fonts.conf）
    antialias = true;
    hinting.enable = true;
    hinting.style = "medium";
    subpixel.rgba = "rgb";

    # 默认字体族优先级（对齐 dotfile fonts.conf）
    defaultFonts = {
      sansSerif = [ "OPPO Sans 4.0" "Noto Sans" ];
      serif = [ "LXGW Neo ZhiSong Plus" "Noto Serif" ];
      monospace = [ "Maple Mono NF CN" "Noto Sans Mono" ];
    };
  };

  # 字体替换规则（fontconfig XML）
  fonts.fontconfig.localConf = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <!-- Arial → OPPO Sans -->
      <match target="pattern">
        <test name="family" qual="any">
          <string>Arial</string>
        </test>
        <edit name="family" mode="assign">
          <string>OPPO Sans 4.0</string>
        </edit>
      </match>
    </fontconfig>
  '';
}
