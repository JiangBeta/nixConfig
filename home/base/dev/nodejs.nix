# home/base/dev/nodejs.nix — Node.js 工具链（nodejs + pnpm + Vue 语言服务）
#
# 项目开发用前端运行环境：
#   - nodejs（默认 nodejs_24） — JavaScript/TypeScript 运行时
#   - pnpm                      — 前端包管理器
#   - vue-language-server       — Vue 的 Volar 语言服务（编辑器用）
#
# ⚠️ 新版 nixpkgs 已移除 nodePackages.*（2026-03），vue-language-server 现为
#    顶层包 pkgs.vue-language-server（Volar），pnpm 也是顶层包 pkgs.pnpm。
{ config, lib, pkgs, ... }:

let
  cfg = config.modules-home-base-dev-nodejs;
in
{
  options.modules-home-base-dev-nodejs = {
    enable = lib.mkEnableOption "Node.js 工具链（nodejs + pnpm + vue-language-server）";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nodejs_24;
      description = "Node.js 版本。默认 pkgs.nodejs_24（与 AI 工具运行时统一，避免 node 冲突）。";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
      pkgs.pnpm                 # 前端包管理器
      pkgs.vue-language-server  # Vue Volar 语言服务
    ];
  };
}
