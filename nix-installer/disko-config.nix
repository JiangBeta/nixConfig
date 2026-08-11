# nix-installer/disko-config.nix — pro13 独立 Disko 配置
# 用于 NixOS ISO live 环境：disko --mode disko ./disko-config.nix
#
# 与 modules/linux/disko-template.nix 内容一致，但硬编码 pro13 参数，
# 使其可独立于 NixOS module 系统运行。
{
  disko.devices = {
    disk = {
      main = {
        # ⚠️ 安装时通过 install.sh 替换为实际磁盘设备
        device = "/dev/nvme0n1";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            # --------- UEFI ESP ----------
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

            # --------- SWAP ----------
            swap = {
              size = "16G";
              content = {
                type = "swap";
                randomEncryption = false;
                resumeDevice = true;
              };
            };

            # --------- Btrfs 根分区 ----------
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  # 需要快照的子卷
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" "space_cache=v2" "discard=async" ];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" "noatime" "space_cache=v2" "discard=async" ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" "space_cache=v2" "discard=async" ];
                  };

                  # 不进行快照的子卷
                  "@var_log" = {
                    mountpoint = "/var/log";
                    mountOptions = [ "compress=zstd" "noatime" "space_cache=v2" "discard=async" ];
                  };
                  "@var_cache" = {
                    mountpoint = "/var/cache";
                    mountOptions = [ "compress=zstd" "noatime" "space_cache=v2" "discard=async" ];
                  };
                  "@var_tmp" = {
                    mountpoint = "/var/tmp";
                    mountOptions = [ "compress=zstd" "noatime" "space_cache=v2" "discard=async" ];
                  };
                  "@docker" = {
                    mountpoint = "/var/lib/docker";
                    mountOptions = [ "compress=zstd" "noatime" "space_cache=v2" "discard=async" ];
                  };

                  # 快照子卷
                  "@snapper" = {
                    mountpoint = "/snapper";
                    mountOptions = [ "compress=zstd" "noatime" "space_cache=v2" "discard=async" ];
                  };
                  "@snapper/root_snap" = {
                    mountpoint = "/snapper/root_snap";
                    mountOptions = [ "compress=zstd" "noatime" "space_cache=v2" "discard=async" ];
                  };
                  "@snapper/home_snap" = {
                    mountpoint = "/snapper/home_snap";
                    mountOptions = [ "compress=zstd" "noatime" "space_cache=v2" "discard=async" ];
                  };
                  "@snapper/nix_snap" = {
                    mountpoint = "/snapper/nix_snap";
                    mountOptions = [ "compress=zstd" "noatime" "space_cache=v2" "discard=async" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
