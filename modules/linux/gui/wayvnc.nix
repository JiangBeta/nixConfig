# modules/linux/gui/wayvnc.nix — Wayland VNC 服务端
#
# 供 VNC 客户端远程查看/控制桌面（画面 + 键鼠）。
# 默认监听 localhost:5900（VNC 明文无加密，远程请走 SSH 隧道，或改监听地址并配密码）。
{ config, lib, pkgs, ... }:
{
  # wayvnc 包（含 wayvncctl 控制工具）
  environment.systemPackages = [ pkgs.wayvnc ];

  # wayvnc 服务端（systemd user service，随图形会话启动）
  systemd.user.services.wayvnc = {
    description = "Wayland VNC server";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.wayvnc}/bin/wayvnc";
      Restart = "on-failure";
      RestartSec = "3s";
    };
  };
}
