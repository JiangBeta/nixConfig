# home/base/ai/nodejs.nix — Node.js 运行时（所有 AI 编码工具共享基座）
#
# Claude Code / OpenCode / Codex / Pi 等 AI 工具均依赖 Node.js。
# 此模块提供统一的 Node.js 版本和全局包管理。
{ config, lib, pkgs, ... }:

let
  cfg = config.modules-home-base-ai-nodejs;
in
{
  options.modules-home-base-ai-nodejs = {
    enable = lib.mkEnableOption "Node.js 运行时（AI 工具共享基座）";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nodejs_24;
      description = "Node.js 版本";
    };

    extraNpmPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "额外的全局 npm 包";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ] ++ cfg.extraNpmPackages;
  };
}
