# modules/linux/gui/niri.nix — Niri 系统级服务（polkit + XDG Portal）
{ config, lib, pkgs, ... }:
let
  cfg = config.modules-nixos-gui-niri;
in
{
  options.modules-nixos-gui-niri = {
    enable = lib.mkEnableOption "Niri 窗口管理器（系统级）";
  };

  config = lib.mkIf cfg.enable {
    # Niri 系统服务
    programs.niri.enable = true;

    # Polkit 认证代理
    security.polkit.enable = true;
    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
      };
    };

    # XDG Portal（桌面集成）
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
      ];
      config.common.default = [ "gnome" "gtk" ];
    };

    # 屏幕截图 + 空闲管理工具
    environment.systemPackages = with pkgs; [
      grim      # 截图
      slurp     # 区域选择
      satty     # 截图编辑/标注
      wl-clipboard  # Wayland 剪贴板
      cliphist  # 剪贴板历史
      swayidle  # 空闲管理（关屏/锁屏/挂起）
      xwayland            # Xwayland X 服务器（xwayland-satellite 依赖）
      xwayland-satellite  # Niri 的 Xwayland 桥接（提供 X11 支持）
    ];
  };
}
