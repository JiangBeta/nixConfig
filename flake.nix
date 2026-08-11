# flake.nix — 多主机 NixOS / nix-darwin / home-manager 配置入口
{
  description = "multi-host NixOS / nix-darwin / home-manager configuration";

  inputs = {
    # Nixpkgs 主线（unstable，滚动更新）
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Disko — 声明式磁盘分区
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager — 用户环境管理
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, disko, home-manager, ... }:
    import ./output inputs;
}
