# Components 选型清单

记录本项目 nixConfig 所包含的全部软件与配置。分类说明：

| 分类 | 含义 | 适用主机 |
|------|------|---------|
| `base` | 所有系统的基础层（含 macOS、armbian），通用配置 | 全部 |
| `darwin` | macOS 专用 | macmini |
| `nix-base` | Linux 通用配置 | 所有 Linux 主机 |
| `nix-server` | Linux 服务器配置 | nuc8-s, appgateway, xiaobaonas(armbian) |
| `nix-desktop` | Linux 桌面配置 | 13pro, nuc8-d |

> 规则：勾选 `base` 即表示所有系统都需要，故 `darwin`、`nix-server`、`nix-desktop` 均含 base 内容。

## 系统层

| 组件 | base | darwin | nix-base | nix-server | nix-desktop |
|------|:---:|:---:|:---:|:---:|:---:|
| Nix Flakes 设置 + 中国镜像 | ✅ | ✅ | ✅ | ✅ | ✅ |
| Locale / 时区 / 键盘 | ✅ | ✅ | ✅ | ✅ | ✅ |
| 用户 + SSH 密钥 | ✅ | ✅ | ✅ | ✅ | ✅ |
| 安全基线（sudo/fail2ban/SSH 加固） | ✅ | ✅ | ✅ | ✅ | ✅ |
| 磁盘：btrfs + disko 声明式分区 | | | | 🔲 | 🔲 |
| 引导：GRUB / Systemd-boot | | | | 🔲 | 🔲 |
| 网络：NetworkManager + iwd | | | |  | ✅ |
| SSH 服务 | | | ✅ | ✅ | ✅ |
| zswap 内存压缩（配合休眠） | | | | 🔲 | ✅ |
| macOS 系统设置（dock/finder/trackpad） | | ✅ |  | | |
| 快照：snapper + grub-btrfs | | |  | 🔲 | ✅ |

- ✅：使用
- 🔲：不一定使用

## 桌面层（nix-desktop 专用）

| 组件 | 说明 | nixpkgs / flake |
|------|------|-----------------|
| 窗口管理器 | Niri | `niri` (flake) |
| 状态栏/启动器/锁屏 | Noctalia Shell | `noctalia` (flake) |
| 显示管理器 | Ly | `ly` |
| 摄像头 | Chicony UVC（`uvcvideo` 驱动开箱即用）+ v4l-utils + Cheese（X11 wrapper） | `v4l-utils`, `cheese` |
| 电池 | upower 守护进程 + upower / acpi（pro13 笔记本） | `upower`, `acpi` |
| 终端 | Kitty | `kitty` |
| 输入法 | Fcitx5 + Rime + 雾凇拼音小鹤双拼 | `fcitx5`, `fcitx5-rime`, `rime-ice` |
| 浏览器 | Zen Browser | `zen-browser` |
| Markdown 编辑器 | Typora（跨平台） | `typora` |
| 编辑器（汉化） | ZedG（Zed 汉化版） | 预编译 tar.gz（autoPatchelf） |
| 数据库/SSH 工作台 | Navop | 预编译 AppImage（静态 ELF） |
| 声音 | PipeWire + SOF/ALSA 固件 | `pipewire`, `wireplumber`, `sof-firmware`, `alsa-ucm-conf` |
| 蓝牙 | bluez + blueman | `bluez`, `blueman` |
| 电源管理 | power-profiles-daemon（balanced） | `power-profiles-daemon` |
| 空闲/锁屏/壁纸 | Noctalia Shell 控制 | 内置 |
| 远程桌面 | Sunshine（服务端）+ Moonlight（客户端，macOS 用 moonlight-macos-enhanced） | `sunshine`, `moonlight-qt` |
| VNC 服务端 | wayvnc（Wayland VNC，监听 0.0.0.0:5900 直连，前置 wl-uinput-proxy 修复 Niri 键盘） | `wayvnc`, `wl-uinput-proxy` |
| 键鼠共享 | pynergy（synergy 协议 KVM，兼容 Deskflow） | `pynergy-client` (flake) |
| XDG Portal | xdg-desktop-portal-gtk/gnome | `xdg-desktop-portal` |
| GPU | Mesa + Vulkan（Intel/AMD 自动） | 内核内置 |
| 窗口截图/录屏 | Niri 内置 + grim/slurp | `grim`, `slurp` |

## Flatpak 应用（modules/linux/gui/flatpak.nix）

系统级 Flatpak，声明式安装（Flathub 稳定版，USTC 镜像加速）：

| 类型 | 应用 | Flatpak ID |
|------|------|-----------|
| 通讯 | 微信 / 电报 / Discord | `com.tencent.WeChat` / `org.telegram.desktop` / `com.discordapp.Discord` |
| 笔记/办公 | Obsidian / WPS / Foliate | `md.obsidian.Obsidian` / `com.wps.Office` / `com.github.johnfactotum.Foliate` |
| 浏览器 | Microsoft Edge | `com.microsoft.Edge` |
| 权限管理 | Flatseal | `com.github.tchx84.Flatseal` |
| 应用商店 | Bazaar | `io.github.kolunmi.Bazaar` |
| 应用管理 | Warehouse | `io.github.flattool.Warehouse` |
| AppImage 管理 | Gear Lever | `it.mijorus.gearlever` |

- **镜像**：Flathub remote → `https://mirrors.ustc.edu.cn/flathub`（缓存，未命中回源）。
- **兼容**：Electron 应用强制 `ELECTRON_OZONE_PLATFORM_HINT=auto`（Wayland）；Obsidian 追加 `--enable-wayland-ime`（fcitx5 输入法，见 `home/linux/gui/flatpak-compat.nix`）。
- **权限**：文件访问由 Flatseal 按需授权（占位，待后续配置）。

## CLI 核心工具

### 跨平台（home/base，含 macOS）
| 组件 | 说明 | base | darwin | nix-server | nix-desktop |
|------|------|:---:|:---:|:---:|:---:|
| Shell | Zsh + Starship + Sheldon + Atuin | ✅ | ✅ | ✅ | ✅ |
| 终端复用 | tmux | ✅ | ✅ | ✅ | ✅ |
| 编辑器 | nvim (LazyVim) | ✅ | ✅ | ✅ | ✅ |
| 系统信息 | fastfetch | ✅ | ✅ | ✅ | ✅ |
| 进程监视 | btop | ✅ | ✅ | ✅ | ✅ |

### 系统 CLI（modules/linux/core/base.nix，Linux 专属，按类别分组）
| 类别 | 工具 | nix-server | nix-desktop |
|------|------|:---:|:---:|
| archives 压缩归档 | zip / xz / unzip / p7zip | ✅ | ✅ |
| networking tools 网络工具 | curl / aria2 / mtr / dnsutils / nmap / tcpdump | ✅ | ✅ |
| misc 杂项 | cowsay / file / which / tree / gnused / gnutar / gawk / zstd / gnupg / jq / gnugrep / rsync / git / vim / tldr / bash-completion / chezmoi / just | ✅ | ✅ |
| system call monitoring 系统调用监控 | lsof | ✅ | ✅ |
| system tools 系统工具 | sysstat / lm_sensors / ethtool / pciutils / usbutils / openssl / btrfs-progs / dosfstools | ✅ | ✅ |

## CLI 替代工具（home/base/core/cli.nix）

| 组件 | 替代 | base | darwin | nix-server | nix-desktop |
|------|------|:---:|:---:|:---:|:---:|
| eza | ls | ✅ | ✅ | ✅ | ✅ |
| bat | cat | ✅ | ✅ | ✅ | ✅ |
| fd | find | ✅ | ✅ | ✅ | ✅ |
| ripgrep | grep | ✅ | ✅ | ✅ | ✅ |
| fzf | 模糊搜索 | ✅ | ✅ | ✅ | ✅ |
| zoxide | cd | ✅ | ✅ | ✅ | ✅ |
| tealdeer (tldr) | man | ✅ | ✅ | ✅ | ✅ |
| dust / duf | du / df | ✅ | ✅ | ✅ | ✅ |
| doggo | dig | ✅ | ✅ | ✅ | ✅ |
| aria2 | 下载 | ✅ | ✅ | ✅ | ✅ |

## TUI 工具（home/base/tui/apps.nix）

| 组件 | 说明 | base | darwin | nix-server | nix-desktop |
|------|------|:---:|:---:|:---:|:---:|
| Yazi / Superfile | 文件管理器 | ✅ | ✅ | ✅ | ✅ |
| btop | 系统监视 | ✅ | ✅ | ✅ | ✅ |
| lazygit | Git TUI | ✅ | ✅ | ✅ | ✅ |
| Neovim + LazyVim(neovim 配置框架) | 文本编辑 | ✅ | ✅ | ✅ | ✅ |
| vortex | 服务器管理 TUI（SSH 管理 VPS 集群） | ✅ | ✅ | ✅ | ✅ |

## 开发环境工具链（dev）

### Go（home/base/dev/go.nix，nix-desktop）
| 组件 | 说明 | nixpkgs |
|------|------|---------|
| go | Go 编译器（默认最新稳定版 1.26，可经 option 固定 go_1_26） | `go` |
| gopls | Go 语言服务器 | `gopls` |
| golangci-lint | Go 代码检查 | `golangci-lint` |
| delve | Go 调试器（命令 `dlv`） | `delve` |

### Node.js（home/base/dev/nodejs.nix，nix-desktop）
| 组件 | 说明 | nixpkgs |
|------|------|---------|
| nodejs | JavaScript/TypeScript 运行时（24.18，与 AI 工具运行时统一为 Node 24） | `nodejs_24` |
| pnpm | 前端包管理器 | `pnpm` |
| vue-language-server | Vue 的 Volar 语言服务 | `vue-language-server` |

### Docker（modules/linux/dev/docker.nix，nix-desktop）
| 组件 | 说明 | nixpkgs |
|------|------|---------|
| docker | 容器引擎（守护进程 + CLI + `docker compose` 插件，用户入 docker 组） | `docker` |
| docker-compose | 独立 compose 命令 `docker-compose` | `docker-compose` |

## 字体（modules/base/core/fonts.nix）

| 字体 | 用途 |
|------|------|
| terminus_font_ttf | 终端 Mono 点阵字体（默认终端字体） |
| Maple Mono NF CN | 中文编程字体 |
| 霞鹜文楷 屏幕版 | 中文阅读字体 |
| OPPO Sans 4.0 | OPPO 字体（界面字体） |



