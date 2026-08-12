# AI 工具配置 — 设计文档

## 设计理念

**单一真相源 + 分层共享，按工具生成。**

所有 AI 编码工具共享同一份配置真相源（Node.js 运行时、MCP 服务器、供应商/token、skills、hooks、prompts）。每个工具模块只做「翻译」——把共享层数据转成自己的配置格式，不做数据定义。

```
┌────────────────────────────────────────────────────────┐
│                共享基础设施层（真相源）                    │
│  nodejs.nix  ── Node.js 运行时基座                      │
│  mcp.nix     ── MCP 服务器统一声明                       │
│  providers.nix ── 供应商 + token 统一声明（将来）          │
│  prompts.nix  ── CLAUDE.md/AGENTS.md 同步（将来）          │
│  skills/     ── 跨工具共享 skills（SKILL.md + agents）   │
│  hooks/      ── 跨工具共享 hooks 脚本                     │
├──────────────────────┬───────────────────────────────────┤
│   Claude Code        │   OpenCode / Codex（将来）        │
│   ~/.claude/*.json   │   ~/.config/<tool>/*.json         │
│   ← 只做格式翻译     │   ← 只做格式翻译                  │
└──────────────────────┴───────────────────────────────────┘
```

**核心原则**：
1. **数据定义只写一次**（在共享层），工具模块不重复定义
2. **工具模块只做翻译**（共享数据 → 工具专属格式）
3. **声明式优先**：能进 Nix 的绝不交给命令式 GUI 工具管理

---

## 关键决策：CCSwitch 的取舍（2026-08-12）

### 结论：不走 CCSwitch 管理 Nix 已覆盖的部分

CCSwitch（`https://github.com/farion1231/cc-switch`）是 GUI 命令式工具，与 Nix 声明式哲学**根本冲突**：

| 维度 | CCSwitch | Nix/HM |
|------|----------|--------|
| 数据存储 | SQLite（`~/.cc-switch/cc-switch.db`） | Nix store（immutable） |
| 应用方式 | 直接写入目标工具 live 配置 | symlink 只读 |
| 可复现性 | 依赖运行时状态 | 声明式可复现 |

**冲突本质**：HM 管理的文件是只读 symlink，CCSwitch 无法写入；即使写入，下次 `nixos-rebuild switch` 会被覆盖。两者管理同一份文件会**永远打架**。

### CCSwitch 仍有价值的地方

Nix 无法声明式管理 SQLite 运行时状态，CCSwitch 的以下**运行时功能**不可替代：
- 🔄 provider 热切换（不重建）
- 📊 用量/成本追踪
- 🗂 session 浏览/恢复

如需这些，可把 CCSwitch 装进 `home.packages`，但让它管理**独立于 Nix 之外**的部分（本地 proxy、session 浏览），MCP/skills/token 继续由 Nix 声明式管理。

---

## 目录结构

```
home/base/ai/
├── default.nix              ← 聚合：自动扫 .nix + 显式导入子目录模块
├── nodejs.nix               ← 🔧 共享：Node.js 22 运行时
├── mcp.nix                  ← 🔧 共享：MCP 服务器声明 (modules-home-base-ai-mcp)
├── skills/                  ← 🔧 共享：跨工具 skills（从 claude_code/ 上移）
│   ├── codebase-memory/
│   ├── git-master/
│   ├── grill-me/            ← 含 agents/openai.yaml（OpenCode/Codex 格式）
│   ├── grill-with-docs/
│   ├── grilling/
│   ├── smart-search-cli/
│   └── using-superpowers/
├── hooks/                   ← 🔧 共享：跨工具 hooks 脚本（从 claude_code/ 上移）
│   ├── cbm-code-discovery-gate
│   ├── cbm-session-reminder
│   └── cbm-subagent-reminder
├── claude_code/
│   └── default.nix          ← 🎯 Claude Code：消费共享层，生成 settings.json
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

### Skills / Hooks 流（上移后）

```
home/base/ai/skills/ (repo 管理，跨工具共享)
  → claude_code/default.nix 通过 skillsDir (默认 ../skills) symlink
    → ~/.claude/skills/
  → opencode（将来）消费同一份 skills/，生成 ~/.config/opencode/skills/

home/base/ai/hooks/ (repo 管理，跨工具共享)
  → claude_code/default.nix 通过 hooksDir (默认 ../hooks) symlink
    → ~/.claude/hooks/
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
  };

  config = lib.mkIf cfg.enable {
    modules-home-base-ai-nodejs = { enable = true; };

    home.packages = [ cfg.package ];

    # 消费共享 skills（../skills）
    # 消费共享 MCP，生成 OpenCode 格式
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
};
```

### 当前 MCP 服务器

| 名称 | 用途 | macOS 路径 | NixOS 路径 |
|------|------|-----------|-----------|
| `codebase-memory-mcp` | 代码知识图谱 | `/Users/beta/.local/bin/codebase-memory-mcp` | `/home/beta/.local/bin/codebase-memory-mcp` |

> ⚠️ 安装方式：官方脚本 `curl -fsSL .../install.sh | bash`，pro13 上建议 `--skip-config`（只装二进制，配置由 HM 管理）。
> 待办：改用 Nix 声明式安装（`fetchurl` + SHA256）。

---

## Skills 管理策略

### 当前状态

7 个 skill 已上移至 `home/base/ai/skills/`（跨工具共享）。部分 skill 含 `agents/openai.yaml`（OpenCode/Codex 格式 agent 配置）和 `references/`（多工具参考文档）。

| Skill | 用途 | 跨工具标记 |
|-------|------|-----------|
| `codebase-memory` | 代码知识图谱查询 | Claude Code 专属 |
| `git-master` | Git 操作指导 | 通用 |
| `grill-me` | 方案压力测试 | 含 `agents/openai.yaml` |
| `grill-with-docs` | 带文档的压力测试 | 含 `agents/openai.yaml` |
| `grilling` | 压力测试 | 含 `agents/openai.yaml` |
| `smart-search-cli` | CLI 网页搜索 | 含 `agents/openai.yaml` |
| `using-superpowers` | 超级能力使用指引 | 含多工具 references |

### 后续共享策略

1. 通用 skill 内容（纯 Markdown 指令）已在 `ai/skills/` 共享层
2. 各工具模块通过 symlink 消费同一份 skills，按需加工具专属元数据
3. 工具完全专属的 skill 留在各工具的 `skills/` 目录下（如将来出现）

---

## Token 管理

### 现状（搭建期）

```
vars/tokens.nix → gitignored → 明文存储
                → nixos-rebuild --impure (flake 才可见 gitignored 文件)
```

### 迁移路径 → agenix

1. 生成主机 age key：`ssh-keygen -t ed25519 -f ~/.ssh/ai_tokens_key`
2. 用 agenix 加密 token
3. 模块改为读取解密后的文件
4. 移除 `--impure` 标志

---

## 主机差异化

### pro13 (NixOS x86_64)

```nix
# home/linux/default.nix
modules-home-base-ai-nodejs.enable = true;
modules-home-base-ai-mcp = {
  enable = true;
  servers."codebase-memory-mcp".command = "/home/beta/.local/bin/codebase-memory-mcp";
};
modules-home-base-ai-claudeCode.enable = true;
```

### macmini (macOS aarch64, 将来)

```nix
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
    "ENABLE_TOOL_SEARCH": "true"
  },
  "model": "sonnet",
  "hooks": { ... }
}
```

---

## 依赖关系

```
nodejs.nix         ← 无依赖
mcp.nix            ← 无依赖（可选依赖 nodejs）
skills/            ← 无依赖（静态文件）
hooks/             ← 无依赖（静态文件）
claude_code.nix    ← nodejs (auto-enable) + mcp (读 servers) + skills/hooks + osConfig (读 token)
opencode.nix       ← nodejs (auto-enable) + mcp (读 servers) + skills + osConfig (读 token)
```

---

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-08-12 | 初始设计：nodejs + mcp + claude_code 三层架构 |
| | 从 macOS `~/.claude/` 备份 skills/hooks 到 repo |
| | 创建 `vars/tokens.nix`（gitignored）+ `vars/tokens.nix.template` |
| 2026-08-12 | **上移 skills/hooks 到 `ai/` 共享层**（从 `claude_code/` 上移） |
| | 决策：不用 CCSwitch 管理 Nix 已覆盖的部分，走 Nix 声明式 |
| | 确立「单一真相源 + 工具模块只做翻译」原则 |
