# modules/base/fonts.nix — 跨平台系统字体（NixOS / nix-darwin）
#
# 参考：
#   - dotfile/config/fontconfig/fonts.conf（渲染设置 + 字体族优先级）
#   - COMPONENTS.md 字体选型
#
# 注意：
#   - fonts.fontconfig 配置仅 NixOS 生效，macOS 使用 CoreText
#   - OPPO Sans 下载链接 403，暂时移除；后续手动下载后恢复
{ config, pkgs, lib, ... }:

let
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
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    lxgw-wenkai-screen
    (maple-mono."NF-CN")
    lxgw-neozhisong
    # oppo-sans — 下载链接 403，后续恢复
  ];

  fonts.fontconfig = {
    enable = true;
    antialias = true;
    hinting.enable = true;
    hinting.style = "medium";
    subpixel.rgba = "rgb";
    defaultFonts = {
      sansSerif = [ "Noto Sans CJK SC" "Noto Sans" ];
      serif = [ "LXGW Neo ZhiSong Plus" "Noto Serif CJK SC" ];
      monospace = [ "Maple Mono NF CN" "Noto Sans Mono" ];
    };
  };
}
