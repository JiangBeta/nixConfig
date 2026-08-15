# common/options/desktop.nix — 桌面硬件级 Option 声明（摄像头 / 人脸识别）
#
# 定义 mySystem.desktop.* 选项树，供:
#   - hosts/<hostname>/ 按主机赋值（pro13 笔记本启用，nuc8-d 桌面不启用）
#   - modules/linux/desktop/* 消费配置
{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.mySystem.desktop = {

    # 内置摄像头（UVC 摄像头开箱即用，需 v4l-utils 调试 + Cheese 应用）
    camera = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "是否启用内置摄像头支持（v4l-utils 工具 + uvcvideo 驱动 + Cheese）";
      };
    };
  };
}
