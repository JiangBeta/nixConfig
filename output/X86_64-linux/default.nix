# output/x86_64-linux/default.nix — NixOS 主机构建
{ inputs, ... }:

{
  pro13 = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      # 1. 全局 Custom Options 定义
      ../../common/options

      # 2. Linux 通用系统模块
      ../../modules/linux/base.nix
      ../../modules/linux/boot.nix
      ../../modules/linux/btrfs.nix
      ../../modules/linux/disko-template.nix
      ../../modules/base/user.nix
      # ../../modules/linux/docker.nix       # 后续启用

      # 3. Disko 官方模块
      inputs.disko.nixosModules.disko

      # 4. 具体主机声明参数
      ../../hosts/pro13
    ];
  };
}
