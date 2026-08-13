# common/hosts-info.nix
{
  hosts = {
    pro13 = {
      ip = "192.168.1.10";
      sshPort = 2222;
      architecture = "x86_64-linux";
      mainDisk = "/dev/nvme0n1";
    };
    host-b = {
      ip = "192.168.1.11";
      sshPort = 22;
      architecture = "x86_64-linux";
      mainDisk = "/dev/nvme0n1";
    };
    nuc8-d = {
      ip = "192.168.1.12"; # ⚠️ 待按实际网络分配
      sshPort = 22;
      architecture = "x86_64-linux";
      mainDisk = "/dev/nvme0n1";
    };
  };
}
