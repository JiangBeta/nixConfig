# hosts/nuc8-d/default.nix — nuc8-d 主机参数赋值（Intel NUC8 桌面）
#
# 🌟 本文件只做「参数赋值」，不写实现逻辑。
# 用户身份（fullName/email）在 vars/default.nix 中统一管理，此处只指定用户名。
{ ... }:
{
  imports = [
    ./hardware.nix
    ./networking.nix
  ];

  # 1. 主机身份
  networking.hostName = "nuc8-d";

  # 2. 指定用哪个用户 + 硬件参数
  mySystem = {
    user = "beta";               # 🌟 只指定用户名（用户细节在 vars/default.nix）
    diskDevice = "/dev/nvme0n1"; # NUC8 M.2 NVMe（如用 2.5" SATA 盘改为 /dev/sda）
    bootMode = "uefi";
    cpuMicrocode = "intel";
    kernel = "zen";              # install.sh 会按选择改写（zen / lts）
    firewall = "nftables";

    hardware = {
      swap = {
        enable = true;
        size = "20G";
        enableHibernation = true;
      };

      btrfs = {
        enableSnapper = true;
      };
    };
  };
}
