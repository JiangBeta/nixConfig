# hosts/pro13/hardware.nix — pro13 硬件配置
#
# ⚠️ 此文件在安装时由 nixos-generate-config 生成，请按以下步骤操作：
#
# 1. ISO live 环境中运行 disko 分区并挂载后：
#    nixos-generate-config --root /mnt
#
# 2. 将生成的 /mnt/etc/nixos/hardware-configuration.nix 内容复制到此文件中
#
# 3. 生成的内容包含：
#    - fileSystems（由 disko 创建的分区挂载信息）
#    - boot.initrd.availableKernelModules（硬件驱动模块）
#    - boot.initrd.kernelModules
#    - swapDevices（由 disko 创建的 SWAP 分区）
#
# 在未实际安装前，此文件保持为最小骨架：

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # 引导内核模块（需根据实际硬件调整）
  boot.initrd.availableKernelModules = [
    "xhci_pci"       # USB 3.0
    "nvme"           # NVMe SSD
    "usb_storage"
    "sd_mod"
    "rtsx_pci_sdmmc" # 读卡器
  ];

  boot.initrd.kernelModules = [ ];

  # 文件系统与 SWAP 由 disko 管理，安装时自动生成
  # 此处为空，nixos-generate-config 会填充实际值

  # 示例（安装后替换为实际生成内容）：
  # fileSystems."/" = {
  #   device = "/dev/disk/by-uuid/xxxx";
  #   fsType = "btrfs";
  #   options = [ "subvol=@" "compress=zstd" "noatime" ];
  # };
}
