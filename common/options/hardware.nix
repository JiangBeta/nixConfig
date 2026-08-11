# common/options/hardware.nix — 硬件级 Option 声明
{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.mySystem = {
    # 目标安装磁盘
    diskDevice = mkOption {
      type = types.str;
      default = "/dev/sda";
      example = "/dev/nvme0n1";
      description = "目标安装磁盘路径";
    };

    # CPU 微码类型（ARM 架构无独立微码包，设为 none）
    cpuMicrocode = mkOption {
      type = types.enum [ "intel" "amd" "none" ];
      default = "none";
      description = "CPU 微码类型：intel / amd / none";
    };

    hardware = {
      # SWAP 与休眠
      swap = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "是否启用 SWAP";
        };
        size = mkOption {
          type = types.str;
          default = "16G";
          example = "32G";
          description = "SWAP 大小（如开启休眠，需大于等于物理内存）";
        };
        enableHibernation = mkOption {
          type = types.bool;
          default = false;
          description = "是否允许休眠到 SWAP（Suspend-to-Disk）";
        };
      };

      # Btrfs 快照
      btrfs = {
        enableSnapper = mkOption {
          type = types.bool;
          default = true;
          description = "是否启用 Btrfs 快照，关闭时不创建 @snapper 相关子卷与软链接";
        };
      };
    };
  };
}
