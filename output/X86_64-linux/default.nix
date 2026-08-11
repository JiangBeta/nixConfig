# output/x86_64-linux/default.nix — NixOS 主机构建（含 Home Manager + 桌面）
inputs:

{
  pro13 = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      # 1. 全局 Custom Options
      ../../common/options

      # 2. 全局数据
      ../../vars

      # 3. 系统模块
      ../../modules/linux/base.nix
      ../../modules/linux/boot.nix
      ../../modules/linux/btrfs.nix
      ../../modules/linux/disko-template.nix
      ../../modules/base/fonts.nix
      ../../modules/base/user.nix

      # 4. 桌面系统模块
      ../../modules/linux/desktop/ly.nix
      ../../modules/linux/desktop/niri.nix
      {
        modules-nixos-desktop-ly.enable = true;
        modules-nixos-desktop-niri.enable = true;
      }

      # 5. Disko
      inputs.disko.nixosModules.disko

      # 6. Home Manager
      inputs.home-manager.nixosModules.home-manager
      ({ config, ... }: {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          # 将 flake inputs 传入 HM 子模块（gtk/niri/noctalia 需要）
          extraSpecialArgs = {
            inherit (inputs) niri noctalia catppuccin;
          };
          users.${config.mySystem.user} = {
            imports = [ (import ../../home/linux) ];
            programs.git.userName = config.myHome.userFullName;
            programs.git.userEmail = config.myHome.userEmail;
          };
        };
      })

      # 7. 主机参数
      ../../hosts/pro13
    ];
  };
}
