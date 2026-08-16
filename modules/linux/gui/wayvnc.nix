# modules/linux/gui/wayvnc.nix — Wayland VNC 服务端（接入 wl-uinput-proxy 修复键鼠）
#
# wayvnc 针对 wlroots 合成器；Niri（Smithay）下 virtual-keyboard 输入只发给焦点应用，
# 合成器无法拦截做窗口管理快捷键（Super 组合键失效）。故用 wl-uinput-proxy 前置代理，
# 以 uinput 实现 virtual-input，修复键盘快捷键/滚动（需 /dev/uinput 权限）。
#
# 默认监听 localhost:5900（VNC 明文，远程请走 SSH 隧道）：
#   ssh -L 5900:localhost:5900 beta@pro13   # 然后 VNC 客户端连 localhost:5900
{ config, lib, pkgs, ... }:

let
  # wl-uinput-proxy 未打包进 nixpkgs，从 crates.io 手动打包（0.0.4）
  wl-uinput-proxy = pkgs.rustPlatform.buildRustPackage {
    pname = "wl-uinput-proxy";
    version = "0.0.4";
    src = pkgs.fetchCrate {
      pname = "wl-uinput-proxy";
      version = "0.0.4";
      sha256 = "sha256-6uLTlVfpL1W2bdhY9bzMiI7tRou3T1F65c2GWseDiWI=";
    };
    cargoHash = "sha256-Gtxz99gotvz9LI0mt3L7VUF4W/l6LPs6bvtta4Fs8CY=";
  };
in
{
  # wl-uinput-proxy 需 /dev/uinput 权限（uinput 组）
  hardware.uinput.enable = true;
  users.users.${config.mySystem.user}.extraGroups = [ "uinput" ];

  # wayvnc + wl-uinput-proxy（含 wayvncctl 控制工具）
  environment.systemPackages = [ pkgs.wayvnc wl-uinput-proxy ];

  # wayvnc 服务端（systemd user service，随图形会话启动）
  systemd.user.services.wayvnc = {
    description = "Wayland VNC server";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      # wl-uinput-proxy 前置：uinput 实现 virtual-input，修复 Niri 键盘快捷键
      ExecStart = "${wl-uinput-proxy}/bin/wl-uinput-proxy ${pkgs.wayvnc}/bin/wayvnc";
      Restart = "on-failure";
      RestartSec = "3s";
    };
  };
}
