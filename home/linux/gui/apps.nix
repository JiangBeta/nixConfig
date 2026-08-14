# home/linux/gui/apps.nix — Linux 专属桌面应用（zedg / navop）
#
# 两者均为无 nixpkgs 包的上游预编译二进制，故在此用 fetchurl + 打包：
#   - zedg：Zed 编辑器汉化版（x6nux/zed-globalization），动态链接 → autoPatchelf + wrap
#   - navop：一体化数据库/SSH/终端工作台（feigeCode/navop），.AppImage 实为静态 ELF → 直接安装
{ config, lib, pkgs, ... }:
let
  cfg = config.modules-home-linux-gui-apps;

  # ===== zedg：Zed 编辑器汉化版 =====
  # 上游仅发布预编译 tar.gz（无 flake/nix 包），提取后为 FHS 布局：
  #   usr/bin/zedg (436M 主程序) + usr/libexec/zedg (3.6M 启动器) + icons + .desktop
  # 依赖经 autoPatchelfHook 修正；Wayland/Vulkan/GL/fontconfig 等运行时 dlopen 库
  # 通过 makeWrapper 注入 LD_LIBRARY_PATH。
  zedgRuntimeLibs = with pkgs; [
    # DT_NEEDED（ldd 直接依赖）
    alsa-lib
    glib
    libxkbcommon
    libx11
    libxcb
    stdenv.cc.cc.lib       # libstdc++.so.6 / libgcc_s.so.1

    # 运行时 dlopen（Wayland / GPU / 字体）
    wayland
    libGL
    vulkan-loader
    fontconfig
    freetype
    zlib
  ];

  zedg = pkgs.stdenv.mkDerivation {
    pname = "zedg";
    version = "1.15.0";
    src = pkgs.fetchurl {
      url = "https://github.com/x6nux/zed-globalization/releases/download/v1.15.0/zedg-zh-cn-linux-x86_64-v1.15.0.tar.gz";
      hash = "sha256-udeY4fjmWdVKDfQ9CRQiH4tOCl/4VO0eUbCu3K0SFdE=";
    };
    sourceRoot = ".";

    nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.makeWrapper ];
    buildInputs = zedgRuntimeLibs;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin $out/libexec $out/share
      install -Dm755 usr/bin/zedg $out/bin/zedg
      install -Dm755 usr/libexec/zedg $out/libexec/zedg
      cp -r usr/share/icons usr/share/applications $out/share/
      wrapProgram $out/bin/zedg \
        --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath zedgRuntimeLibs}
      wrapProgram $out/libexec/zedg \
        --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath zedgRuntimeLibs}
      runHook postInstall
    '';

    meta = with lib; {
      description = "Zed 编辑器汉化版（globalization / 中文界面）";
      homepage = "https://github.com/x6nux/zed-globalization";
      license = licenses.gpl3Only; # Zed 源码 GPLv3
      platforms = [ "x86_64-linux" ];
      mainProgram = "zedg";
    };
  };

  # ===== navop：一体化工作台（type-2 AppImage，解包 + autoPatchelf） =====
  # .AppImage 实为 type-2 AppImage（魔数 AI\x02），运行时是动态链接 FHS 可执行文件，
  # 直接复制会在 NixOS 上被 stub-ld 拦截（"cannot run dynamically linked executable"）。
  # 用 appimageTools.wrapType2 解包 squashfs 并 autoPatchelf。
  navop = pkgs.appimageTools.wrapType2 {
    pname = "navop";
    version = "0.10.7";
    src = pkgs.fetchurl {
      url = "https://github.com/feigeCode/navop/releases/download/v0.10.7/navop_0.10.7_amd64.AppImage";
      hash = "sha256-hVm8LOOLfbzwZBC97eh947NNui8+QU1PWIaKItJOuCw=";
    };
  };
in
{
  options.modules-home-linux-gui-apps = {
    enable = lib.mkEnableOption "Linux 桌面应用（zedg / navop）";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ zedg navop ];

    # navop 无官方 .desktop，这里补一个启动项
    xdg.desktopEntries.navop = {
      name = "Navop";
      exec = "navop";
      icon = "utilities-terminal";
      comment = "Databases, SSH, SFTP, terminals, remote desktop, monitoring, AI";
      categories = [ "Development" "Utility" "Network" ];
      terminal = false;
    };
  };
}
