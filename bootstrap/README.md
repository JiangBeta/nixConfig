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

## 安装方式分布

- **apt（需 sudo）**：zsh、git、git-lfs、direnv、fzf、zoxide、fd-find、ripgrep、bat、tealdeer、tmux、btop、zsh-syntax-highlighting、zsh-autosuggestions、git-delta
- **官方安装脚本**：starship、atuin
- **GitHub Release 预编译（~/.local/bin）**：eza、sheldon、dust、fastfetch、lazygit、duf、doggo、gh、superfile、yazi、neovim

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
4. **Neovim 版本**：为保证 LazyVim 可用（需 ≥ 0.9），neovim 走 GitHub Release 而非 apt（Debian 12 / Ubuntu 22.04 的 apt 版本过旧）。
5. **无需 Rust 工具链**：eza/sheldon/dust 均使用 GitHub Release 预编译二进制，不安装 rustup/cargo（避免大陆下载 static.rust-lang.org 缓慢超时）。
5. **命名冲突**：Debian/Ubuntu 的 `bat` 实际为 `batcat`、`fd` 为 `fdfind`，脚本自动在 `~/.local/bin` 建软链接；`~/.local/bin` 已在 `~/.zshrc` 的 PATH 首位。
