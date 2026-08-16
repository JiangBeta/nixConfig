#!/usr/bin/env bash
# ================================================================
# Ubuntu / Debian Shell 环境一键安装脚本（非 root 用户）
#
# 从 nixConfig 提取的 shell 相关配置，等价于以下模块：
#   home/base/core/shell.nix   → zsh + starship + sheldon + atuin + direnv
#   home/base/core/cli.nix     → eza/bat/fzf/zoxide/tealdeer/rg/fd/tmux/fastfetch/dust/duf/doggo
#   home/base/core/git.nix     → git + git-lfs + delta + lazygit + gh
#   home/base/tui/apps.nix     → yazi + btop + superfile
#   home/base/tui/neovim.nix   → neovim + LazyVim
#
# 用法：
#   bash setup-shell.sh          # 安装全部 + 写入配置
#   bash setup-shell.sh --skip-apt   # 跳过 apt 阶段（已手动装好系统包时）
#
# 说明：
#   - 需要 sudo（仅 apt 阶段），其余工具安装到用户目录（~/.local/bin）
#   - 幂等：已安装的工具会自动跳过
# ================================================================
set -euo pipefail
IFS=$'\n\t'

# ---------- 颜色与样式 ----------
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

ICON_CHECK="${GREEN}✔${NC}"
ICON_CROSS="${RED}✘${NC}"
ICON_WARN="${YELLOW}!${NC}"
ICON_INFO="${CYAN}ℹ${NC}"

# ---------- 全局变量 ----------
HOME_DIR="${HOME}"
LOCAL_BIN="$HOME_DIR/.local/bin"
CONFIG_DIR="$HOME_DIR/.config"

# Git 用户信息（对应 vars/default.nix，可改成你自己的）
GIT_USER_NAME="Beta"
GIT_USER_EMAIL="nishui8384@gmail.com"   # ⚠️ 请替换为真实邮箱（Git commit 签名需要）

SKIP_APT=0
for arg in "$@"; do
  [ "$arg" = "--skip-apt" ] && SKIP_APT=1
done

# ---------- 日志函数 ----------
info()  { printf "${ICON_INFO} ${CYAN}%s${NC}\n" "$*"; }
ok()    { printf "${ICON_CHECK} ${GREEN}%s${NC}\n" "$*"; }
warn()  { printf "${ICON_WARN} ${YELLOW}%s${NC}\n" "$*"; }
err()   { printf "${ICON_CROSS} ${RED}%s${NC}\n" "$*"; }
section(){ printf "\n${BOLD}${PURPLE}==> %s${NC}\n" "$*"; }

have()  { command -v "$1" >/dev/null 2>&1; }

# ---------- 系统检测 ----------
detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "${ID:-}" in
      ubuntu|debian) OS="$ID" ;;
      *) OS="unknown" ;;
    esac
  else
    OS="unknown"
  fi
  if [ "$OS" = "unknown" ]; then
    warn "未识别为 Ubuntu/Debian（ID=${ID:-未知}），脚本可能不完全适用，继续执行..."
  else
    ok "检测到系统：${PRETTY_NAME:-$OS}"
  fi
}

# ---------- 权限检查 ----------
check_user() {
  if [ "$(id -u)" -eq 0 ]; then
    warn "当前是 root 用户，脚本将安装到 /root 下；建议用非 root 用户运行。"
    warn "如需以非 root 运行，请退出后用普通用户执行。继续中..."
  fi
  if [ "$SKIP_APT" -eq 0 ] && ! have sudo; then
    err "未找到 sudo，apt 阶段无法执行。可用 --skip-apt 跳过（需自行安装系统包）。"
    exit 1
  fi
}

# ---------- 阶段 1：apt 系统包 ----------
install_apt() {
  section "阶段 1/5：安装 apt 系统包"
  [ "$SKIP_APT" -eq 1 ] && { warn "已跳过 apt 阶段"; return 0; }

  info "更新软件源..."
  sudo apt-get update -y

  # 核心 shell + CLI + TUI + 构建依赖
  local pkgs=(
    # shell 核心
    zsh git git-lfs direnv
    # CLI 工具
    fzf zoxide fd-find ripgrep bat tealdeer
    # TUI / 系统
    tmux btop
    # zsh 插件
    zsh-syntax-highlighting zsh-autosuggestions
    # git 美化
    git-delta
    # 下载 / 解压（安装器依赖）
    curl wget ca-certificates unzip tar
  )

  local available=()
  local p
  for p in "${pkgs[@]}"; do
    if apt-cache show "$p" >/dev/null 2>&1; then
      available+=("$p")
    else
      warn "apt 源中无 $p，跳过"
    fi
  done

  if [ "${#available[@]}" -gt 0 ]; then
    sudo apt-get install -y "${available[@]}"
    ok "apt 包安装完成"
  fi

  # Debian/Ubuntu 的命名冲突处理：fdfind→fd、batcat→bat
  mkdir -p "$LOCAL_BIN"
  if have fdfind && ! have fd; then
    ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"
    ok "已创建 fd → fdfind 软链接"
  fi
  if have batcat && ! have bat; then
    ln -sf "$(command -v batcat)" "$LOCAL_BIN/bat"
    ok "已创建 bat → batcat 软链接"
  fi
}

# eza / sheldon / dust 改用 GitHub Release 预编译二进制（见 install_releases），
# 避免下载 Rust 工具链（static.rust-lang.org 在大陆缓慢/超时）。

# ---------- 阶段 2：starship / atuin ----------
install_starship() {
  if have starship; then ok "starship 已安装，跳过"; return 0; fi
  info "安装 starship..."
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$LOCAL_BIN"
  ok "starship 安装完成"
}

install_atuin() {
  if have atuin; then ok "atuin 已安装，跳过"; return 0; fi
  info "安装 atuin..."
  curl --proto '=https' --tlsv1.2 -LsSf \
    https://github.com/atuinsh/atuin/releases/latest/download/atuin-installer.sh | sh
  ok "atuin 安装完成"
}

install_scripts() {
  section "阶段 2/5：安装 starship / atuin"
  install_starship
  install_atuin
}

# ---------- 阶段 4：GitHub Release 预编译二进制 ----------
# 通用下载器：从 GitHub 最新 release 按正则匹配资产，解压后装二进制到 ~/.local/bin
# 用法: gh_bin <owner/repo> <资产正则> <归档内二进制名> [安装名]
gh_bin() {
  local repo="$1" pattern="$2" bin="$3" name="${4:-$3}"
  local archpat
  case "$(uname -m)" in
    x86_64)  archpat="x86_64|amd64" ;;
    aarch64) archpat="aarch64|arm64" ;;
    *)       archpat="$(uname -m)" ;;
  esac

  local api="https://api.github.com/repos/${repo}/releases/latest"
  local urls url
  urls="$(curl -fsSL "$api" | grep -oE '"browser_download_url": *"[^"]+"' | cut -d'"' -f4 | grep -E "$pattern")"
  url="$(printf '%s\n' "$urls" | grep -iE "$archpat" | head -n1)"
  [ -z "$url" ] && url="$(printf '%s\n' "$urls" | head -n1)"

  if [ -z "$url" ]; then
    warn "未找到 ${repo} 匹配资产（pattern: $pattern），跳过"
    return 1
  fi

  info "下载 ${repo} ..."
  local tmpdir file
  tmpdir="$(mktemp -d)"
  file="$tmpdir/$(basename "$url")"
  curl -fL --retry 3 -o "$file" "$url"

  case "$file" in
    *.deb)
      dpkg-deb -x "$file" "$tmpdir/x" 2>/dev/null || {
        mkdir -p "$tmpdir/x"
        ( cd "$tmpdir" && ar x "$file" && tar -xf data.tar.* -C "$tmpdir/x" 2>/dev/null ) || true
      }
      ;;
    *.tar.gz|*.tgz)  tar -xzf "$file" -C "$tmpdir" ;;
    *.tar.xz)        tar -xJf "$file" -C "$tmpdir" ;;
    *.tar.bz2)       tar -xjf "$file" -C "$tmpdir" ;;
    *.zip)           unzip -q "$file" -d "$tmpdir" ;;
    *) warn "未知归档类型：$(basename "$file")"; rm -rf "$tmpdir"; return 1 ;;
  esac

  local found
  found="$(find "$tmpdir" -type f -name "$bin" -executable 2>/dev/null | head -n1)"
  if [ -z "$found" ]; then
    warn "归档中未找到二进制 $bin（${repo}），跳过"
    rm -rf "$tmpdir"; return 1
  fi
  mkdir -p "$LOCAL_BIN"
  install -m 755 "$found" "$LOCAL_BIN/$name"
  ok "已安装 $name"
  rm -rf "$tmpdir"
}

# yazi 归档内同时含 yazi + ya 两个二进制
install_yazi() {
  if have yazi; then ok "yazi 已安装，跳过"; return 0; fi
  local archpat
  case "$(uname -m)" in
    x86_64)  archpat="x86_64|amd64" ;;
    aarch64) archpat="aarch64|arm64" ;;
    *)       archpat="$(uname -m)" ;;
  esac
  local api="https://api.github.com/repos/sxyazi/yazi/releases/latest"
  local url tmpdir file
  url="$(curl -fsSL "$api" | grep -oE '"browser_download_url": *"[^"]+"' | cut -d'"' -f4 | grep -E 'yazi-.*linux.*\.zip' | grep -iE "$archpat" | head -n1)"
  [ -z "$url" ] && url="$(curl -fsSL "$api" | grep -oE '"browser_download_url": *"[^"]+"' | cut -d'"' -f4 | grep -E 'yazi-.*linux.*\.zip' | head -n1)"
  if [ -z "$url" ]; then warn "未找到 yazi 资产，跳过"; return 1; fi

  info "下载 yazi ..."
  tmpdir="$(mktemp -d)"
  file="$tmpdir/yazi.zip"
  curl -fL --retry 3 -o "$file" "$url"
  unzip -q "$file" -d "$tmpdir"
  mkdir -p "$LOCAL_BIN"
  install -m 755 "$tmpdir"/*/yazi "$LOCAL_BIN/yazi"
  install -m 755 "$tmpdir"/*/ya   "$LOCAL_BIN/ya"
  ok "已安装 yazi + ya"
  rm -rf "$tmpdir"
}

install_releases() {
  section "阶段 3/5：安装 GitHub Release 预编译工具"
  gh_bin "eza-community/eza"          'eza_.*linux.*\.tar\.gz'       "eza"       || true
  gh_bin "rossmacarthur/sheldon"      'sheldon-.*linux.*\.tar\.gz'   "sheldon"   || true
  gh_bin "bootandy/dust"              'dust-.*linux.*\.tar\.gz'      "dust"      || true
  gh_bin "fastfetch-cli/fastfetch"    'fastfetch-linux.*\.tar\.gz'   "fastfetch" || true
  gh_bin "jesseduffield/lazygit"     'lazygit_.*Linux_.*\.tar\.gz' "lazygit"   || true
  gh_bin "muesli/duf"                'duf_.*linux_.*\.tar\.gz'     "duf"       || true
  gh_bin "mr-karan/doggo"            'doggo_.*Linux_.*\.tar\.gz'   "doggo"     || true
  gh_bin "cli/cli"                   'gh_.*linux_.*\.tar\.gz'      "gh"        || true
  gh_bin "yorukot/superfile"         'superfile.*\.tar\.gz'        "spf"                     || true
  install_yazi || true
}

# ---------- 阶段 5：Neovim（GitHub Release，含完整 runtime） ----------
install_neovim() {
  section "阶段 4/5：安装 Neovim（LazyVim 需 >= 0.9）"
  if have nvim && nvim --version 2>/dev/null | head -n1 | grep -qE '0\.(9|[1-9][0-9])'; then
    ok "neovim 版本满足要求，跳过"; return 0
  fi
  local archpat
  case "$(uname -m)" in
    x86_64)  archpat="x86_64|64" ;;     # 兼容 nvim-linux-x86_64 / nvim-linux64
    aarch64) archpat="arm64" ;;
    *) err "不支持的架构：$(uname -m)"; return 1 ;;
  esac
  local api="https://api.github.com/repos/neovim/neovim/releases/latest"
  local url tmpdir file
  url="$(curl -fsSL "$api" | grep -oE '"browser_download_url": *"[^"]+"' | cut -d'"' -f4 | grep -E "nvim-linux-${archpat}\.tar\.gz" | head -n1)"
  if [ -z "$url" ]; then warn "未找到 neovim 资产，跳过"; return 1; fi

  info "下载 neovim ..."
  tmpdir="$(mktemp -d)"
  file="$tmpdir/nvim.tar.gz"
  curl -fL --retry 3 -o "$file" "$url"
  tar -xzf "$file" -C "$tmpdir"
  local root
  root="$(find "$tmpdir" -maxdepth 1 -type d -name 'nvim-linux*' | head -n1)"
  mkdir -p "$LOCAL_BIN" "$HOME_DIR/.local/share" "$HOME_DIR/.local/lib"
  cp -r "$root"/bin/*   "$LOCAL_BIN/"
  [ -d "$root/share" ] && cp -r "$root"/share/* "$HOME_DIR/.local/share/"
  [ -d "$root/lib"   ] && cp -r "$root"/lib/*   "$HOME_DIR/.local/lib/"
  ok "neovim 安装完成（$(nvim --version 2>/dev/null | head -n1 || true)）"
  rm -rf "$tmpdir"
}

# ---------- 阶段 6：写入配置 ----------
write_config() {
  local file="$1"
  mkdir -p "$(dirname "$file")"
  cat > "$file"
}

deploy_configs() {
  section "阶段 5/5：写入配置文件"

  # ---- ~/.zshrc ----
  info "写入 ~/.zshrc"
  write_config "$HOME_DIR/.zshrc" <<'EOF'
# ~/.zshrc — Zsh 配置（由 nixConfig bootstrap/setup-shell.sh 生成）
# 对应 home/base/core/shell.nix + cli.nix

# ---- PATH ----
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# ---- 语言 ----
export LANG="zh_CN.UTF-8"
export LC_ALL="zh_CN.UTF-8"

# ---- 编辑器 ----
export EDITOR="nvim"
export VISUAL="nvim"

# ---- History ----
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000000
SAVEHIST=10000
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt APPEND_HISTORY
setopt SHARE_HISTORY

# ---- Completion ----
autoload -Uz compinit && compinit

# ---- zoxide ----
export _ZO_DATA_DIR="$HOME/.local/share/zoxide"
export _ZO_EXCLUDE_DIRS="$HOME/tmp:$HOME/Downloads/*:$HOME/.snapshots/*"
export _ZO_RESOLVE_SYMLINKS=1

# ---- FZF ----
export FZF_WALKER_DEPTH=5
export FZF_TMUX_HEIGHT="60%"
export FZF_DEFAULT_OPTS='--preview "cat {}" --preview-window right:50%'
export FZF_CTRL_R_OPTS="--scheme=history -i"
export FZF_CTRL_T_OPTS='--preview "[[ -d {} ]] && tree -C {} || highlight -0 ansi {} 2> /dev/null"'

# ---- 插件：sheldon（zsh-defer / zsh-completions / you-should-use / ohmyzsh） ----
if command -v sheldon >/dev/null 2>&1; then
  eval "$(sheldon source)"
fi

# ---- 插件：zsh-syntax-highlighting / zsh-autosuggestions（apt 安装） ----
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# ---- fzf 集成 ----
if command -v fzf >/dev/null 2>&1; then
  [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
  [ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh
fi

# ---- zoxide 集成 ----
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# ---- atuin 集成（--disable-up-arrow：上箭头留给 autosuggestions） ----
if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

# ---- direnv 集成 ----
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# ---- Aliases ----
# ls → eza
alias ls="eza --icons --long --header"
alias ll="eza --icons --long --header --all"
alias la="eza --icons --long --header --all --git"
alias tree="eza --tree --icons"
# cat → bat / du → dust
alias cat="bat"
alias du="dust"
# 系统
alias df="duf"
alias find="fd"
alias grep="rg"
alias top="btop"
alias help="tldr"
alias ip="ip -color"
alias myip="curl -s ip.sb"
# git
alias g="git"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias gst="git status"
alias gd="git diff"
alias gco="git checkout"
alias gb="git branch"
# lazygit / docker
alias lg="lazygit"
alias d="docker"
alias dc="docker compose"

# ---- 函数：zoxide + fzf 模糊搜索 (zx) ----
zx() {
  local query="${*}"
  local dir
  local preview_cmd="ls -F -C --color=always {2..}"
  local bind_opts="ctrl-z:ignore,btab:up,tab:down,enter:become:echo {2..}"
  dir=$(zoxide query --list --score | \
    fzf --filter="$query" --no-sort | \
    fzf --prompt="zoxide > " --nth=2.. --ansi --height=60% \
      --info=inline --border=rounded --layout=reverse \
      --preview-window=down:40%:wrap \
      --preview="$preview_cmd" \
      --bind "$bind_opts" \
      --cycle --keep-right --tabstop=1)
  [[ -n "$dir" ]] && cd "$dir"
}

# ---- 函数：Yazi（退出时 cd 到浏览目录） ----
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  command yazi "$@" --cwd-file="$tmp"
  if [ -f "$tmp" ]; then
    local cwd="$(cat "$tmp")"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f "$tmp"
  fi
}

# ---- Starship 提示符（放最后，覆盖 RPROMPT） ----
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# ---- fastfetch 启动（不在 VSCode/Nvim 中） ----
if [[ "$TERM_PROGRAM" != "vscode" && -z "$VSCODE_INJECTION" && -z "$NVIM" ]] && command -v fastfetch >/dev/null 2>&1; then
  fastfetch --pipe false
fi
EOF
  ok "~/.zshrc 已写入"

  # ---- ~/.config/starship.toml ----
  info "写入 ~/.config/starship.toml"
  write_config "$CONFIG_DIR/starship.toml" <<'EOF'
# starship.toml — Catppuccin Mocha（对应 home/base/core/shell.nix）
"$schema" = "https://starship.rs/config-schema.json"

format = "[](red)$os$username[](bg:peach fg:red)$directory[](bg:yellow fg:peach)$git_branch$git_status[](fg:yellow bg:green)$c$rust$golang$nodejs$python[](fg:green bg:sapphire)$nix_shell[ ](fg:sapphire)$line_break$character"
right_format = "$time$cmd_duration"

palette = "catppuccin_mocha"

[os]
disabled = false
style = "bg:red fg:crust"

[os.symbols]
NixOS = ""
Arch = "󰣇"
Macos = "󰀵"
Linux = "󰌽"

[username]
show_always = true
style_user = "bg:red fg:crust"
style_root = "bg:red fg:crust"
format = "[ $user]($style)"

[directory]
style = "bg:peach fg:crust"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = "…/"

[directory.substitutions]
Documents = "󰈙 "
Downloads = " "
Music = "󰝚 "
Pictures = " "
Developer = "󰲋 "

[git_branch]
symbol = ""
style = "bg:yellow"
format = "[[ $symbol $branch ](fg:crust bg:yellow)]($style)"

[git_status]
style = "bg:yellow"
format = "[[($all_status$ahead_behind )](fg:crust bg:yellow)]($style)"

[nix_shell]
symbol = "❄️ "
format = "via [$symbol]($style) "

[character]
success_symbol = "[❯](bold fg:green)"
error_symbol = "[❯](bold fg:red)"
vimcmd_symbol = "[❮](bold fg:green)"

[cmd_duration]
show_milliseconds = true
format = "took $duration "
min_time_to_notify = 45000

[time]
disabled = false
time_format = "%R"
format = "[  $time ](fg:text)"

[palettes.catppuccin_mocha]
rosewater = "#f5e0dc"
flamingo = "#f2cdcd"
pink = "#f5c2e7"
mauve = "#cba6f7"
red = "#f38ba8"
maroon = "#eba0ac"
peach = "#fab387"
yellow = "#f9e2af"
green = "#a6e3a1"
teal = "#94e2d5"
sky = "#89dceb"
sapphire = "#74c7ec"
blue = "#89b4fa"
lavender = "#b4befe"
text = "#cdd6f4"
subtext1 = "#bac2de"
subtext0 = "#a6adc8"
overlay2 = "#9399b2"
overlay1 = "#7f849c"
overlay0 = "#6c7086"
surface2 = "#585b70"
surface1 = "#45475a"
surface0 = "#313244"
base = "#1e1e2e"
mantle = "#181825"
crust = "#11111b"
EOF
  ok "starship.toml 已写入"

  # ---- ~/.config/sheldon/plugins.toml ----
  info "写入 ~/.config/sheldon/plugins.toml"
  write_config "$CONFIG_DIR/sheldon/plugins.toml" <<'EOF'
# plugins.toml — Sheldon 插件（对应 home/base/core/shell.nix）
shell = "zsh"

[templates]
# `-p` 关闭 reset-prompt：zsh-defer 默认带 `p` 选项时，若 `$+RPS1 == 0`
# 会执行 `RPS1=`，而 starship 只写 RPROMPT 不写 RPS1（zsh 对两者
# 的 set 状态独立记录），导致 right_format（RPROMPT）被清空。
defer = "{% for file in files %}zsh-defer -p source \"{{ file }}\"\n{% endfor %}"

[plugins]

[plugins.zsh-defer]
github = "romkatv/zsh-defer"

[plugins.zsh-completions]
github = "zsh-users/zsh-completions"

[plugins.you-should-use]
github = "MichaelAquilina/zsh-you-should-use"

[plugins.ohmyzsh-plugin]
github = "ohmyzsh/ohmyzsh"
dir = "plugins"
use = ["{command-not-found,git,sudo,systemd,extract,fzf}/*.plugin.zsh"]
apply = ["defer"]
EOF
  ok "sheldon plugins.toml 已写入"

  # 生成 plugins.lock（与 plugins.toml 同步）
  if have sheldon; then
    info "运行 sheldon lock 生成 plugins.lock（首次会 clone 插件）..."
    sheldon lock || warn "sheldon lock 失败，可稍后手动执行"
    ok "sheldon lock 完成"
  fi

  # ---- ~/.config/bat/config ----
  info "写入 ~/.config/bat/config"
  write_config "$CONFIG_DIR/bat/config" <<'EOF'
--pager="less -FR"
--theme="TwoDark"
--map-syntax="*.conf:INI"
--map-syntax=".ignore:Git Ignore"
EOF
  ok "bat config 已写入"

  # ---- ~/.config/tealdeer/config.toml ----
  info "写入 ~/.config/tealdeer/config.toml"
  write_config "$CONFIG_DIR/tealdeer/config.toml" <<'EOF'
[display]
compact = false
use_pager = true

[updates]
auto_update = false
auto_update_interval_hours = 720
EOF
  ok "tealdeer config 已写入"

  # ---- ~/.config/btop/btop.conf ----
  info "写入 ~/.config/btop/btop.conf"
  write_config "$CONFIG_DIR/btop/btop.conf" <<'EOF'
theme_background = False
vim_keys = True
EOF
  ok "btop config 已写入"

  # ---- ~/.config/yazi/yazi.toml ----
  info "写入 ~/.config/yazi/yazi.toml"
  write_config "$CONFIG_DIR/yazi/yazi.toml" <<'EOF'
[manager]
show_hidden = true
show_symlink = true
EOF
  ok "yazi config 已写入"

  # ---- ~/.config/atuin/config.toml ----
  info "写入 ~/.config/atuin/config.toml"
  write_config "$CONFIG_DIR/atuin/config.toml" <<'EOF'
update_check = false
search_mode = "fuzzy"
filter_mode = "global"
style = "compact"
inline_height = 40
sync_frequency = "0"

[sync]
records = false
EOF
  ok "atuin config 已写入"

  # ---- ~/.tmux.conf ----
  info "写入 ~/.tmux.conf"
  write_config "$HOME_DIR/.tmux.conf" <<'EOF'
# ~/.tmux.conf — 对应 home/base/core/cli.nix
set -g default-terminal "screen-256color"
set -g base-index 1
set -g escape-time 0
set -g mode-keys vi
set -g history-limit 50000
set -g mouse on
set -g clock-mode-style 24

# prefix 键改为 Ctrl-a
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# 分屏快捷键（在当前目录）
set -g pane-base-index 1
set -g renumber-windows on
bind -r | split-window -h -c "#{pane_current_path}"
bind -r - split-window -v -c "#{pane_current_path}"
EOF
  ok "~/.tmux.conf 已写入"

  # ---- ~/.config/nvim/init.lua（LazyVim bootstrap） ----
  info "写入 ~/.config/nvim/init.lua"
  write_config "$CONFIG_DIR/nvim/init.lua" <<'EOF'
-- ~/.config/nvim/init.lua — LazyVim bootstrap（对应 home/base/tui/neovim.nix）
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
  },
  defaults = {
    lazy = true,
    version = false,
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = { enabled = true, notify = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
EOF
  ok "nvim init.lua 已写入"

  # ---- Git 全局配置（用 git config 避免转义问题） ----
  info "写入 Git 全局配置"
  git config --global user.name  "$GIT_USER_NAME"
  git config --global user.email "$GIT_USER_EMAIL"
  git config --global init.defaultBranch main
  git config --global push.autoSetupRemote true
  git config --global pull.rebase true
  git config --global core.pager delta
  git config --global interactive.diffFilter "delta --color-only"
  git config --global merge.conflictstyle diff3
  git config --global diff.colorMoved default
  git config --global delta.diff-so-fancy true
  git config --global delta.line-numbers true
  git config --global delta.true-color always

  git config --global alias.br branch
  git config --global alias.co checkout
  git config --global alias.st status
  git config --global alias.ls 'log --pretty=format:"%C(yellow)%h%Cred%d %Creset%s%Cblue [%cn]" --decorate'
  git config --global alias.ll 'log --pretty=format:"%C(yellow)%h%Cred%d %Creset%s%Cblue [%cn]" --decorate --numstat'
  git config --global alias.cm 'commit -m'
  git config --global alias.ca 'commit -am'
  git config --global alias.dc 'diff --cached'
  git config --global alias.amend 'commit --amend -m'
  git config --global alias.unstage 'reset HEAD --'
  git config --global alias.merged 'branch --merged'
  git config --global alias.unmerged 'branch --no-merged'
  git config --global alias.nonexist 'remote prune origin --dry-run'
  git config --global alias.delmerged '! git branch --merged | egrep -v "(^\*|main|master|dev|staging)" | xargs git branch -d'
  git config --global alias.delnonexist 'remote prune origin'
  git config --global alias.update 'submodule update --init --recursive'
  git config --global alias.foreach 'submodule foreach'
  ok "Git 配置已写入（user.name=$GIT_USER_NAME / user.email=$GIT_USER_EMAIL）"

  # ---- git-lfs 初始化 ----
  if have git-lfs; then git lfs install >/dev/null 2>&1 && ok "git-lfs 已初始化"; fi
}

# ---------- 设置默认 shell ----------
set_default_shell() {
  section "设置默认 shell"
  local zsh_bin
  zsh_bin="$(command -v zsh)"
  if [ -z "$zsh_bin" ]; then warn "未找到 zsh，跳过"; return 0; fi
  if [ "$(basename "$SHELL")" = "zsh" ]; then
    ok "默认 shell 已是 zsh"
    return 0
  fi
  info "将默认 shell 切换为 zsh（$zsh_bin）——需要输入密码："
  if chsh -s "$zsh_bin"; then
    ok "默认 shell 已切换为 zsh，重新登录后生效"
  else
    warn "chsh 失败，可稍后手动执行：chsh -s $zsh_bin"
  fi
}

# ---------- 汇总 ----------
summary() {
  section "安装完成，摘要如下"
  printf "  ${CYAN}Shell${NC}     : zsh + starship + sheldon + atuin + direnv\n"
  printf "  ${CYAN}CLI${NC}       : eza bat fzf zoxide tealdeer ripgrep fd tmux fastfetch dust duf doggo\n"
  printf "  ${CYAN}TUI${NC}       : yazi btop superfile\n"
  printf "  ${CYAN}Git${NC}       : git git-lfs delta lazygit gh\n"
  printf "  ${CYAN}Editor${NC}    : neovim + LazyVim\n\n"

  printf "  ${BOLD}下一步：${NC}\n"
  printf "    1. 重新登录（或 exec zsh）使默认 shell 生效\n"
  printf "    2. 首次启动 nvim 会自动安装 LazyVim 插件（需 Node.js 已装）\n"
  printf "    3. 若 sheldon 插件未加载，先执行：sheldon lock && exec zsh\n"
  printf "    4. 确认语言环境存在：locale | grep zh_CN.UTF-8（无则 sudo locale-gen zh_CN.UTF-8）\n"
}

# ---------- 主流程 ----------
main() {
  printf "${BOLD}${WHITE}============================================================${NC}\n"
  printf "${BOLD}${WHITE}  Ubuntu / Debian Shell 环境一键安装（nixConfig 提取）${NC}\n"
  printf "${BOLD}${WHITE}============================================================${NC}\n"

  detect_os
  check_user

  mkdir -p "$LOCAL_BIN"
  export PATH="$HOME_DIR/bin:$LOCAL_BIN:$PATH"

  install_apt
  install_scripts
  install_releases
  install_neovim
  deploy_configs
  set_default_shell
  summary
}

main "$@"
