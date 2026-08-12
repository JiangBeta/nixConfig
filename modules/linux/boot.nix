# modules/linux/boot.nix — 引导、内核与休眠配置
{ config, pkgs, lib, ... }:

let
  cfg = config.mySystem;
  hwCfg = cfg.hardware;
  isUEFI = cfg.bootMode == "uefi";
in
{
  # 1. 引导加载器
  boot.loader = if isUEFI then {
    # UEFI 模式：systemd-boot，挂载 /efi
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/efi";
    };
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
      consoleMode = "0";  # 80x25 模式 — HiDPI 下字体更大
    };
  } else {
    # Legacy BIOS 模式：GRUB
    grub = {
      enable = true;
      device = cfg.diskDevice;
      configurationLimit = 10;
    };
  };

  # 2. 休眠 (Hibernation)
  boot.resumeDevice = lib.mkIf (hwCfg.swap.enable && hwCfg.swap.enableHibernation)
    "/dev/disk/by-partlabel/disk-main-swap";

  boot.kernel.sysctl = lib.mkIf hwCfg.swap.enable {
    "vm.swappiness" = 10;
  };

  # 3. 内核
  boot.kernelPackages =
    if cfg.kernel == "lts"
    then pkgs.linuxPackages_lts
    else pkgs.linuxPackages_zen;

  # 4. CPU 微码
  hardware.cpu.intel.updateMicrocode = lib.mkIf (cfg.cpuMicrocode == "intel") true;
  hardware.cpu.amd.updateMicrocode = lib.mkIf (cfg.cpuMicrocode == "amd") true;
}
