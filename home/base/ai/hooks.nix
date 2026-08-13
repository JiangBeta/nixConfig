# home/base/ai/hooks.nix — 共享 Hooks 脚本管理
#
# 统一声明 hooks 脚本目录（跨工具共享的钩子脚本），与 skills.nix 对应。
# 各 AI 工具模块按需 symlink 到各自 hooks 目录：
#   - Claude Code → ~/.claude/hooks/
#
# 使用方式（host 层或 home/linux/default.nix）：
#   modules-home-base-ai-hooks.enable = true;
{ config, lib, pkgs, ... }:

let
  cfg = config.modules-home-base-ai-hooks;
in
{
  options.modules-home-base-ai-hooks = {
    enable = lib.mkEnableOption "共享 Hooks 脚本管理";

    dir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = ./hooks;
      description = "Hooks 脚本目录（所有 AI 工具共享）";
    };
  };

  config = lib.mkIf cfg.enable {
    # hooks 为静态脚本，由各工具模块 symlink 消费。
  };
}
