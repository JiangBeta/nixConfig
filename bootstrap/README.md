# bootstrap/setup-shell.sh

从 nixConfig 提取的 shell 环境一键安装脚本，面向 **Ubuntu / Debian**、**非 root 用户**。

## 与 Nix 模块的对应关系

| 脚本内容 | 来源模块 |
|----------|----------|
| zsh + starship + sheldon + atuin + direnv | `home/base/core/shell.nix` |
| eza / bat / fzf / zoxide / tealdeer / rg / fd / tmux / fastfetch / dust / duf / doggo | `home/base/core/cli.nix` |
| git + git-lfs + delta + lazygit + gh | `home/base/core/git.nix` |
| yazi + btop + superfile | `home/base/tui/apps.nix` |
| neovim + LazyVim | `home/base/tui/neovim.nix` |

## 用法

```bash
bash setup-shell.sh              # 完整安装（apt + 用户级工具 + 配置）
bash setup-shell.sh --skip-apt   # 跳过 apt 阶段（已手动装好系统包时）
```

## 安装方式

按优先级：默认 apt → 第三方仓库 / PPA → 官方安装脚本 → GitHub 兜底。

| 工具 | 安装方式 |
|------|----------|
| zsh / git / git-lfs / direnv / fzf / zoxide / fd-find / ripgrep / bat / tealdeer / tmux / btop / zsh-syntax-highlighting / zsh-autosuggestions / git-delta / eza / duf / gh | 默认 apt |
| sheldon / atuin / lazygit | 第三方仓库 deb.griffo.io |
| yazi | 第三方仓库 yazi-rs.github.io |
| fastfetch | PPA `zhangsongcui3371/fastfetch`（仅 Ubuntu；Debian 走默认仓库，缺则 GitHub 兜底） |
| neovim | PPA `neovim-ppa/stable`（仅 Ubuntu；Debian 走默认仓库，版本 <0.9 则 GitHub 兜底） |
| starship | 官方脚本 `starship.rs/install.sh` |
| dust | 官方脚本 `bootandy/dust` install.sh |
| doggo | 官方脚本 `mr-karan/doggo` install.sh |
| superfile | 官方脚本 `superfile.dev/install.sh` |

> - **PPA 仅 Ubuntu 生效**：Debian 下 fastfetch/neovim 走默认仓库（trixie 有；bookworm 的 fastfetch 无、neovim 仅 0.7），缺失/过旧时自动 GitHub 兜底。
> - **网络提示**：starship/dust/doggo/superfile 的安装脚本、以及 GitHub 兜底都会连 GitHub；大陆网络下需系统代理 `export https_proxy=http://127.0.0.1:端口`，GitHub 兜底也可用 `export GH_PROXY=https://ghfast.top/`。

## 写入的配置

| 文件 | 说明 |
|------|------|
| `~/.zshrc` | PATH/语言/编辑器/历史/completion、sheldon/fzf/zoxide/atuin/direnv 集成、别名、`zx`/`y` 函数、fastfetch |
| `~/.config/starship.toml` | Catppuccin Mocha 主题 |
| `~/.config/sheldon/plugins.toml` | zsh-defer / zsh-completions / you-should-use / ohmyzsh |
| `~/.config/bat/config` | pager / TwoDark 主题 / syntax 映射 |
| `~/.config/tealdeer/config.toml` | display + updates |
| `~/.config/btop/btop.conf` | 无背景 + vim 键 |
| `~/.config/yazi/yazi.toml` | 显示隐藏文件 + 符号链接 |
| `~/.config/atuin/config.toml` | 本地模式（关闭 sync records） |
| `~/.tmux.conf` | Ctrl-a prefix + vi 模式 + 分屏快捷键 |
| `~/.config/nvim/init.lua` | LazyVim bootstrap |
| `~/.gitconfig` | 用户信息 + delta + 全部别名 |

## 注意事项

1. **Git 用户信息**：脚本顶部 `GIT_USER_NAME` / `GIT_USER_EMAIL` 默认取自 `vars/default.nix`，请按需修改（邮箱为占位值）。
2. **默认 shell**：脚本末尾会 `chsh -s zsh`（需输入密码），重新登录后生效。
3. **中文环境**：`~/.zshrc` 设置 `LANG=zh_CN.UTF-8`，若系统无此 locale 需 `sudo locale-gen zh_CN.UTF-8`。
4. **Neovim 版本**：apt 优先，但 Debian 12（0.7.2）/ Ubuntu 22.04（0.6）的 apt neovim < 0.9 不满足 LazyVim，脚本会自动回退 GitHub 新版。
5. **GitHub 兜底**：仅 sheldon / doggo / superfile / yazi 恒无 apt 包、必走 GitHub；其余工具新版 release 有 apt 包时用 apt，无包时回退 GitHub（全程不装 rustup/cargo）。
6. **命名冲突**：Debian/Ubuntu 的 `bat` 实际为 `batcat`、`fd` 为 `fdfind`，脚本自动在 `~/.local/bin` 建软链接；`~/.local/bin` 已在 `~/.zshrc` 的 PATH 首位。
7. **GitHub 下载超时**：每个下载设了 15s 连接超时 + 600s 总超时，失败会跳过而非无限卡住。大陆网络下载卡住时，`export GH_PROXY=https://ghfast.top/` 后重跑（备选 `gh-proxy.com` / `ghproxy.net`）。
