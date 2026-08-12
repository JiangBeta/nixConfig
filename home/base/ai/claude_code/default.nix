# home/base/ai/claude_code/default.nix — Claude Code CLI 安装与配置
#
# 安装 Claude Code 并生成其专属配置文件：
#   - ~/.claude/settings.json  (API + hooks + 模型映射)
#   - ~/.claude/.mcp.json       (MCP — 消费 modules-home-base-ai-mcp.servers)
#   - ~/.claude/config.json
#   - ~/.claude/skills/         (从 ./skills/ symlink)
#   - ~/.claude/hooks/          (从 ./hooks/ symlink)
#
# Token 消费（两阶段）：
#   Phase 1（当前）：osConfig.myHome.ai.tokens.* → vars/tokens.nix (NixOS option)
#   Phase 2（目标）：aiTokensPath → agenix 解密 → home.activation 注入
#
# 依赖：
#   - modules-home-base-ai-nodejs  — Node.js 运行时
#   - modules-home-base-ai-mcp     — 共享 MCP 服务器定义
{ config, lib, pkgs, osConfig ? { }, aiTokensPath ? null, ... }:

let
  cfg = config.modules-home-base-ai-claudeCode;
  mcpServers = config.modules-home-base-ai-mcp.servers or { };
  aiCfg = osConfig.myHome.ai or { };

  # ---- 根据 provider 确定 API 配置 ----
  providerConfig = {
    anthropic = {
      baseUrl = null;
      token = aiCfg.tokens.anthropic or "";
    };
    deepseek = {
      baseUrl = "https://api.deepseek.com/anthropic";
      token = aiCfg.tokens.deepseek or "";
    };
    openai = {
      baseUrl = "https://api.openai.com/v1";
      token = aiCfg.tokens.openai or "";
    };
  }.${cfg.apiProvider};

  modelEnvVars = builtins.listToAttrs (
    lib.mapAttrsToList (tier: model:
      lib.nameValuePair "ANTHROPIC_DEFAULT_${lib.toUpper tier}_MODEL" model
    ) cfg.modelMapping
  );

  modelNameEnvVars = builtins.listToAttrs (
    lib.mapAttrsToList (tier: name:
      lib.nameValuePair "ANTHROPIC_DEFAULT_${lib.toUpper tier}_MODEL_NAME" name
    ) cfg.modelNameMapping
  );

  # ---- settings.json 结构（en 环境变量，token 用占位符） ----
  settingsEnv = lib.filterAttrs (_: v: v != null && v != "")
    ({
      # Phase 1 直接用 token；Phase 2 用 agenix 注入替换
      ANTHROPIC_AUTH_TOKEN = providerConfig.token;
      ANTHROPIC_MODEL = cfg.model;
      ENABLE_TOOL_SEARCH = if cfg.enableToolSearch then "true" else "false";
    }
    // lib.optionalAttrs (providerConfig.baseUrl != null) {
      ANTHROPIC_BASE_URL = providerConfig.baseUrl;
    }
    // modelEnvVars
    // modelNameEnvVars
    // cfg.extraEnv
    );

  settingsJson = {
    env = settingsEnv;
    model = cfg.claudeModel;
    hooks = cfg.hooks;
  } // lib.optionalAttrs (cfg.extraSettings != { }) cfg.extraSettings;

in
{
  options.modules-home-base-ai-claudeCode = {
    enable = lib.mkEnableOption "Claude Code CLI";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "Claude Code 包。null 时自动选择 nixpkgs nodePackages。";
    };

    apiProvider = lib.mkOption {
      type = lib.types.enum [ "anthropic" "deepseek" "openai" ];
      default = "deepseek";
      description = "API 提供商";
    };

    model = lib.mkOption {
      type = lib.types.str;
      default = "deepseek-v4-pro[1M]";
      description = "主模型（ANTHROPIC_MODEL）";
    };

    claudeModel = lib.mkOption {
      type = lib.types.str;
      default = "sonnet";
      description = "Claude Code 内部模型标签";
    };

    modelMapping = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        fable = "deepseek-v4-flash[1M]";
        haiku = "deepseek-v4-flash";
        opus = "deepseek-v4-flash[1M]";
        sonnet = "deepseek-v4-flash[1M]";
      };
      description = "ANTHROPIC_DEFAULT_*_MODEL 映射（含上下文窗口）";
    };

    modelNameMapping = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        fable = "deepseek-v4-flash";
        haiku = "deepseek-v4-flash";
        opus = "deepseek-v4-flash";
        sonnet = "deepseek-v4-flash";
      };
      description = "ANTHROPIC_DEFAULT_*_MODEL_NAME 映射（不含上下文窗口）";
    };

    enableToolSearch = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "ENABLE_TOOL_SEARCH";
    };

    hooks = lib.mkOption {
      type = lib.types.attrs;
      default = {
        PreToolUse = [
          {
            matcher = "Grep|Glob";
            hooks = [
              {
                type = "command";
                command = "~/.claude/hooks/cbm-code-discovery-gate";
                timeout = 5;
              }
            ];
          }
        ];
        SessionStart = [
          {
            matcher = "startup";
            hooks = [ { type = "command"; command = "~/.claude/hooks/cbm-session-reminder"; } ];
          }
          {
            matcher = "resume";
            hooks = [ { type = "command"; command = "~/.claude/hooks/cbm-session-reminder"; } ];
          }
          {
            matcher = "clear";
            hooks = [ { type = "command"; command = "~/.claude/hooks/cbm-session-reminder"; } ];
          }
          {
            matcher = "compact";
            hooks = [ { type = "command"; command = "~/.claude/hooks/cbm-session-reminder"; } ];
          }
        ];
        SubagentStart = [
          {
            matcher = "*";
            hooks = [ { type = "command"; command = "~/.claude/hooks/cbm-subagent-reminder"; } ];
          }
        ];
      };
      description = "Claude Code hooks 配置";
    };

    skillsDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = ./skills;
      description = "Skills 目录（symlink → ~/.claude/skills/）";
    };

    hooksDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = ./hooks;
      description = "Hooks 脚本目录（symlink → ~/.claude/hooks/）";
    };

    extraEnv = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "额外环境变量";
    };

    extraSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "额外的 settings.json 顶层字段";
    };

    ensureNodejs = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "自动启用 modules-home-base-ai-nodejs";
    };
  };

  # ============================================
  # 配置输出
  # ============================================

  config = lib.mkIf cfg.enable {
    modules-home-base-ai-nodejs = lib.mkIf cfg.ensureNodejs { enable = true; };

    home.packages = [
      (if cfg.package != null then
        cfg.package
      else
        pkgs.nodePackages."@anthropic-ai/claude-code"
        or pkgs.nodePackages.claude-code
        or (builtins.throw "Claude Code 包未找到！请设置 modules-home-base-ai-claudeCode.package。"))
    ];

    home.file = lib.mkMerge [
      { ".claude/settings.json".text = builtins.toJSON settingsJson; }
      {
        ".claude/.mcp.json".text =
          if mcpServers != { }
          then builtins.toJSON { mcpServers = mcpServers; }
          else "{}";
      }
      { ".claude/config.json".text = builtins.toJSON { primaryApiKey = "any"; }; }

      (lib.mkIf (cfg.skillsDir != null) (
        builtins.listToAttrs (
          lib.mapAttrsToList (name: _:
            lib.nameValuePair ".claude/skills/${name}" {
              source = cfg.skillsDir + "/${name}";
              recursive = true;
            }
          ) (lib.filterAttrs (_: type: type == "directory") (builtins.readDir cfg.skillsDir))
        )
      ))

      (lib.mkIf (cfg.hooksDir != null) (
        builtins.listToAttrs (
          lib.mapAttrsToList (name: _:
            lib.nameValuePair ".claude/hooks/${name}" {
              source = cfg.hooksDir + "/${name}";
              executable = true;
            }
          ) (lib.filterAttrs (_: type: type == "regular") (builtins.readDir cfg.hooksDir))
        )
      ))
    ];

    # ---- Phase 2: agenix token 注入 ----
    # 当 agenix 解密文件存在时，用 jq 将真实 token 注入 settings.json。
    # 覆盖 Phase 1 的占位符/symlink，使 token 不入 Nix store。
    home.activation.injectAgenixTokens = lib.mkIf (aiTokensPath != null) (
      lib.hm.dag.entryAfter [ "writeBoundary" ] (
        let
          settingsFile = "${config.home.homeDirectory}/.claude/settings.json";
        in ''
          AGENIX_FILE="${aiTokensPath}"
          if [ -f "$AGENIX_FILE" ]; then
            TOKEN=$(${pkgs.jq}/bin/jq -r '.deepseek // .anthropic // empty' "$AGENIX_FILE")
            if [ -n "$TOKEN" ] && [ -f "${settingsFile}" ]; then
              ${
                pkgs.jq
              }/bin/jq --arg t "$TOKEN" '.env.ANTHROPIC_AUTH_TOKEN = $t' \
                "${settingsFile}" > "${settingsFile}.tmp" \
                && mv "${settingsFile}.tmp" "${settingsFile}"
            fi
          fi
        ''
      )
    );
  };
}
