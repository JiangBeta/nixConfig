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

  # Sunshine 以 systemd user service 运行（当前登录用户），需加入 uinput 组
  # 才能通过 /dev/uinput 创建虚拟键鼠/手柄（否则报 Permission denied）
  users.users.${config.mySystem.user}.extraGroups = [ "uinput" ];

  # Moonlight 客户端
  environment.systemPackages = with pkgs; [
    moonlight-qt
  ];
}
