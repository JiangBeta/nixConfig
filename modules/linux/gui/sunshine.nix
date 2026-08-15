# modules/linux/gui/sunshine.nix — 远程桌面（Sunshine 服务端 + Moonlight 客户端）
#
# 所有桌面主机（pro13 / nuc8-d）统一启用，无需按主机区分：
#   - Sunshine：自托管 GameStream 服务端，供 Moonlight 客户端远程连接本机
#   - Moonlight：客户端，从本机连接其他 Sunshine 服务端
{ config, lib, pkgs, ... }:
{
  # Sunshine 服务端（Wayland/Niri 下用 KMS 抓屏，需 CAP_SYS_ADMIN）
  services.sunshine = {
    enable = true;
    autoStart = true;      # 开机自启
    capSysAdmin = true;    # DRM/KMS 抓屏权限
    openFirewall = true;   # 开放 Moonlight 流式端口（TCP 47984/47989/48010 + UDP 47998-48010）
  };

  # Moonlight 客户端
  environment.systemPackages = with pkgs; [
    moonlight-qt
  ];
}
