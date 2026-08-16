# modules/base/gui/sunshine.nix — 远程桌面（Sunshine 服务端 + Moonlight 客户端）
#
# 跨平台远程桌面方案：
#   - Linux（NixOS）：Sunshine 服务端（services.sunshine）+ Moonlight 客户端（moonlight-qt）
#   - macOS：Moonlight 客户端用 moonlight-macos-enhanced（GitHub release .dmg 手动安装，
#     无 Homebrew cask，详见 README.md「远程桌面」）
#
# Sunshine 服务端目前仅 NixOS 声明式管理；macOS 仅作客户端连接。
{ config, lib, pkgs, ... }:

let
  cfg = config.modules-base-gui-sunshine;
in
{
  options.modules-base-gui-sunshine = {
    enable = lib.mkEnableOption "远程桌面（Sunshine 服务端 + Moonlight 客户端）";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    # Sunshine 服务端（Wayland/Niri 下用 KMS 抓屏，需 CAP_SYS_ADMIN）
    services.sunshine = {
      enable = true;
      autoStart = true;      # 开机自启
      capSysAdmin = true;    # DRM/KMS 抓屏权限
      openFirewall = true;   # 开放 Moonlight 流式端口（TCP 47984/47989/48010 + UDP 47998-48010）
    };

    # Sunshine 以 systemd user service 运行（当前登录用户），需加入 uinput 组
    # 才能通过 /dev/uinput 创建虚拟键鼠/手柄（否则报 Permission denied）
    users.users.${config.mySystem.user}.extraGroups = [ "uinput" ];

    # Moonlight 客户端
    environment.systemPackages = with pkgs; [ moonlight-qt ];
  };
}
