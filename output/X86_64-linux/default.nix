# output/x86_64-linux/default.nix — NixOS 主机构建（含 Home Manager + 桌面）
inputs:

let
  # 每台 x86_64 桌面主机的公共模块列表，仅最后一步主机参数（hosts/<host>）不同。
  # DRY：pro13 / nuc8-d 复用同一套系统 + 桌面 + HM 模块，主机差异收敛到 hosts/ 目录。
  mkHost = host: inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      # 1. 全局 Custom Options
      ../../common/options

      # 2. 全局数据
      ../../vars
    ]
    # 条件导入 API token（gitignored，不存在时跳过）
    ++ (if builtins.pathExists ../../vars/tokens.nix then [ ../../vars/tokens.nix ] else [ ])
    ++ [
      # 3. 系统模块（跨平台 base + Linux core）
      ../../modules/base
      ../../modules/linux/core
      {
        # 系统级 AI 支持（Node.js 供 MCP 服务器等使用）
        modules-base-ai-claudeCode.enable = true;
      }

      # 4. 桌面系统模块（Linux gui）
      ../../modules/linux/gui
      {
        modules-nixos-gui-ly.enable = true;
        modules-nixos-gui-niri.enable = true;
        modules-nixos-gui-noctalia.enable = true;
      }

      # 5. Zen Browser（Wayland 原生 text-input-v3 / waylandim 前端，勿注入 GTK_IM_MODULE）
      ({ pkgs, ... }: {
        environment.systemPackages = [
          inputs.zen-browser.packages.x86_64-linux.default
        ];
      })

      # 7. Disko
      inputs.disko.nixosModules.disko

      # 8. agenix — Secret 解密
      inputs.agenix.nixosModules.age
      ../../common/secrets

      # 9. Home Manager
      inputs.home-manager.nixosModules.home-manager
      ({ config, ... }: {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          # 将 flake inputs 传入 HM 子模块
          extraSpecialArgs = {
            inherit (inputs) niri noctalia catppuccin;
            # agenix 解密路径（供 AI 模块注入 token、SSH 模块部署密钥）
            # ⚠️ 仅当对应 .age 文件存在时才有效
            aiTokensPath = config.age.secrets."ai-tokens".path or null;
            sshKeyPath = config.age.secrets."ssh-key".path or null;
          };
          users.${config.mySystem.user} = {
            imports = [ (import ../../home/linux) ];
            programs.git.userName = config.myHome.userFullName;
            programs.git.userEmail = config.myHome.userEmail;
          };
        };
      })

      # 10. 主机参数
      ../../hosts/${host}
    ];
  };
in
{
  pro13 = mkHost "pro13";
  nuc8-d = mkHost "nuc8-d";
}
