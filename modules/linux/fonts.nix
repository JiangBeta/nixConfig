# modules/linux/fonts.nix — 系统字体安装与 fontconfig 配置
#
# 参考：
#   - dotfile/config/fontconfig/fonts.conf（渲染设置 + 字体族优先级）
#   - COMPONENTS.md 字体选型
{ config, pkgs, lib, ... }:

let
  # OPPO Sans V4 — 不在 nixpkgs 中，需要从 OPPO 官网下载
  # 首次构建会报错并显示正确的 sha256，替换后重新构建
  oppo-sans = pkgs.stdenvNoCC.mkDerivation {
    pname = "oppo-sans";
    version = "4.0";
    src = pkgs.fetchzip {
      url = "https://coloros-website-cn.allawnfs.com/font/OPPO_Sans_4.0.zip";
      sha256 = "0000000000000000000000000000000000000000000000000000"; # ⚠️ 首次构建后替换为正确值
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
    # Noto 家族（Noto Sans / Serif / Mono / CJK）
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-emoji

    # 霞鹜文楷（屏幕优化版）
    lxgw-wenkai-screen
    # 霞鹜新致宋（如不在 nixpkgs 则需类似 oppo-sans 自定义）
    # lxgw-neozhisong

    # Maple Mono NF CN（编程等宽字体）
    maple-mono-NF-CN

    # OPPO Sans V4（自定义 derivation）
    oppo-sans
  ];

  # ==================== Fontconfig 配置 ====================
  fonts.fontconfig = {
    enable = true;

    # 抗锯齿 + 微调 + 亚像素渲染（对齐 dotfile fonts.conf）
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

  # 字体替换规则（Arial → OPPO Sans，等 fontconfig xml 才能表达的）
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
