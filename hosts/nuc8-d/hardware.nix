# hosts/nuc8-d/hardware.nix — Intel NUC8 硬件配置模板
#
# ⚠️ 安装时会被 nixos-generate-config 重新生成（nix-installer/install.sh 处理）。
# 此文件提供安装前求值所需的占位配置，参考 Intel NUC8（Coffee Lake-U）：
#   - Intel 无线 AC-9560（iwlwifi）/ I219-V 有线（e1000e）
#   - Iris Plus 655 核显 / Thunderbolt 3（部分型号）
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "sd_mod" "rtsx_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
