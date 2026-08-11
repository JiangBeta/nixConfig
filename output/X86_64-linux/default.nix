# output/x86_64-linux/default.nix — NixOS 主机构建（含 Home Manager）
inputs:

{
  pro13 = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      # 1. 全局 Custom Options 定义
      ../../common/options

      # 2. 🌟 全局数据（用户身份等）— 在 hosts 之前加载
      ../../vars

      # 3. Linux 通用系统模块
      ../../modules/linux/base.nix
      ../../modules/linux/boot.nix
      ../../modules/linux/btrfs.nix
      ../../modules/linux/disko-template.nix
      ../../modules/linux/fonts.nix
      ../../modules/base/user.nix
      # ../../modules/linux/docker.nix       # 后续启用

      # 4. Disko 官方模块
      inputs.disko.nixosModules.disko

      # 5. Home Manager（作为 NixOS module 集成）
      inputs.home-manager.nixosModules.home-manager
      ({ config, ... }: {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${config.mySystem.user} = {
            imports = [ (import ../../home/linux) ];
            # Git 用户身份（从 NixOS config 注入）
            programs.git.userName = config.myHome.userFullName;
            programs.git.userEmail = config.myHome.userEmail;
          };
        };
      })

      # 6. 具体主机声明参数
      ../../hosts/pro13
    ];
  };
}
