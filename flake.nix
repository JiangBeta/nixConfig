# flake.nix — 多主机 NixOS / nix-darwin / home-manager 配置入口
{
  description = "multi-host NixOS / nix-darwin / home-manager configuration";

  # 二进制缓存（避免本地编译大包）
  nixConfig = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Niri — Wayland 合成器
    niri = {
      url = "github:YaLTeR/niri";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Noctalia Shell — 状态栏/启动器/锁屏
    noctalia = {
      url = "github:noctalia-dev/noctalia/cachix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Catppuccin — 统一配色主题
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Zen Browser
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # agenix — Secret 管理（age 加密）
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # pynergy — synergy 协议键鼠共享客户端
    pynergy-client = {
      url = "github:GOKORURI007/pynergy";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # vortex — 服务器管理 TUI（SSH 管理 VPS 集群，agentless）
    vortex = {
      url = "github:berkayyytech/vortex";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, disko, home-manager, niri, noctalia, catppuccin, zen-browser, agenix, pynergy-client, vortex, ... }:
    import ./output inputs;
}
