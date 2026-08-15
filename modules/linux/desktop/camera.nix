# modules/linux/desktop/camera.nix — 内置摄像头驱动与工具
#
# pro13 内置 Chicony UVC 摄像头（04f2:b67c），uvcvideo 驱动开箱即用。
# 此处确保 uvcvideo 模块加载，并安装 v4l-utils + Cheese 摄像头应用。
{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.desktop.camera;

  # Cheese 依赖 Clutter（GTK3 渲染摄像头预览），其 Wayland 后端在 Niri 上无法初始化。
  # niri 的 common/assets/niri/miscellaneous.kdl 全局强制 GDK/EGL/CLUTTER=wayland，
  # 导致 Cheese 无窗口卡死。此处对 Cheese 单独覆盖为 x11（走 XWayland）修复，
  # 不改动全局环境，避免影响其他 Wayland 原生应用。
  cheese-x11 = pkgs.symlinkJoin {
    name = "cheese-x11";
    paths = [ pkgs.cheese ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      mv "$out/bin/cheese" "$out/bin/.cheese-original"
      makeWrapper "$out/bin/.cheese-original" "$out/bin/cheese" \
        --set GDK_BACKEND x11 \
        --set EGL_PLATFORM x11 \
        --set CLUTTER_BACKEND x11
    '';
  };
in
{
  config = lib.mkIf cfg.enable {
    # USB 视频类驱动（UVC 摄像头开箱即用；与 hardware.nix 的 boot.kernelModules 合并）
    boot.kernelModules = [ "uvcvideo" ];

    # v4l2-ctl 调试工具 + Cheese 摄像头应用（预览/拍照/录像）
    environment.systemPackages = with pkgs; [
      v4l-utils
      cheese-x11
    ];
  };
}
