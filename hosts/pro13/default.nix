# hosts/pro13/default.nix — pro13 主机参数赋值
{ ... }:
{
  imports = [
    ./hardware.nix
    ./networking.nix
  ];

  # 1. 主机身份
  networking.hostName = "pro13";

  # 2. 注入硬件与底层配置参数（触发 common/options 与 modules/linux/ 联动）
  mySystem = {
    user = "beta";
    diskDevice = "/dev/nvme0n1";
    bootMode = "uefi";
    kernel = "zen";
    cpuMicrocode = "intel";
    firewall = "nftables";

    hardware = {
      swap = {
        enable = true;
        size = "16G";
        enableHibernation = true;
      };

      btrfs = {
        enableSnapper = true;
      };
    };
  };
}
