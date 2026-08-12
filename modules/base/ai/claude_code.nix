# modules/base/ai/claude_code.nix — 系统级 Claude Code 支持
#
# 目前仅确保 Node.js 在系统级可用（供 MCP 服务器等使用）。
# Claude Code 的安装和配置主要在 home/base/ai/claude_code.nix（HM 层）完成。
#
# 未来可扩展：
#   - 系统级 MCP 服务器（如 codebase-memory-mcp）
#   - 共享的 Node.js 全局包
{ config, lib, pkgs, ... }:

let
  cfg = config.modules-base-ai-claudeCode;
in
{
  options.modules-base-ai-claudeCode = {
    enable = lib.mkEnableOption "系统级 Claude Code 支持（Node.js + MCP 依赖）";

    enableSystemNodejs = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "确保 Node.js 在系统级可用";
    };
  };

  config = lib.mkIf cfg.enable {
    # 系统级 Node.js（供 MCP 服务器等使用）
    environment.systemPackages = lib.mkIf cfg.enableSystemNodejs [ pkgs.nodejs_22 ];
  };
}
