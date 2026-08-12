# modules/base/fonts.nix — 跨平台系统字体（NixOS / nix-darwin）
#
# 参考：
#   - dotfile/config/fontconfig/fonts.conf（渲染设置 + 字体族优先级）
#   - COMPONENTS.md 字体选型
#
# 注意：
#   - fonts.fontconfig 配置仅 NixOS 生效，macOS 使用 CoreText
#   - OPPO Sans 本地文件放在 assets/fonts/OPPO_Sans_4.0.zip
{ config, pkgs, lib, ... }:

let
  # LXGW Neo ZhiSong Plus — 不在 nixpkgs 中
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

  # OPPO Sans V4 — 本地文件，避免 403
  oppo-sans = pkgs.stdenvNoCC.mkDerivation {
    pname = "oppo-sans";
    version = "4.0";
    src = ../../assets/fonts/OPPO_Sans_4.0.zip;
    nativeBuildInputs = [ pkgs.unzip ];
    unpackPhase = "unzip $src";
    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      find . \( -name "*.ttf" -o -name "*.otf" \) -exec cp {} $out/share/fonts/truetype/ \;
    '';
  };
in
{
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    lxgw-wenkai-screen
    (maple-mono."NF-CN")
    lxgw-neozhisong
    oppo-sans
  ];

  fonts.fontconfig = {
    enable = true;
    antialias = true;
    hinting.enable = true;
    hinting.style = "medium";
    subpixel.rgba = "rgb";
    defaultFonts = {
      sansSerif = [ "OPPO Sans 4.0" "Noto Sans CJK SC" ];
      serif = [ "LXGW Neo ZhiSong Plus" "Noto Serif CJK SC" ];
      monospace = [ "Maple Mono NF CN" "Noto Sans Mono" ];
    };
  };
}
