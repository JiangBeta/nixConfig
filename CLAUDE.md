# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Always reply in Chinese.

## 项目概述

基于 Nix Flakes 的多主机 NixOS / nix-darwin / home-manager 配置仓库（从 Arch Linux 迁移）。

**核心设计理念：DRY 优先**。跨平台通用逻辑上提到 `modules/base/`、`home/base/`；平台专属逻辑下沉到 `modules/linux/`（NixOS）、`modules/darwin/`（macOS）、`home/linux/`、`home/darwin/`。

**⚠️ 当前为搭建初期**：`flake.nix` 为空、无 `flake.lock`、未初始化 git。`home/`、`modules/base/`、`modules/darwin/`、`secrets/`、`vars/`、`nix-installer/` 等目录仅为空占位。README 描述的是目标结构，实际落地仅完成 `common/options/`、`modules/linux/`、`hosts/pro13/`、`output/` 的骨架。

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
nixos-rebuild switch --flake .#pro13      # 构建并切换 NixOS 主机
darwin-rebuild switch --flake .#macmini   # 构建并切换 nix-darwin 主机
home-manager switch --flake .#beta@pro13  # 仅切换 Home Manager
nix flake check                           # 检查 flake 求值
nix fmt                                   # 格式化（需先配置 formatter 才可用）
```

> 由于 `flake.nix` 目前为空，上述构建命令在补齐 flake 入口之前不可用；`nix flake check` 可直接用来验证模块是否可求值。

## 架构：Custom Options 作为契约

本仓库的核心模式是 **分层 + 选项驱动**，实现"一份配置、多机复用"：

1. **`common/options/`** —— 自定义 Option 声明层（契约层）。用 `mkOption` 定义 `mySystem.*` / `myHome.*` 全局选项，`default.nix` 统一 imports 汇聚：
   - `user.nix`：`mySystem.user`（默认 `"beta"`）、`myHome.dirs`
   - `system.nix`：`mySystem.bootMode`（`uefi` / `bios`）
   - `hardware.nix`：`mySystem.diskDevice`、`mySystem.hardware.swap.{enable,size,enableHibernation}`、`mySystem.hardware.btrfs.enableSnapper`

2. **`hosts/<hostname>/default.nix`** —— 每台主机**只做参数赋值**，声明 `mySystem = { user, diskDevice, bootMode, hardware = {...} }`，不写实现逻辑（参考 `hosts/pro13/default.nix`：`diskDevice = "/dev/nvme0n1"`、`enableHibernation = true`）。注意实际目录名是小写 `m4macmini`，而非 README 的 `M4MacMini`。

3. **`modules/linux/*.nix`** —— 消费选项实现实际配置（典型写法 `cfg = config.mySystem` 后按 `cfg.bootMode` 等条件输出）：
   - `boot.nix`：按 `bootMode` 选 systemd-boot(UEFI) / GRUB(BIOS)；按 `hardware.swap` 配置休眠（`resumeDevice`、`vm.swappiness`）
   - `disko-template.nix`：按 `bootMode` / `swap` / `enableSnapper` 动态生成 Disko GPT 分区（UEFI ESP 或 BIOS boot、Btrfs 子卷、`@snapper` 快照子卷）
   - `btrfs-snap.nix`：Btrfs autoScrub + Snapper 定时快照与 `.snapshots` 软链接
   - `docker.nix`：Docker 支持

4. **`output/`** —— Flake outputs 分发层。按架构分目录，每个 `output/<system>/default.nix` 定义该架构下主机的 `nixosSystem`。**实际目录名是 `output/`（单数）**，README 中写的是 `outputs/`。

## 当前状态 (2026-08-11)

### 已完成
- ✅ `flake.nix`：入口已创建（inputs: nixpkgs/unstable, disko, home-manager）
- ✅ `common/options/*.nix`：语法错误全部修复，新增 `cpuMicrocode`、`firewall` option
- ✅ `modules/linux/boot.nix`：linux-zen 内核 + CPU 微码消费
- ✅ `modules/linux/btrfs.nix`：修复 lib 参数缺失并改名（原 `btrfs-snap.nix`）
- ✅ `modules/linux/base.nix`：时区/Locale/Nix镜像/PipeWire/蓝牙/基础包
- ✅ `modules/base/user.nix`：用户创建 + sudo
- ✅ `hosts/pro13/`：default/hardware/networking 全部填充
- ✅ `output/`：default.nix 入口 + X86_64-linux 分发
- ✅ `nix-installer/`：disko 独立配置 + 半自动安装脚本
- ✅ `home/base/`：shell(Zsh+Starship+Sheldon+Atuin)、cli(eza/bat/fzf等)、git(Delta+LazyGit)、tui(Yazi+btop)、neovim
- ✅ `home/linux/default.nix`：Linux HM 聚合入口
- ✅ `vars/default.nix`：共享变量（用户名/邮箱）
- ✅ `common/lib/default.nix`：scanPaths 辅助函数
- ✅ `common/options/user.nix`：新增 `myHome.userFullName` / `myHome.userEmail`
- ✅ `flake.nix`：新增 niri/noctalia/catppuccin inputs
- ✅ `output/X86_64-linux/default.nix`：集成 `home-manager.nixosModules.home-manager`

### 待完成
- 🔲 `flake.lock`：需在 Nix 环境中运行 `nix flake update` 生成
- 🔲 `hosts/pro13/hardware.nix`：需在 ISO live 环境用 `nixos-generate-config` 生成实际内容
- 🔲 桌面环境（`home/linux/Desktop/`）：Niri + Noctalia + Kitty + Fcitx5 + Zen Browser（Phase 4b）
- 🔲 `modules/linux/desktop/`：Ly/greetd、niri 系统服务、字体
- 🔲 `common/` 下 `env.nix`、`overlays/`、`assets/`
- 🔲 `modules/linux/docker.nix`
- 🔲 `modules/darwin/`、`hosts/m4macmini/`、`home/darwin/`
- 🔲 `secrets/`（agenix）

## 规范约定

### Option 命名体系
- 系统级：`mySystem.bootMode`、`mySystem.firewall`、`mySystem.user`
- 硬件级：`mySystem.diskDevice`、`mySystem.cpuMicrocode`、`mySystem.hardware.swap.*`、`mySystem.hardware.btrfs.*`
- 用户级：`myHome.dirs.enableXDG`、`myHome.dirs.projectsDir`

### cpuMicrocode 取值
- `"intel"` / `"amd"` / `"none"`（ARM CPU 无独立微码包，用 `"none"`）
- 消费方（boot.nix）按值条件引入 `hardware.cpu.{intel,amd}.updateMicrocode`

### firewall 取值
- `"nftables"` / `"none"`（不用 ufw，用 NixOS 原生 nftables）
- 消费方（networking.nix）按值条件启用 `networking.firewall`

### 文件/目录命名
- `output/`（单数，非 `outputs/`）
- hostname 与目录名一律小写（`pro13`、`m4macmini`）
- Linux 模块：`modules/linux/btrfs.nix`（非 `btrfs-snap.nix`）

### 模块消费模式
- 统一 `cfg = config.mySystem`，`hwCfg = cfg.hardware` 后按需引用
- 条件配置用 `lib.mkIf`，条件模块用 `lib.optionalAttrs`

## 数据与组件约定

- `common/hosts-info.nix`：静态主机元数据映射表（IP、SSH 端口、架构、系统盘）。
- 桌面栈：Niri + Noctalia Shell + Ly + Kitty + Fcitx5/Rime；CLI：Zsh + Starship + Sheldon + Atuin；磁盘：btrfs + disko + Snapper；内核：linux-zen。
- 详细组件矩阵与 CLI/TUI 选型见 `COMPONENTS.md`。
