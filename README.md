# nixConfig — Nix Flakes 多主机配置

基于 Nix Flakes 的多主机 NixOS / nix-darwin / home-manager 配置仓库（从 Arch Linux 迁移）。

**设计理念**：DRY 优先。跨平台通用逻辑上提到 `modules/base/`、`home/base/`，平台专属逻辑下沉到 `modules/linux/`、`modules/darwin/`、`home/linux/`、`home/darwin/`。通过 `common/options/` 自定义 Option 层实现"一份配置、多机复用"的参数化契约。

## 目录结构

```
nixConfig/
├── flake.nix                    # Flake 入口（inputs + outputs 分发）
├── common/                      # 数据、契约与工具层
│   ├── options/                 # 自定义 Option 声明（契约层）
│   │   ├── default.nix            # 统一 imports 汇聚
│   │   ├── user.nix               # mySystem.user / myHome.userFullName / myHome.dirs
│   │   ├── system.nix             # mySystem.bootMode / kernel / firewall
│   │   ├── hardware.nix           # mySystem.diskDevice / cpuMicrocode / swap / btrfs
│   │   └── ai.nix                 # myHome.ai.tokens / defaultProvider（AI 工具）
│   ├── hosts-info.nix            # 静态主机元数据映射表（IP、SSH 端口、架构）
│   ├── lib/default.nix           # 辅助函数（scanPaths 等）
│   └── secrets/default.nix       # agenix 密钥占位（待实现）
│
├── modules/                     # 系统级模块（NixOS / nix-darwin）
│   ├── base/                     # 跨平台系统模块
│   │   ├── user.nix                # 用户创建 + sudo（消费 mySystem.user）
│   │   ├── fonts.nix               # 系统字体
│   │   └── ai/                     # AI 工具系统级支持
│   │       ├── default.nix            # 聚合入口
│   │       └── claude_code.nix        # 系统级 Node.js
│   └── linux/                    # NixOS 专属
│       ├── base.nix                # 时区 / Locale / Nix 镜像 / 电源
│       ├── boot.nix                # 引导 + linux-zen 内核 + CPU 微码
│       ├── btrfs.nix               # Btrfs autoScrub + Snapper 快照
│       ├── disko-template.nix      # Disko GPT 分区模板
│       ├── docker.nix              # Docker 支持
│       └── desktop/                # 桌面环境系统服务（server 不需要）
│           ├── audio.nix             # PipeWire + WirePlumber + SOF 固件
│           ├── bluetooth.nix         # bluez + blueman
│           ├── fcitx5.nix            # Fcitx5 系统级 IM 模块注册
│           ├── ly.nix                # Ly 显示管理器
│           ├── niri.nix              # Niri Wayland 合成器 + swayidle 空闲管理
│           └── noctalia.nix          # Noctalia Shell
│
├── home/                        # Home Manager 用户配置
│   ├── base/                     # 跨平台用户模块
│   │   ├── default.nix            # 自动扫描导入 + home.stateVersion = 26.05
│   │   ├── shell.nix              # Zsh + Starship + Sheldon + Atuin + Direnv
│   │   ├── cli.nix                # eza / bat / fzf / ripgrep / fd / zoxide / tmux / btop 等
│   │   ├── git.nix                # Git + Delta + LazyGit + GitHub CLI
│   │   ├── tui.nix                # Yazi / Superfile
│   │   ├── neovim.nix             # Neovim + LazyVim 编辑器
│   │   ├── fcitx5.nix             # Fcitx5 通用配置（Rime 雾凇拼音 + macos12-dark 主题）
│   │   └── ai/                    # AI 编码工具
│   │       ├── default.nix          # 聚合入口（自动导入 .nix + ./claude_code）
│   │       ├── nodejs.nix           # 🔧 共享：Node.js 22（所有 AI 工具运行时基座）
│   │       ├── mcp.nix              # 🔧 共享：MCP 服务器声明（各工具消费）
│   │       ├── skills.nix           # 🔧 共享：Skills 目录声明
│   │       ├── hooks.nix            # 🔧 共享：Hooks 脚本目录声明
│   │       ├── skills/              # 7 个 skill（codebase-memory / git-master 等）
│   │       ├── hooks/               # 3 个 hook（cbm-code-discovery-gate 等）
│   │       └── claude_code/         # 🎯 Claude Code 专属
│   │           └── default.nix        # 安装 + settings.json + .mcp.json（消费共享层）
│   └── linux/                    # Linux 专属用户模块
│       ├── default.nix            # 入口：imports + enable 开关
│       └── Desktop/               # 桌面环境
│           ├── default.nix          # 聚合
│           ├── niri.nix             # Niri 窗口管理器
│           ├── noctalia.nix         # Noctalia Shell（状态栏/启动器/锁屏）
│           ├── kitty.nix            # Kitty 终端（One Dark 配色）
│           ├── fcitx5.nix           # Fcitx5 Linux 专属（IM 前端注册 + 环境变量）
│           ├── browsers.nix         # Zen Browser
│           ├── gtk.nix              # GTK 主题（Adwaita-dark）
│           └── xdg.nix              # XDG 目录 + MIME 关联
│
├── hosts/                       # 主机实例（只做参数赋值）
│   └── pro13/                    # 桌面 PC（x86_64 NixOS）
│       ├── default.nix            # mySystem / myHome 参数赋值
│       ├── hardware.nix           # 硬件配置（nixos-generate-config 生成）
│       └── networking.nix         # 网络 / 防火墙
│
├── output/                      # Flake outputs 分发层
│   ├── default.nix               # 聚合入口（nixosConfigurations / devShells / formatter）
│   └── X86_64-linux/             # x86_64-linux 架构
│       └── default.nix            # pro13 构建 + Home Manager 集成
│
├── vars/                        # 共享变量
│   ├── default.nix               # 用户身份（userFullName / userEmail）
│   ├── tokens.nix                # API token（gitignored，不提交）
│   └── tokens.nix.template       # Token 模板（已提交）
│
├── secrets/                     # agenix 加密密钥（待实现）
├── nix-installer/               # 独立安装脚本 + Disko 配置
├── dotfile/                     # 原始 dotfile 参考（不入库）
├── CLAUDE.md                    # Claude Code 项目指引
└── COMPONENTS.md                # 组件选型矩阵
```

## 主机一览

| 主机 | 系统 | 架构 | 角色 | 状态 |
|------|------|------|------|------|
| pro13 | NixOS | x86_64 | 桌面 PC | ✅ 已配置 |
| nuc8-d | NixOS | x86_64 | 桌面 PC | ✅ 已配置 |
| nuc8-s | NixOS | x86_64 | 服务器 | 🔲 计划中 |
| appgateway | NixOS VM | x86_64 | 网关 | 🔲 计划中 |
| macmini | macOS (nix-darwin) | aarch64 | AI 服务器 | 🔲 计划中 |
| xiaobaonas | armbian (HM standalone) | aarch64 | NAS | 🔲 计划中 |

## 核心架构：Option 驱动

```
common/options/  →  hosts/pro13/   →  modules/ + home/
（声明 Option）     （赋值参数）        （消费生成配置）
```

1. **`common/options/`** — 用 `mkOption` 定义 `mySystem.*` / `myHome.*` 全局选项（契约层）
2. **`hosts/<hostname>/`** — 每台主机只做参数赋值，不写实现逻辑
3. **`modules/` + `home/`** — 按 `cfg = config.mySystem` 模式消费选项，条件生成配置

## AI 工具分层

```
home/base/ai/
├── nodejs.nix     ← 🔧 共享：Node.js 运行时（所有 AI 工具基座）
├── mcp.nix        ← 🔧 共享：MCP 服务器统一定义（各工具按格式消费）
├── skills.nix     ← 🔧 共享：Skills 目录统一定义
├── hooks.nix      ← 🔧 共享：Hooks 脚本目录统一定义
├── claude_code/   ← 🎯 专属：Claude Code CLI + settings（消费共享层）
├── opencode/      ← 🔲 将来
└── codex/         ← 🔲 将来

vars/tokens.nix    ← 💰 共享：所有 AI API token 统一定义（gitignored）
```

## 常用命令

```bash
# 更新依赖
nix flake update

# 构建并切换 NixOS 配置（Home Manager 已由 NixOS 模块集成，一并应用）
sudo nixos-rebuild switch --flake .#pro13

# 检查 flake 求值
nix flake check

# 格式化
nix fmt
```

## Components 选型

| 类型 | 选型 |
|------|------|
| **WM** | Niri（Wayland 合成器） |
| **Shell** | Noctalia Shell（状态栏 / 启动器 / 锁屏） |
| **DM** | Ly（显示管理器） |
| **终端** | Kitty（One Dark 配色 + Maple Mono 字体） |
| **命令行** | Zsh + Starship + Sheldon + Atuin + Direnv |
| **编辑器** | Neovim + LazyVim |
| **输入法** | Fcitx5 + Rime + rime-ice（雾凇拼音）+ macos12-dark 主题 |
| **字体** | 霞鹜文楷等宽 / Maple Mono NF / OPPO Sans 4.0 |
| **浏览器** | Zen Browser |
| **GTK 主题** | Adwaita-dark |
| **内核** | linux-zen |
| **文件系统** | Btrfs + Disko + Snapper（快照） |
| **音频** | PipeWire + WirePlumber（SOF/ALSA 固件） |
| **电源管理** | power-profiles-daemon（balanced） |
| **空闲/休眠** | swayidle（10 分钟关屏+锁屏，20 分钟挂起） |
| **蓝牙** | bluez |
| **网络** | NetworkManager + nftables |

### CLI/TUI 工具

| 功能 | 选型 | 功能 | 选型 |
|------|------|------|------|
| ls | eza | cd | zoxide |
| cat | bat | find | fd |
| grep | ripgrep | 模糊搜索 | fzf |
| Git TUI | lazygit | Git diff | delta |
| 系统监视 | btop | 磁盘分析 | dust |
| 文件管理 | Yazi / Superfile | 系统信息 | fastfetch |
| 命令历史 | Atuin | 环境管理 | Direnv |
| GitHub CLI | gh | 代码高亮 | highlight |
| 终端复用 | tmux | 编辑器 | LazyVim (Neovim) |

## Fcitx5 输入法

> 背景：在 Niri（Wayland）下，若设置 `GTK_IM_MODULE=fcitx`，GTK/Gecko 应用（如 Zen Browser）会走 fcitx5 的 D-Bus 经典前端，候选框渲染异常（主题失效）。正确做法是启用 fcitx5 的 Wayland 输入法前端 `waylandim`（`text-input-v3` 协议），由 fcitx5 服务端统一渲染候选框。

### 系统配置分层

| 层 | 文件 | 职责 |
|----|------|------|
| 跨平台 | `home/base/fcitx5.nix` | Rime 雾凇拼音（仅小鹤双拼）+ macos12-dark 主题 + `fcitx5/config`/`profile`/`classicui.conf`（带圈候选编号 ①-⑨） |
| Linux IM 注册 | `home/linux/Desktop/fcitx5.nix` | `i18n.inputMethod`（`waylandFrontend` + rime/gtk addons）+ session 环境变量 |
| 系统级 | `modules/linux/desktop/fcitx5.nix` | `i18n.inputMethod`（`waylandFrontend` + `fcitx5-gtk`）注册 GTK2/3 IM 模块 |
| 启动 | `common/assets/niri/miscellaneous.kdl` | `spawn-at-startup "fcitx5" "--enable=waylandim"` 启用 waylandim 前端 |

### Qt 与 GTK 应用的不同配置

- **GTK 应用**：**不设 `GTK_IM_MODULE` 环境变量**（Arch Wiki 明确警告，否则退回 D-Bus 经典前端）。Xwayland 的 GTK3 应用改用 `gtk-3.0/settings.ini` 的 `gtk-im-module=fcitx`（见 `home/linux/Desktop/gtk.nix`）；原生 Wayland 的 GTK4 应用自动走 `text-input-v3`。
- **Qt 应用**：保留 `QT_IM_MODULE=fcitx`（Qt5/Xwayland 用 fcitx 插件），另设 `QT_IM_MODULES=wayland;fcitx`（Qt6 优先走 wayland 文本输入协议，回退 fcitx）。
- **其他 Xwayland 应用**：`XMODIFIERS=@im=fcitx`。

## 规范约定

- **目录名**：`output/`（单数）、hostname 一律小写（`pro13`）
- **Option 命名**：系统级 `mySystem.*`、硬件级 `mySystem.hardware.*`、用户级 `myHome.*`、模块级 `modules-<path>-<name>.enable`
- **模块消费模式**：`cfg = config.{mySystem|modules-*}`, `lib.mkIf cfg.enable { ... }`
- **cpuMicrocode**：`"intel"` / `"amd"` / `"none"`（ARM）
- **firewall**：`"nftables"` / `"none"`
- **home.stateVersion**：固定 `"26.05"`，永不修改
