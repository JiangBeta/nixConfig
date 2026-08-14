# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Always reply in Chinese.

## 项目概述

基于 Nix Flakes 的多主机 NixOS / nix-darwin / home-manager 配置仓库（从 Arch Linux 迁移）。

**核心设计理念：DRY 优先**。跨平台通用逻辑上提到 `modules/base/`、`home/base/`；平台专属逻辑下沉到 `modules/linux/`（NixOS）、`modules/darwin/`（macOS）、`home/linux/`、`home/darwin/`。

**⚠️ 当前为搭建初期**：基础骨架已完成，桌面环境和部分模块待补齐，详见下方「当前状态」。

## 主机一览（README 目标）

| 主机 | 系统 | 架构 | 角色 |
|------|------|------|------|
| pro13 | NixOS | x86_64 | 桌面 PC |
| nuc8-d / nuc8-s | NixOS | x86_64 | 桌面 / 服务器 |
| appgateway | NixOS VM | x86_64 | 网关 |
| macmini | macOS (nix-darwin) | aarch64 | AI 服务器 |
| xiaobaonas | armbian (HM standalone) | aarch64 | NAS |

## 常用命令

```bash
nix flake update                          # 更新依赖锁定
nixos-rebuild switch --flake .#pro13      # 构建并切换 NixOS 主机（Home Manager 已由 NixOS 模块集成，一并应用）
darwin-rebuild switch --flake .#macmini   # 构建并切换 nix-darwin 主机
nix flake check                           # 检查 flake 求值
nix fmt                                   # 格式化（需先配置 formatter 才可用）
```

> `flake.nix` 已创建，含 nixpkgs/disko/home-manager/niri/noctalia/catppuccin/zen-browser/agenix inputs。构建前需在 Nix 环境中运行 `nix flake update` 生成 `flake.lock`。

## 架构：Custom Options 作为契约

本仓库的核心模式是 **分层 + 选项驱动**，实现"一份配置、多机复用"：

1. **`common/options/`** —— 自定义 Option 声明层（契约层）。用 `mkOption` 定义 `mySystem.*` / `myHome.*` 全局选项，`default.nix` 统一 imports 汇聚：
   - `user.nix`：`mySystem.user`（默认 `"beta"`）、`myHome.dirs`
   - `system.nix`：`mySystem.bootMode`（`uefi` / `bios`）
   - `hardware.nix`：`mySystem.diskDevice`、`mySystem.hardware.swap.{enable,size,enableHibernation}`、`mySystem.hardware.btrfs.enableSnapper`

2. **`hosts/<hostname>/default.nix`** —— 每台主机**只做参数赋值**，声明 `mySystem = { user, diskDevice, bootMode, hardware = {...} }`，不写实现逻辑（参考 `hosts/pro13/default.nix`：`diskDevice = "/dev/nvme0n1"`、`enableHibernation = true`）。注意实际目录名是小写 `m4macmini`，而非 README 的 `M4MacMini`。

3. **`modules/linux/`** —— 消费选项实现实际配置（典型写法 `cfg = config.mySystem` 后按 `cfg.bootMode` 等条件输出）：
   - `core/boot.nix`：按 `bootMode` 选 systemd-boot(UEFI) / GRUB(BIOS)；按 `hardware.swap` 配置休眠（`resumeDevice`、`vm.swappiness`）
   - `core/disko-template.nix`：按 `bootMode` / `swap` / `enableSnapper` 动态生成 Disko GPT 分区
   - `core/btrfs.nix`：Btrfs autoScrub + Snapper 定时快照与 `.snapshots` 软链接
   - `server/docker.nix`：Docker 支持（待服务器落地）

4. **`output/`** —— Flake outputs 分发层。按架构分目录，每个 `output/<system>/default.nix` 定义该架构下主机的 `nixosSystem`。**实际目录名是 `output/`（单数）**，README 中写的是 `outputs/`。

## 当前状态 (2026-08-15)

### 已完成
- ✅ `flake.nix`：入口已创建（inputs: nixpkgs/unstable, disko, home-manager, niri, noctalia, catppuccin, zen-browser, agenix）
- ✅ `flake.lock`：已通过 `nix flake update` 生成
- ✅ `common/options/*.nix`：user/system/hardware/ai 选项声明
- ✅ `modules/base/`：core(user/fonts) + ai(claude_code，系统级 Node.js 已启用)
- ✅ `modules/linux/core/`：base/boot/btrfs/disko-template（所有 Linux 主机）
- ✅ `modules/linux/gui/`：audio/bluetooth/fcitx5/flatpak/ly/niri/noctalia（桌面）
- ✅ `modules/linux/server/`：docker（占位，待服务器落地）
- ✅ `home/base/`：core(shell/git/cli)/tui(neovim/apps)/gui(kitty/browsers/typora/fcitx5)
- ✅ `home/base/ai/`：nodejs (共享运行时) + mcp (共享 MCP) + skills/hooks (共享) + claude_code (Claude Code 全配置)
- ✅ `home/linux/gui/`：niri/noctalia/fcitx5/gtk/xdg/apps/flatpak-compat
- ✅ `home/linux/default.nix`：Linux HM 聚合入口（含 AI 模块启用）
- ✅ `hosts/pro13/`：default/hardware/networking 全部填充（hardware.nix 已由 `nixos-generate-config` 生成）
- ✅ `hosts/nuc8-d/`：default/hardware/networking（Intel NUC8 桌面，复用 pro13 桌面栈）
- ✅ `output/`：default.nix 入口 + X86_64-linux 分发（集成 agenix + HM）
- ✅ `nix-installer/`：disko 独立配置 + 半自动安装脚本
- ✅ `vars/default.nix`：共享变量（用户名/邮箱）
- ✅ `common/lib/default.nix`：scanPaths 辅助函数（被各类别 default.nix 复用）
- ✅ `common/assets/`：niri 等桌面资产
- ✅ `common/secrets/`：agenix secrets 管理体系（README + default.nix）
- ✅ `secrets/`：加密 secret 目录结构（ai/ssh/creds/api）
- ✅ `.agenix.yaml`：主机 age 公钥注册表（结构已建）

### 待完成
- 🔲 fcitx5 候选框在 Xwayland 应用（微信/WPS）下偏小：候选框是 Wayland 层，Niri 下不随 1.25x 缩放，Xft.dpi/GDK_SCALE 均不影响它；`ForceWaylandDPI` 会导致候选框消失，暂未解决
- 🔲 `secrets/*/*.age`：需用 agenix 加密各 secret（AI tokens, SSH key 等）
- 🔲 `.agenix.yaml`：需填入各主机 age 公钥（当前仅为注释占位）
- 🔲 `common/env.nix`、`common/overlays/`
- 🔲 `modules/darwin/`、`home/darwin/`、`hosts/m4macmini/`（macOS 支持）
- 🔲 `home/base/ai/opencode/`、`home/base/ai/codex/`（其他 AI 工具）

## 规范约定

### 目录分类：平台 × 类别

`<层>/<平台>/<类别>/`：
- 层：`home/`（用户级 HM）、`modules/`（系统级）
- 平台：`base`（跨平台）、`linux`、`darwin`
- 类别：`core`（基础环境）、`tui`（终端应用）、`gui`（图形应用）、`ai`（AI 工具）、`server`（服务器）

规则：`base` 永远 = 跨平台（macOS + Linux 共用）；`core` 永远 = 平台内通用（该平台所有机器都要）。`gui` 仅桌面主机导入、`server` 仅服务器主机导入。每个类别目录的 `default.nix` 用 `common/lib` 的 `scanPaths` 自动收集同目录 `.nix` 子模块。完整目录树见 `README.md`。

### Option 命名体系
- 系统级：`mySystem.bootMode`、`mySystem.firewall`、`mySystem.user`
- 硬件级：`mySystem.diskDevice`、`mySystem.cpuMicrocode`、`mySystem.hardware.swap.*`、`mySystem.hardware.btrfs.*`
- 用户级：`myHome.dirs.enableXDG`、`myHome.dirs.projectsDir`
- 模块级：`modules-<层>-<平台>-<类别>-<名>`
  - HM：`modules-home-<平台>-<类别>-<名>`，如 `modules-home-base-core-shell`、`modules-home-linux-gui-niri`
  - 系统：`modules-nixos-<类别>-<名>`，如 `modules-nixos-gui-niri`（NixOS 即 Linux，省略平台）
- 文件头注释：首行 `# <路径> — <一句话说明>`，如 `# home/base/core/shell.nix — Zsh + Starship + Sheldon + Atuin + Direnv`

### cpuMicrocode 取值
- `"intel"` / `"amd"` / `"none"`（ARM CPU 无独立微码包，用 `"none"`）
- 消费方（boot.nix）按值条件引入 `hardware.cpu.{intel,amd}.updateMicrocode`

### firewall 取值
- `"nftables"` / `"none"`（不用 ufw，用 NixOS 原生 nftables）
- 消费方（networking.nix）按值条件启用 `networking.firewall`

### 文件/目录命名
- `output/`（单数，非 `outputs/`）
- hostname 与目录名一律小写（`pro13`、`m4macmini`）
- Linux 模块：`modules/linux/core/btrfs.nix`（非 `btrfs-snap.nix`）

### 模块消费模式
- 统一 `cfg = config.mySystem`，`hwCfg = cfg.hardware` 后按需引用
- 条件配置用 `lib.mkIf`，条件模块用 `lib.optionalAttrs`

### AI 工具模块（`home/base/ai/`）

层次化共享架构，详见 `modules/base/ai/README.md`：

| 文件 | 角色 | Option 前缀 |
|------|------|-------------|
| `nodejs.nix` | 🔧 共享：Node.js 22 运行时 | `modules-home-base-ai-nodejs` |
| `mcp.nix` | 🔧 共享：MCP 服务器声明 | `modules-home-base-ai-mcp` |
| `skills.nix` | 🔧 共享：Skills 目录（SKILL.md） | `modules-home-base-ai-skills` |
| `hooks.nix` | 🔧 共享：Hooks 脚本目录 | `modules-home-base-ai-hooks` |
| `claude_code/default.nix` | 🎯 专属：Claude Code 全配置 | `modules-home-base-ai-claudeCode` |

设计原则：Node.js、MCP、Skills、Hooks 是所有 AI 工具的共享基础设施，各工具模块消费同一份 `mcp.servers` / `skills.dir` / `hooks.dir` 生成各自格式的配置文件。

### Secrets 管理（`common/secrets/` + `secrets/`）

- 工具：agenix + age 加密
- 加密的 `.age` 文件安全提交 git，解密到 `/run/agenix/`（tmpfs）
- Secret 分类：`secrets/ai/` (AI tokens) | `secrets/ssh/` (SSH 私钥) | `secrets/creds/` (密码) | `secrets/api/` (API key)
- 主机密钥注册：`.agenix.yaml`
- 过渡期仍可用 `vars/tokens.nix`（gitignored），目标迁移到 agenix
- 详细文档：`common/secrets/README.md`

## Fcitx5 输入法

**核心**：Niri（Wayland）下启用 fcitx5 的 waylandim 前端（`text-input-v3`），由 fcitx5 服务端渲染候选框。**切勿设置 `GTK_IM_MODULE` 环境变量**，否则 GTK/Gecko 应用（如 Zen Browser）退回 D-Bus 经典前端，候选框主题失效。

### 配置分层
- `home/base/gui/fcitx5.nix`（跨平台）：Rime 雾凇拼音（仅小鹤双拼 `double_pinyin_flypy`）+ macos12-dark 主题 + `classicui.conf`（候选字/预编辑字体 = `霞鹜文楷等宽 屏幕阅读版`（LXGW WenKai Mono Screen），带圈候选编号 ①-⑨）。
- `home/linux/gui/fcitx5.nix`（Linux 专属）：`i18n.inputMethod`（waylandFrontend + rime/gtk addons）+ session 环境变量。
- `modules/linux/gui/fcitx5.nix`（系统级）：`i18n.inputMethod`（waylandFrontend + `fcitx5-gtk`）注册 GTK2/3 IM 模块。
- `common/assets/niri/miscellaneous.kdl`：`spawn-at-startup "fcitx5" "--enable=waylandim"` 启用 waylandim。

### Qt 与 GTK 应用的不同配置
- **GTK**：不设 `GTK_IM_MODULE`；Xwayland 的 GTK3 应用用 `gtk-3.0/settings.ini` 的 `gtk-im-module=fcitx`；原生 Wayland 的 GTK4 应用自动走 `text-input-v3`。
- **Qt**：`QT_IM_MODULE=fcitx`（Qt5/Xwayland）+ `QT_IM_MODULES=wayland;fcitx`（Qt6 优先 wayland 协议）。
- **其他 Xwayland**：`XMODIFIERS=@im=fcitx`。

## 数据与组件约定

- `common/hosts-info.nix`：静态主机元数据映射表（IP、SSH 端口、架构、系统盘）。
- 桌面栈：Niri + Noctalia Shell + Ly + Kitty + Fcitx5/Rime；CLI：Zsh + Starship + Sheldon + Atuin；磁盘：btrfs + disko + Snapper；内核：linux-zen。
- Flatpak：系统级声明式安装 Flathub 应用（微信/Telegram/Discord/Obsidian/Foliate/WPS/Edge + Flatseal/Bazaar/Warehouse/Gear Lever），USTC 镜像加速，注入 `GDK_SCALE/GDK_DPI_SCALE/QT_SCALE_FACTOR=1.25` 缩放 + Electron ozone/沙盒兼容（`modules/linux/gui/flatpak.nix`）。
- 桌面应用：Typora（跨平台，`home/base/gui/typora.nix`）；ZedG 汉化编辑器 + Navop 工作台（预编译二进制，`home/linux/gui/apps.nix`）。
- X11 兼容：xwayland-satellite（Niri 的 Xwayland 桥接，微信/WPS 等 X11-only 应用依赖）。
- 音频：PipeWire + WirePlumber（sof-firmware / alsa-ucm-conf / alsa-firmware）；电源：power-profiles-daemon（balanced）。空闲/锁屏/挂起与壁纸由 Noctalia Shell 控制。
- 详细组件矩阵与 CLI/TUI 选型见 `COMPONENTS.md`。
