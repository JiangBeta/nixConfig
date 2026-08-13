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
    src = ../../common/assets/fonts/OPPO_Sans_4.0.zip;
    nativeBuildInputs = [ pkgs.unzip ];
    unpackPhase = "unzip $src";
    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      find . \( -name "*.ttf" -o -name "*.otf" \) -exec cp {} $out/share/fonts/truetype/ \;
    '';
  };

  # LXGW WenKai Mono Screen — 霞鹜文楷等宽 屏幕阅读版（fcitx5 候选字/预编辑字体）
  # nixpkgs 的 lxgw-wenkai-screen 只含非等宽版，这里单独 fetch 等宽屏幕版
  lxgw-wenkai-mono-screen = pkgs.stdenvNoCC.mkDerivation {
    pname = "lxgw-wenkai-mono-screen";
    version = "1.522";
    src = pkgs.fetchurl {
      url = "https://github.com/lxgw/LxgwWenKai-Screen/releases/download/v1.522/LXGWWenKaiMonoScreen.ttf";
      sha256 = "dYvw5/zt3q5CX6P1t5KqPoBCiFa5830hNV4OQpUTXp0=";
    };
    dontUnpack = true;
    installPhase = ''
      install -Dm644 "$src" "$out/share/fonts/truetype/LXGWWenKaiMonoScreen.ttf"
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
    lxgw-wenkai-mono-screen
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
