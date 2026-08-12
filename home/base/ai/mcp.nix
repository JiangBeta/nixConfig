# home/base/ai/mcp.nix — 共享 MCP 服务器管理
#
# 统一声明所有 MCP 服务器。各 AI 工具模块（claude_code / opencode / codex）
# 读取此配置，生成各自格式的 MCP 配置文件：
#   - Claude Code → ~/.claude/.mcp.json
#   - OpenCode    → ~/.config/opencode/mcp.json（将来）
#   - Codex       → ~/.config/codex/mcp.json（将来）
#
# 使用方式（在 host 层或 home/linux/default.nix 中设置）：
#   modules-home-base-ai-mcp.servers = {
#     "codebase-memory-mcp" = {
#       command = "/home/beta/.local/bin/codebase-memory-mcp";
#     };
#   };
{ config, lib, pkgs, ... }:

let
  cfg = config.modules-home-base-ai-mcp;
in
{
  options.modules-home-base-ai-mcp = {
    enable = lib.mkEnableOption "共享 MCP 服务器管理";

    servers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          command = lib.mkOption {
            type = lib.types.str;
            example = "/home/beta/.local/bin/codebase-memory-mcp";
            description = "MCP 服务器可执行文件路径（或 Nix 包路径）";
          };
          args = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "命令行参数";
          };
          env = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            description = "环境变量";
          };
        };
      });
      default = { };
      description = "MCP 服务器定义（所有 AI 工具共享同一份配置）";
    };
  };

  config = lib.mkIf cfg.enable {
    # 预留：安装 MCP 服务器 Nix 包
    # home.packages = builtins.attrValues (lib.mapAttrs (name: srv: srv.package) cfg.servers);
  };
}
