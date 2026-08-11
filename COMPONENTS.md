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
| 终端 | Kitty | `kitty` |
| 输入法 | Fcitx5 + Rime + 雾凇拼音小鹤双拼 | `fcitx5`, `fcitx5-rime`, `rime-ice` |
| 浏览器 | Zen Browser | `zen-browser` |
| 声音 | PipeWire | `pipewire`, `wireplumber` |
| 蓝牙 | bluez + blueman | `bluez`, `blueman` |
| XDG Portal | xdg-desktop-portal-gtk/gnome | `xdg-desktop-portal` |
| GPU | Mesa + Vulkan（Intel/AMD 自动） | 内核内置 |
| 窗口截图/录屏 | Niri 内置 + grim/slurp | `grim`, `slurp` |

## CLI 核心工具

| 组件 | 说明 | base | darwin | nix-server | nix-desktop |
|------|------|:---:|:---:|:---:|:---:|
| Shell | Zsh + Starship + Sheldon + Atuin | ✅ | ✅ | ✅ | ✅ |
| 编辑器 | vim | ✅ | ✅ | ✅ | ✅ |
| 系统信息 | fastfetch | ✅ | ✅ | ✅ | ✅ |
| 进程监视 | btop-cn | ✅ | ✅ | ✅ | ✅ |
| 包/归档 | zip/unzip/p7zip | ✅ | ✅ | ✅ | ✅ |
| 网络诊断 | mtr/dnsutils/nmap/tcpdump | ✅ | ✅ | ✅ | ✅ |
| 文本处理 | jq/gnugrep/gawk/gnused | ✅ | ✅ | ✅ | ✅ |
| 文件操作 | rsync/file/which | ✅ | ✅ | ✅ | ✅ |
| 安全 | openssh/openssl | ✅ | ✅ | ✅ | ✅ |

## CLI 替代工具（home/base/cli.nix）

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

## TUI 工具（home/base/tui.nix）

| 组件 | 说明 | base | darwin | nix-server | nix-desktop |
|------|------|:---:|:---:|:---:|:---:|
| Yazi / Superfile | 文件管理器 | ✅ | ✅ | ✅ | ✅ |
| btop | 系统监视 | ✅ | ✅ | ✅ | ✅ |
| lazygit | Git TUI | ✅ | ✅ | ✅ | ✅ |
| Neovim + LazyVim(neovim 配置框架) | 文本编辑 | ✅ | ✅ | ✅ | ✅ |

## 字体（modules/base/fonts.nix）

| 字体 | 用途 |
|------|------|
| terminus_font_ttf | 终端 Mono 点阵字体（默认终端字体） |
| Maple Mono NF CN | 中文编程字体 |
| 霞鹜文楷 屏幕版 | 中文阅读字体 |
| OPPO Sans 4.0 | OPPO 字体（界面字体） |



