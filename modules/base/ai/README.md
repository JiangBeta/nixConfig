# AI 工具配置 — 设计文档

## 设计理念

**分层共享，按工具生成。** Node.js 运行时和 MCP 服务器是协议/运行时层面的通用基础设施，所有 AI 编码工具共享；Skills 和 Hooks 按各工具的格式分别管理；各工具模块消费共享配置后，生成各自格式的专属配置文件。

```
┌──────────────────────────────────────────────────┐
│                 Node.js (nodejs.nix)              │  ← 运行时基座
├──────────────────────────────────────────────────┤
│              MCP 服务器 (mcp.nix)                  │  ← 协议层，统一声明
├────────────────────┬──────────────────────────────┤
│   Claude Code      │   OpenCode (将来)             │  ← 各工具消费同一份
│   ~/.claude/.mcp   │   ~/.config/opencode/mcp      │    MCP，生成各自格式
│   .json            │   .json                      │
├────────────────────┼──────────────────────────────┤
│   CC Skills/Hooks  │   OC Skills                  │  ← 工具专属文件
└────────────────────┴──────────────────────────────┘
```

---

## 目录结构

```
home/base/ai/
├── default.nix              ← 聚合：自动扫 .nix + 显式导入子目录模块
├── nodejs.nix               ← 🔧 共享：Node.js 22 运行时
├── mcp.nix                  ← 🔧 共享：MCP 服务器声明 (modules-home-base-ai-mcp)
├── claude_code/
│   ├── default.nix          ← 🎯 Claude Code：消费 mcp + skills + hooks
│   ├── skills/              ← Claude Code 格式 skills (SKILL.md + agents/*.yaml)
│   └── hooks/               ← Claude Code hooks 脚本
├── opencode/                ← 🎯 将来：OpenCode 模块
└── codex/                   ← 🎯 将来：Codex 模块

modules/base/ai/
├── default.nix              ← 系统级聚合（NixOS module）
├── claude_code.nix          ← 系统级 Node.js 支持 (+ 预留 MCP 服务)
└── README.md                ← 本文档

common/options/
├── ai.nix                   ← myHome.ai.* 选项声明 (tokens / defaultProvider)

vars/
├── tokens.nix               ← 💰 API token 定义（gitignored）
└── tokens.nix.template      ← 📋 模板（已提交）
```

---

## 模块命名规范

遵循项目统一模式 `modules-<path-with-hyphens>-<name>`：

| 文件路径 | 选项前缀 |
|----------|----------|
| `home/base/ai/nodejs.nix` | `modules-home-base-ai-nodejs` |
| `home/base/ai/mcp.nix` | `modules-home-base-ai-mcp` |
| `home/base/ai/claude_code/default.nix` | `modules-home-base-ai-claudeCode` |
| `modules/base/ai/claude_code.nix` | `modules-base-ai-claudeCode` |

---

## 数据流

### Token 流

```
vars/tokens.nix (gitignored)
  → 设置 myHome.ai.tokens.* (NixOS 层 option)
    → common/options/ai.nix (声明)
      → output/X86_64-linux (条件导入)
        → home-manager 传入 osConfig
          → claude_code/default.nix 读取 osConfig.myHome.ai.tokens.*
            → 写入 ~/.claude/settings.json (env 字段)
```

### MCP 流

```
mcp.nix → modules-home-base-ai-mcp.servers (统一声明)
  ├── claude_code → ~/.claude/.mcp.json      (Claude Code 格式)
  ├── opencode    → ~/.config/opencode/mcp.json  (将来)
  └── codex       → ~/.config/codex/mcp.json     (将来)
```

### Skills 流

```
claude_code/skills/ (repo 管理)
  → home.file symlink → ~/.claude/skills/
    → settings.json hooks → 触发 skill 加载
```

---

## 添加新 AI 工具（分步指南）

以 OpenCode 为例：

### 1. 创建工具子目录

```bash
mkdir -p home/base/ai/opencode
```

### 2. 编写工具模块 `home/base/ai/opencode/default.nix`

```nix
{ config, lib, pkgs, osConfig ? { }, ... }:

let
  cfg = config.modules-home-base-ai-opencode;
  # 消费共享 MCP
  mcpServers = config.modules-home-base-ai-mcp.servers or { };
  # 消费共享 token
  aiCfg = osConfig.myHome.ai or { };
in
{
  options.modules-home-base-ai-opencode = {
    enable = lib.mkEnableOption "OpenCode";
    package = lib.mkOption { ... };
    # OpenCode 专属选项...
  };

  config = lib.mkIf cfg.enable {
    modules-home-base-ai-nodejs = { enable = true; };

    home.packages = [ cfg.package ];

    # 生成 OpenCode 格式的 MCP 配置
    home.file = {
      ".config/opencode/mcp.json".text =
        builtins.toJSON { servers = ...; };
    };
  };
}
```

### 3. 注册到聚合入口

在 `home/base/ai/default.nix` 的 `imports` 中追加 `./opencode`。

### 4. 在 host 层启用

```nix
modules-home-base-ai-opencode.enable = true;
```

---

## MCP 服务器配置

### 配置位置

MCP 服务器路径与主机绑定（不同机器上二进制路径不同），推荐在 **host 层** 设置：

```nix
# hosts/<hostname>/default.nix 或 home/linux/default.nix
modules-home-base-ai-mcp.servers = {
  "codebase-memory-mcp" = {
    command = "/home/beta/.local/bin/codebase-memory-mcp";
    # 将来可用 Nix 包：
    # command = "${pkgs.codebase-memory-mcp}/bin/codebase-memory-mcp";
  };
  "another-mcp-server" = {
    command = "/path/to/server";
    args = [ "--port" "3000" ];
    env = { DEBUG = "true"; };
  };
};
```

### 当前 MCP 服务器

| 名称 | 用途 | macOS 路径 | NixOS 路径 |
|------|------|-----------|-----------|
| `codebase-memory-mcp` | 代码知识图谱 | `/Users/beta/.local/bin/codebase-memory-mcp` | `/home/beta/.local/bin/codebase-memory-mcp` |

---

## Skills 管理策略

### 当前状态

所有 7 个 skill 均为 Claude Code 格式（`SKILL.md` + 可选 `agents/*.yaml`），位于 `claude_code/skills/`：

| Skill | 用途 |
|-------|------|
| `codebase-memory` | 代码知识图谱查询 |
| `git-master` | Git 操作指导 |
| `grill-me` | 方案压力测试（symlink → ~/.cc-switch） |
| `grill-with-docs` | 带文档的压力测试 |
| `grilling` | 压力测试（symlink → ~/.cc-switch） |
| `smart-search-cli` | CLI 网页搜索 |
| `using-superpowers` | 超级能力使用指引（symlink → ~/.cc-switch） |

### 后续共享策略

当 OpenCode/Codex 也需要 skills 时：
1. 通用 skill 内容（纯 Markdown 指令）提取到 `home/base/ai/skills.d/`
2. 各工具模块 symlink 到各自的 skills 目录，加上工具专属的元数据文件
3. 工具专属 skill 留在各工具的 `skills/` 目录下

---

## Token 管理

### 现状（搭建期）

```
vars/tokens.nix → gitignored → 明文存储
                → nixos-rebuild --impure (flake 才可见 gitignored 文件)
```

### 迁移路径 → agenix

1. 生成主机 age key：`ssh-keygen -t ed25519 -f ~/.ssh/ai_tokens_key`
2. 用 agenix 加密 `vars/tokens.nix`：
   ```nix
   # secrets/tokens.nix.age (加密后的文件，可提交 git)
   age.secrets.ai-tokens = {
     file = ../../secrets/tokens.nix.age;
     owner = "beta";
   };
   ```
3. 模块改为读取解密后的文件
4. 移除 `--impure` 标志

### 环境变量回退（CI / 临时使用）

```nix
# 当 vars/tokens.nix 不存在时，可 fallback 到环境变量
ANTHROPIC_AUTH_TOKEN = 
  if token != "" then token
  else builtins.getEnv "ANTHROPIC_AUTH_TOKEN";
```

---

## 主机差异化

### pro13 (NixOS x86_64)

```nix
# home/linux/default.nix 或 hosts/pro13/default.nix
modules-home-base-ai-nodejs.enable = true;
modules-home-base-ai-mcp = {
  enable = true;
  servers."codebase-memory-mcp".command = "/home/beta/.local/bin/codebase-memory-mcp";
};
modules-home-base-ai-claudeCode.enable = true;
```

### macmini (macOS aarch64, 将来)

```nix
# home/darwin/default.nix (将来)
modules-home-base-ai-nodejs.enable = true;
modules-home-base-ai-mcp = {
  enable = true;
  servers."codebase-memory-mcp".command = "/Users/beta/.local/bin/codebase-memory-mcp";
};
modules-home-base-ai-claudeCode.enable = true;
```

---

## Claude Code settings.json 结构

Nix 模块生成的 `~/.claude/settings.json` 结构：

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "<from vars/tokens.nix>",
    "ANTHROPIC_BASE_URL": "https://api.deepseek.com/anthropic",
    "ANTHROPIC_MODEL": "deepseek-v4-pro[1M]",
    "ANTHROPIC_DEFAULT_FABLE_MODEL": "deepseek-v4-flash[1M]",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "deepseek-v4-flash",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "deepseek-v4-flash[1M]",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "deepseek-v4-flash[1M]",
    "ANTHROPIC_DEFAULT_FABLE_MODEL_NAME": "deepseek-v4-flash",
    "ENABLE_TOOL_SEARCH": "true"
  },
  "model": "sonnet",
  "hooks": { ... }
}
```

### 模型映射说明

- `*_MODEL` — 带上下文窗口后缀 (`[1M]`)，传给 API
- `*_MODEL_NAME` — 不带后缀，用于显示
- Haiku 模型不支持 1M 上下文，不加后缀

---

## 依赖关系

```
nodejs.nix         ← 无依赖
mcp.nix            ← 无依赖（可选依赖 nodejs）
claude_code.nix    ← nodejs (auto-enable) + mcp (读 servers) + osConfig (读 token)
opencode.nix       ← nodejs (auto-enable) + mcp (读 servers) + osConfig (读 token)
```

启用 `modules-home-base-ai-claudeCode.enable = true` 时：
- 自动启用 `modules-home-base-ai-nodejs`
- 读取 `modules-home-base-ai-mcp.servers`（如果 mcp 模块未启用则回退到 `{}`）
- 通过 `osConfig.myHome.ai` 读取 API token

---

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-08-12 | 初始设计：nodejs + mcp + claude_code 三层架构 |
| | 从 macOS `~/.claude/` 备份 skills/hooks 到 repo |
| | 创建 `vars/tokens.nix`（gitignored）+ `vars/tokens.nix.template` |
