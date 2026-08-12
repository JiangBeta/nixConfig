# common/options/ai.nix — AI 工具 Option 声明层
#
# 定义 myHome.ai 选项树，供:
#   - vars/tokens.nix  设置 token 值
#   - home/base/ai/*   消费配置
#   - hosts/<hostname>/ 按主机覆盖
{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.myHome.ai = {

    # ---- 默认 API 提供商 ----
    defaultProvider = mkOption {
      type = types.enum [ "anthropic" "deepseek" "openai" ];
      default = "deepseek";
      description = "默认 AI API 提供商（Claude Code / OpenCode 等共用）";
    };

    # ---- API Token 管理 ----
    # ⚠️ 通过 vars/tokens.nix 赋值（gitignored），后续迁移到 agenix
    tokens = {
      anthropic = mkOption {
        type = types.str;
        default = "";
        description = "Anthropic API key (sk-ant-api03-...)";
      };
      deepseek = mkOption {
        type = types.str;
        default = "";
        description = "DeepSeek API key (sk-...)";
      };
      openai = mkOption {
        type = types.str;
        default = "";
        description = "OpenAI API key (sk-proj-...)";
      };
    };

  };
}
