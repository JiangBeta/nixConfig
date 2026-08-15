# home/base/ai/opencode/default.nix — OpenCode CLI 安装与配置
#
# 安装 OpenCode 并生成其专属配置文件：
#   - ~/.config/opencode/opencode.json  (provider/model + MCP + 模型映射)
#   - ~/.config/opencode/skills/        (消费 modules-home-base-ai-skills.dir，共享层)
#
# 设计原则（同 claude_code）：工具模块只做「翻译」，把共享层数据转成 OpenCode 格式：
#   - MCP    → modules-home-base-ai-mcp.servers → opencode.json 的 mcp 字段
#   - Skills → modules-home-base-ai-skills.dir  → ~/.config/opencode/skills/（symlink）
#
# Token 消费（两阶段，与 claude_code 一致）：
#   Phase 1（当前）：osConfig.myHome.ai.tokens.* → vars/tokens.nix (NixOS option)
#   Phase 2（目标）：aiTokensPath → agenix 解密 → home.activation 注入
#
# 依赖：
#   - modules-home-base-ai-nodejs  — Node.js 运行时
#   - modules-home-base-ai-mcp     — 共享 MCP 服务器定义
#   - modules-home-base-ai-skills  — 共享 skills 目录
{ config, lib, pkgs, osConfig ? { }, aiTokensPath ? null, ... }:

let
  cfg = config.modules-home-base-ai-opencode;
  # 消费共享 MCP / skills（与 mcp.nix / skills.nix 同层声明）
  mcpServers = config.modules-home-base-ai-mcp.servers or { };
  skillsDir = config.modules-home-base-ai-skills.dir or null;
  aiCfg = osConfig.myHome.ai or { };

  # ---- 共享 MCP → OpenCode 格式 ----
  # mcp.nix 的 command(str) + args(list) → opencode 的 command(list)
  mcpJson = lib.mapAttrs (name: srv: {
    type = "local";
    command = [ srv.command ] ++ srv.args;
    enabled = true;
  } // lib.optionalAttrs (srv.env != { }) { environment = srv.env; }) mcpServers;

  # ---- 根据 provider 确定 OpenCode provider 定义 ----
  # 与 claude_code/default.nix 的 providerConfig 对齐；deepseek 走 anthropic 兼容端点。
  # 空 token 时省略 apiKey（与 claude_code 的 filterAttrs 过滤空值行为一致），让 OpenCode 首次运行时提示。
  providerDef = {
    anthropic = {
      npm = "@ai-sdk/anthropic";
      name = "Anthropic";
      options = lib.optionalAttrs (aiCfg.tokens.anthropic or "" != "") { apiKey = aiCfg.tokens.anthropic or ""; };
    };
    deepseek = {
      npm = "@ai-sdk/anthropic";
      name = "DeepSeek";
      options = {
        baseURL = "https://api.deepseek.com/anthropic";
      } // lib.optionalAttrs (aiCfg.tokens.deepseek or "" != "") { apiKey = aiCfg.tokens.deepseek or ""; };
    };
    openai = {
      npm = "@ai-sdk/openai";
      name = "OpenAI";
      options = lib.optionalAttrs (aiCfg.tokens.openai or "" != "") { apiKey = aiCfg.tokens.openai or ""; };
    };
  }.${cfg.apiProvider};

  providerJson = {
    ${cfg.apiProvider} = {
      npm = providerDef.npm;
      name = providerDef.name;
      options = providerDef.options;
      models = cfg.models;
    };
  };

  opencodeJson = {
    "$schema" = "https://opencode.ai/config.json";
    model = cfg.model;
    small_model = cfg.smallModel;
    provider = providerJson;
  } // lib.optionalAttrs (mcpServers != { }) { mcp = mcpJson; }
    // cfg.extraConfig;

in
{
  options.modules-home-base-ai-opencode = {
    enable = lib.mkEnableOption "OpenCode CLI";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "OpenCode 包。null 时自动使用 pkgs.opencode。";
    };

    apiProvider = lib.mkOption {
      type = lib.types.enum [ "anthropic" "deepseek" "openai" ];
      default = "deepseek";
      description = "API 提供商";
    };

    model = lib.mkOption {
      type = lib.types.str;
      default = "deepseek/deepseek-v4-pro";
      description = "主模型（OpenCode 格式 provider/model）";
    };

    smallModel = lib.mkOption {
      type = lib.types.str;
      default = "deepseek/deepseek-v4-flash";
      description = "小模型（small_model，用于后台任务）";
    };

    models = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = {
        "deepseek-v4-pro" = { name = "DeepSeek V4 Pro"; };
        "deepseek-v4-flash" = { name = "DeepSeek V4 Flash"; };
      };
      description = "provider.models 映射（model-id → 显示名等）";
    };

    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "额外的 opencode.json 顶层字段（覆盖默认值）";
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
        let
          fromTop = builtins.tryEval pkgs.opencode or null;
        in
          if fromTop.success then fromTop.value
          else builtins.throw "OpenCode 包未找到！请设置 modules-home-base-ai-opencode.package。")
    ];

    home.file = lib.mkMerge [
      { ".config/opencode/opencode.json".text = builtins.toJSON opencodeJson; }

      # 消费共享 skills（symlink 每个 skill 目录到 OpenCode skills 目录）
      (lib.mkIf (skillsDir != null) (
        builtins.listToAttrs (
          lib.mapAttrsToList (name: _:
            lib.nameValuePair ".config/opencode/skills/${name}" {
              source = skillsDir + "/${name}";
              recursive = true;
            }
          ) (lib.filterAttrs (_: type: type == "directory") (builtins.readDir skillsDir))
        )
      ))
    ];

    # ---- Phase 2: agenix token 注入 ----
    # 当 agenix 解密文件存在时，用 jq 将真实 token 注入 opencode.json 的 provider options。
    # 覆盖 Phase 1 的明文 token，使 token 不入 Nix store。
    home.activation.injectOpencodeTokens = lib.mkIf (aiTokensPath != null) (
      lib.hm.dag.entryAfter [ "writeBoundary" ] (
        let
          cfgFile = "${config.home.homeDirectory}/.config/opencode/opencode.json";
          keyPath = ".provider.${cfg.apiProvider}.options.apiKey";
        in ''
          AGENIX_FILE="${aiTokensPath}"
          if [ -f "$AGENIX_FILE" ]; then
            TOKEN=$(${pkgs.jq}/bin/jq -r '.deepseek // .anthropic // empty' "$AGENIX_FILE")
            if [ -n "$TOKEN" ] && [ -f "${cfgFile}" ]; then
              ${
                pkgs.jq
              }/bin/jq --arg t "$TOKEN" '${keyPath} = $t' \
                "${cfgFile}" > "${cfgFile}.tmp" \
                && mv "${cfgFile}.tmp" "${cfgFile}"
            fi
          fi
        ''
      )
    );
  };
}
