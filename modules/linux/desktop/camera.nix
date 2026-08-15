# modules/linux/desktop/camera.nix — 内置摄像头驱动与工具
#
# pro13 内置 Chicony UVC 摄像头（04f2:b67c），uvcvideo 驱动开箱即用。
# 此处确保 uvcvideo 模块加载，并安装 v4l-utils 供验证/调试（gaze doctor 亦依赖）。
{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.desktop.camera;
in
{
  config = lib.mkIf cfg.enable {
    # USB 视频类驱动（UVC 摄像头开箱即用；与 hardware.nix 的 boot.kernelModules 合并）
    boot.kernelModules = [ "uvcvideo" ];

    # v4l2-ctl / v4l2-ctl --list-devices 等工具
    environment.systemPackages = with pkgs; [
      v4l-utils
    ];
  };
}
