# nixConfig — Nix Flakes 配置

## 项目概述

基于 Nix Flakes 的多主机 NixOS/nix-darwin/home-manager 配置，从 Arch Linux 迁移而来。

**设计理念**：DRY 优先，通过模块分层实现"一份配置，多机复用"。跨平台通用逻辑上提到 `modules/base/` 和 `home/base/`，平台专属逻辑下沉到 `modules/nixos/`、`modules/darwin/`、`home/linux/`、`home/darwin/`。

## 目录结构

```
nixConfig/
├── flake.nix                           # Flake 入口（inputs 声明）
├── flake.lock                          # 锁定版本
├── outputs/                            # Flake outputs（按架构分发）
│   ├── default.nix                       # 入口：genSpecialArgs, forAllSystems
│   ├── x86_64-linux/                     # NixOS 主机（pro13, nuc8-d, nuc8-s, appgateway）
│   ├── aarch64-darwin/                   # nix-darwin 主机（macmini）
│   └── aarch64-linux/                    # HM standalone（xiaobaonas）
├── modules/                            # 抽象出的“功能模块”（按操作系统与组合复用划分）
│   ├── base/                             # 跨平台共享（Nix 设置、locale、fonts、用户、包）
│   ├── linux/                            # linux 专用（base + desktop 层）
│   │   ├── base.nix                        # linux 基础设置（时区、Locale、Nix设置）
│   │   ├── boot.nix                        # 引导与内核设置
│   │   ├── btrfs.nix                       # Btrfs / Snapper 快照策略
│   │   └── docker.nix                      # Docker 相关支持
│   └── darwin/                           # nix-darwin 专用（macOS 系统设置）
├── home/                               # Home Manager 用户配置
│   ├── base/                             # 跨平台共享（shell、git、neovim、CLI/TUI 工具）
│   ├── linux/                            # Linux 专属
│   │   ├── Desktop/                        # 桌面环境(Wayland + Ly + Niri + Noctalia)
│   │   │   ├── default.nix             
│   │   │   └── wayland.nix
│   │   └── TUI/                            # TUI
│   └── darwin/                           # macOS 专属
├── hosts/                              # 单台主机配置（hardware、disko、networking）
│   ├── pro13/                            # hostname 为 pro13 的主机
│   │   ├── default.nix                     # 默认配置入口
│   │   ├── hardware.nix                    # 硬件相关
│   │   ├── disko.nix                       # 磁盘分区
│   │   └── networking.nix                  # 网络设置
│   └── M4MacMini/                        # hostname 为 M4MacMini 的主机
├── lib/                                # 辅助函数（scanPaths、relativeToRoot）
├── vars/                               # 共享变量（用户名、时区、locale）
├── nixos-installer/                    # 独立 Flake — 用于从 ISO 安装系统
├── overlays/                           # nixpkgs overrides
└── secrets/                            # agenix 密钥定义（不提交）
```

```
nixConfig/
├── flake.nix                            # Flake 主入口（声明 inputs 依赖与输出结构）
├── flake.lock                           # 锁定的依赖版本
├── outputs/                             # 按系统类型分发的构建输出逻辑
│   ├── default.nix                      # 入口：提供 forAllSystems、genSpecialArgs 等构建辅助
│   ├── x86_64-linux/                    # NixOS 主机构建（pro13, nuc8-d, nuc8-s, appgateway）
│   ├── aarch64-darwin/                  # nix-darwin 主机构建（macmini）
│   └── aarch64-linux/                   # Standalone Home Manager 构建（xiaobaonas）
│
├── common/                              # 【数据、契约与工具层】跨 NixOS / Darwin / HM 共享
│   ├── options/                         # 🌟 模块化的 Custom Options 统一声明目录
│   │   ├── default.nix                  # 汇聚入口（统一 imports 目录下所有 option 子模块）
│   │   ├── user.nix                     # 专门定义 用户/账号 相关的全局 Option (mySystem.user, myHome.dirs)
│   │   ├── system.nix                   # 专门定义 系统级 参数的 Option (isServer, locale, timezone)
│   │   └── hardware.nix                 # 专门定义 硬件级 参数的 Option (diskDevice, enableNVMe)
│   │
│   ├── hosts-info.nix                   # 🌟 静态主机元数据映射表（统一定义 IP、SSH 端口、主机角色等）
│   ├── env.nix                          # 跨端共享的环境变量与 XDG 目录规范（如 EDITOR, ZDOTDIR）
│   ├── lib/                             # 纯 Nix 辅助函数库（整合原根目录 lib/，如 scanPaths, relativeToRoot）
│   ├── overlays/                        # nixpkgs 的自定义覆盖与修补（整合原根目录 overlays/）
│   └── assets/                          # 静态资源与纯 Bash 脚本（通用的运维脚本、壁纸、公钥等）
│
├── modules/                             # 【操作系统级系统模块】处理 OS 权限、驱动与服务（NixOS / Darwin）
│   ├── base/                            # 跨平台系统级基础逻辑
│   │   ├── user.nix                     # 🌟 消费 common/options/user.nix，创建 Linux 系统账号与 sudo 组
│   │   └── nix-settings.nix             # Nix 核心设置、Flake 选项、GC 垃圾回收策略
│   ├── linux/                           # Linux / NixOS 专属系统模块
│   │   ├── base.nix                     # Linux 基础设置（时区、Locale）
│   │   ├── boot.nix                     # 引导与内核参数
│   │   ├── disko-template.nix           # 🌟 消费 common/options/hardware.nix，实现通用的 Disko 分区逻辑
│   │   ├── btrfs.nix                    # Btrfs / Snapper 快照策略
│   │   └── docker.nix                   # Docker 容器运行时支持
│   └── darwin/                          # macOS / nix-darwin 专属系统模块
│
├── home/                                # 【Home Manager 用户环境】专注 Dotfiles、GUI/TUI 工具与用户家目录
│   ├── base/                            # 跨平台共享用户配置
│   │   ├── user-dirs.nix                # 🌟 消费 common/options/user.nix，管理 Downloads, Projects 等 XDG 目录
│   │   └── shell.nix                    # Zsh, Git, Neovim 等 CLI 工具链配置
│   ├── linux/                           # Linux 专属用户环境
│   │   ├── Desktop/                     # Wayland + Ly + Niri + Noctalia 桌面环境
│   │   └── TUI/                         # 终端界面增强工具
│   └── darwin/                          # macOS 专属用户配置
│
├── hosts/                               # 【具体主机实例化】仅做参数赋值与差异化硬件绑定
│   ├── pro13/                           # 示例 NixOS 笔记本
│   │   ├── default.nix                  # 入口：干净赋值 mySystem = { user = "..."; diskDevice = "/dev/nvme0n1"; }
│   │   ├── hardware.nix                 # 自动生成的底层硬件配置
│   │   └── networking.nix               # 机器特定网络与防火墙配置
│   └── M4MacMini/                       # 示例 macOS 主机
│       └── default.nix                  # macOS 专属差异化配置
│
├── nixos-installer/                     # 独立 Flake — 用于制作自定义 ISO 与光盘离线安装
└── secrets/                             # agenix 密钥管理（不提交到 Git 仓库）
```

## 主机表

| 主机名 | 系统 | 架构 | 角色 | Nix 模式 |
|--------|------|------|------|----------|
| Pro13 | NixOS | x86_64 | 桌面 PC | `nixosSystem` + `home-manager` |
| nuc8-d | NixOS | x86_64 | 桌面 PC | `nixosSystem` + `home-manager` |
| nuc8-s | NixOS | x86_64 | 服务器 | `nixosSystem` + `home-manager` |
| appgateway | NixOS VM | x86_64 | 网关 | `nixosSystem` + `home-manager` |
| macmini | macOS | aarch64 | AI 服务器 | `nix-darwin` + `home-manager` |
| xiaobaonas | armbian | aarch64 | NAS | HM standalone |
| 7100U | PVE | x86_64 | VM Host |  |

## 快速开始

```bash
# 更新依赖
nix flake update

# 构建并切换 NixOS 配置
nixos-rebuild switch --flake .#13pro

# 构建并切换 nix-darwin 配置
darwin-rebuild switch --flake .#macmini

# 仅切换 Home Manager 配置
home-manager switch --flake .#beta@13pro

# 格式化代码
nix fmt

# 运行检查
nix flake check
```

## 内核

linux-zen


## Components 选型

| 类型 | 功能 | 选型 |
|------|------|------|
| **WM** | 窗口管理器 | Niri |
| **Shell** | 状态栏/启动器/锁屏 | Noctalia Shell |
| **终端** | 终端模拟器 | Kitty |
| **Shell** | 命令行 | Zsh + Starship + Sheldon + Atuin |
| **编辑器** | 编辑器 | Neovim |
| **输入法** | 中文输入 | Fcitx5 + Rime + rime-ice（雾凇拼音） |
| **DM** | 显示管理器 | Ly |
| **字体** | 中英文 | 霞鹜文楷, Maple Mono, OPPO v4 |
| **文件管理** | 文件管理器 | Superfile (TUI) + Yazi（TUI）+ Thunar（GUI） |
| **网络** | 网络管理 | NetworkManager + iwd |
| **声音** | 音频 | PipeWire + WirePlumber |
| **蓝牙** | 蓝牙 | bluez |
| **浏览器** | 浏览器 | Zen Browser |

### CLI/TUI 工具链

| 功能 | 选型 | 功能 | 选型 |
|------|------|------|------|
| cd | zoxide | ls | eza |
| cat | bat | find | fd |
| grep | ripgrep | 模糊搜索 | fzf |
| 系统监视 | btop | 磁盘分析 | dust |
| git TUI | lazygit | 系统信息 | fastfetch |
| 历史搜索 | atuin | 环境管理 | direnv |
| 命令运行器 | Justfile | 软件手册 | tldr |
| DNS 工具包 | dnsutils | 网络管理 | iproute2 |
