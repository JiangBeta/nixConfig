# modules/linux/disko-template.nix
{ config, lib, ... }:

let
  cfg = config.mySystem;
  hwCfg = config.mySystem.hardware;
  isUEFI = cfg.bootMode == "uefi";
  enableSnapper = hwCfg.btrfs.enableSnapper;

  # 1. 动态 Boot 分区配置（UEFI 或 BIOS）
  bootPartitions = if isUEFI then {
    # UEFI 模式：/efi, 512M, vfat
    ESP = {
      size = "512M";
      type = "EF00";
      content = {
        type = "filesystem";
        format = "vfat";
        mountpoint = "/efi";
        mountOptions = [ "fmask=0077" "dmask=0077" ];
      };
    };
  } else {
    # Legacy BIOS 模式 (GPT 盘)：需 1M 引导无格式分区 + 1G /boot 分区
    biosboot = {
      size = "1M";
      type = "EF02"; # BIOS boot partition
    };
    boot = {
      size = "1G";
      type = "8300";
      content = {
        type = "filesystem";
        format = "ext4";
        mountpoint = "/boot";
      };
    };
  };

  # 2. SWAP 分区设置
  swapPartition = lib.optionalAttrs hwCfg.swap.enable {
    swap = {
      size = hwCfg.swap.size;
      content = {
        type = "swap";
        randomEncryption = false; # 🌟 开启休眠 (Hibernation) 时绝对不能开启随机加密！
        resumeDevice = true;      # 标记该分区为休眠恢复源
      };
    };
  };

  # 3. Btrfs 通用挂载参数
  defaultBtrfsOptions = [ "compress=zstd" "noatime" "space_cache=v2" "discard=async" ];

  # 4. Btrfs 子卷
  btrfsSubvolumes = {
    # ------- 需要快照的子卷 ----------
    "@"     = { mountpoint = "/";     mountOptions = defaultBtrfsOptions; };
    "@home" = { mountpoint = "/home"; mountOptions = defaultBtrfsOptions; };
    "@nix"  = { mountpoint = "/nix";  mountOptions = defaultBtrfsOptions; };

    # ------- 不进行快照的子卷 ----------
    "@var_log"   = { mountpoint = "/var/log";        mountOptions = defaultBtrfsOptions; };
    "@var_cache" = { mountpoint = "/var/cache";      mountOptions = defaultBtrfsOptions; };
    "@var_tmp"   = { mountpoint = "/var/tmp";        mountOptions = defaultBtrfsOptions; };
    "@docker"    = { mountpoint = "/var/lib/docker"; mountOptions = defaultBtrfsOptions; };
  };

  # 仅当 enableSnapper = true 时才创建的快照子卷
  snapperSubvolumes = lib.optionalAttrs enableSnapper {
    # ------- 存放快照的子卷 ----------
    "@snapper"           = { mountpoint = "/snapper";           mountOptions = defaultBtrfsOptions; };
    "@snapper/root_snap" = { mountpoint = "/snapper/root_snap"; mountOptions = defaultBtrfsOptions; };
    "@snapper/home_snap" = { mountpoint = "/snapper/home_snap"; mountOptions = defaultBtrfsOptions; };
    "@snapper/nix_snap"  = { mountpoint = "/snapper/nix_snap";  mountOptions = defaultBtrfsOptions; };
  };



in
{
  disko.devices = {
    disk = {
      main = {
        device = cfg.diskDevice;
        type = "disk";
        content = {
          type = "gpt";
          partitions = bootPartitions // swapPartition // {
            # 根分区 (Btrfs)
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = btrfsSubvolumes // snapperSubvolumes;
              };
            };
          };
        };
      };
    };
  };
}
