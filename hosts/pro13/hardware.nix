# hosts/pro13/hardware.nix — pro13 硬件配置
#
# 此文件由 install.sh 在安装时自动生成（从 nixos-generate-config 输出）。
# fileSystems 和 swapDevices 由 disko 模块管理，生成时自动剔除，
# 避免双重定义冲突。此处仅保留硬件驱动相关信息。
#
# 在未实际安装前，此文件保持为最小骨架：

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # 引导内核模块（安装时 nixos-generate-config 自动填充实际值）
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "usb_storage"
    "sd_mod"
    "rtsx_pci_sdmmc"
  ];

  boot.initrd.kernelModules = [ ];
}
