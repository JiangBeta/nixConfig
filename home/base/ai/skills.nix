# home/base/ai/skills.nix — 共享 Skills 管理
#
# 统一声明 skills 目录（跨工具共享的 SKILL.md 技能文件），与 mcp.nix 对应。
# 各 AI 工具模块（claude_code / opencode / codex）读取此配置，
# 按需 symlink 到各自格式的 skills 目录：
#   - Claude Code → ~/.claude/skills/
#   - OpenCode    → ~/.config/opencode/skills/（将来）
#   - Codex       → ~/.config/codex/skills/（将来）
#
# 使用方式（host 层或 home/linux/default.nix）：
#   modules-home-base-ai-skills.enable = true;
{ config, lib, pkgs, ... }:

let
  cfg = config.modules-home-base-ai-skills;
in
{
  options.modules-home-base-ai-skills = {
    enable = lib.mkEnableOption "共享 Skills 管理";

    dir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = ./skills;
      description = "Skills 目录（SKILL.md + agents/references，所有 AI 工具共享）";
    };
  };

  config = lib.mkIf cfg.enable {
    # skills 为静态文件，由各工具模块通过 home.file symlink 消费，此处无系统级副作用。
  };
}
