# home/base/shell.nix — Zsh + Starship + Sheldon + Atuin + Direnv
#
# 参考：
#   - dotfile/zshrc（别名、fastfetch 启动、zoxide+fzf 集成）
#   - dotfile/config/anyconf/starship.toml（Catppuccin Mocha 配色）
#   - dotfile/config/sheldon/plugins.toml（插件列表）
#   - 旧 home/base/shell.nix（mkEnableOption 模式）
{ config, lib, pkgs, ... }:
let
  cfg = config.modules-home-base-shell;
in
{
  options.modules-home-base-shell = {
    enable = lib.mkEnableOption "Zsh + Starship + Sheldon + Atuin Shell 环境";
  };

  config = lib.mkIf cfg.enable {
    # sheldon 的 plugins.lock 是状态文件（不在 HM 声明式管理内）。当
    # plugins.toml 内容变化时 lock 会过期，导致 `sheldon source` 仍按旧
    # 插件列表/模板渲染（例如丢失 `-p`、重复加载已删插件）。故在每次
    # switch 写入配置后自动重新 lock 一次，保证与 plugins.toml 同步。
    home.activation.relockSheldon = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.sheldon}/bin/sheldon lock
    '';

    # ==================== Zsh ====================
    programs.zsh = {
      enable = true;
      enableCompletion = true;

      syntaxHighlighting = {
        enable = true;
        # "main" 由 home-manager 自动包含（见 modules/programs/zsh/default.nix:586），
        # 再显式列出会产生重复的 main 高亮器。
        highlighters = [ "brackets" "pattern" "cursor" ];
      };

      autosuggestion = {
        enable = true;
        strategy = [ "history" ];
      };

      history = {
        size = 10000000;
        path = "${config.home.homeDirectory}/.zsh_history";
        extended = true;
        ignoreDups = true;
        ignoreSpace = true;
        append = true;
        share = true;
        save = 10000;
      };

      # 来自 dotfile/zshrc
      initExtra = ''
        # ---- PATH ----
        export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

        # ---- 语言 ----
        export LANG="zh_CN.UTF-8"
        export LC_ALL="zh_CN.UTF-8"

        # ---- 编辑器 ----
        export EDITOR="nvim"
        export VISUAL="nvim"

        # ---- zoxide 配置 ----
        export _ZO_DATA_DIR="$HOME/.local/share/zoxide"
        export _ZO_EXCLUDE_DIRS="$HOME/tmp:$HOME/Downloads/*:$HOME/.snapshots/*"
        export _ZO_RESOLVE_SYMLINKS=1

        # ---- FZF 配置 ----
        export FZF_WALKER_DEPTH=5
        export FZF_TMUX_HEIGHT="60%"
        export FZF_DEFAULT_OPTS='--preview "cat {}" --preview-window right:50%'
        export FZF_CTRL_R_OPTS="--scheme=history -i"
        export FZF_CTRL_T_OPTS='--preview "[[ -d {} ]] && tree -C {} || highlight -0 ansi {} 2> /dev/null"'

        # ---- zoxide + fzf 模糊搜索 (zx) ----
        zx() {
          local query="''${*}"
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

        # ---- Yazi（退出时 cd 到浏览目录） ----
        function y() {
          local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
          command yazi "$@" --cwd-file="$tmp"
          if [ -f "$tmp" ]; then
            local cwd="$(cat "$tmp")"
            [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
            rm -f "$tmp"
          fi
        }

        # ---- fastfetch 启动（不在 VSCode/Nvim 中） ----
        if [[ "$TERM_PROGRAM" != "vscode" && -z "$VSCODE_INJECTION" && -z "$NVIM" ]]; then
          fastfetch --pipe false
        fi
      '';

      shellAliases = {
        # nix
        nix-switch = "sudo nixos-rebuild switch --flake ${config.home.homeDirectory}/nixConfig";
        nix-update = "nix flake update";
        # ls → eza
        ls = "eza --icons --long --header";
        ll = "eza --icons --long --header --all";
        la = "eza --icons --long --header --all --git";
        tree = "eza --tree --icons";
        # cat → bat
        cat = "bat";
        # du → dust
        du = "dust";
        # 系统
        df = "duf";
        find = "fd";
        grep = "rg";
        top = "btop";
        help = "tldr";
        ip = "ip -color";
        myip = "curl -s ip.sb";
        # git
        g = "git"; ga = "git add"; gc = "git commit"; gp = "git push";
        gl = "git pull"; gst = "git status"; gd = "git diff";
        gco = "git checkout"; gb = "git branch";
        # lazygit
        lg = "lazygit";
        # docker
        d = "docker"; dc = "docker compose";
      };
    };

    # ==================== Starship ====================
    # 来自 dotfile/config/anyconf/starship.toml（Catppuccin Mocha）
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;

      settings = {
        "$schema" = "https://starship.rs/config-schema.json";

        format = ''
          [](red)$os$username[](bg:peach fg:red)$directory[](bg:yellow fg:peach)$git_branch$git_status[](fg:yellow bg:green)$c$rust$golang$nodejs$python[](fg:green bg:sapphire)$nix_shell[ ](fg:sapphire)$line_break$character'';

        right_format = ''$time$cmd_duration'';

        palette = "catppuccin_mocha";

        os = {
          disabled = false;
          style = "bg:red fg:crust";
          symbols = {
            NixOS = "";
            Arch = "󰣇";
            Macos = "󰀵";
            Linux = "󰌽";
          };
        };

        username = {
          show_always = true;
          style_user = "bg:red fg:crust";
          style_root = "bg:red fg:crust";
          format = "[ $user]($style)";
        };

        directory = {
          style = "bg:peach fg:crust";
          format = "[ $path ]($style)";
          truncation_length = 3;
          truncation_symbol = "…/";
          substitutions = {
            Documents = "󰈙 "; Downloads = " "; Music = "󰝚 ";
            Pictures = " "; Developer = "󰲋 ";
          };
        };

        git_branch = {
          symbol = "";
          style = "bg:yellow";
          format = "[[ $symbol $branch ](fg:crust bg:yellow)]($style)";
        };

        git_status = {
          style = "bg:yellow";
          format = "[[($all_status$ahead_behind )](fg:crust bg:yellow)]($style)";
        };

        nix_shell = { symbol = "❄️ "; format = "via [$symbol]($style) "; };

        character = {
          success_symbol = "[❯](bold fg:green)";
          error_symbol = "[❯](bold fg:red)";
          vimcmd_symbol = "[❮](bold fg:green)";
        };

        cmd_duration = {
          show_milliseconds = true;
          format = "took $duration ";
          min_time_to_notify = 45000;
        };

        time = {
          disabled = false;
          time_format = "%R";
          format = "[  $time ](fg:text)";
        };

        palettes.catppuccin_mocha = {
          rosewater = "#f5e0dc"; flamingo = "#f2cdcd"; pink = "#f5c2e7";
          mauve = "#cba6f7"; red = "#f38ba8"; maroon = "#eba0ac";
          peach = "#fab387"; yellow = "#f9e2af"; green = "#a6e3a1";
          teal = "#94e2d5"; sky = "#89dceb"; sapphire = "#74c7ec";
          blue = "#89b4fa"; lavender = "#b4befe"; text = "#cdd6f4";
          subtext1 = "#bac2de"; subtext0 = "#a6adc8"; overlay2 = "#9399b2";
          overlay1 = "#7f849c"; overlay0 = "#6c7086"; surface2 = "#585b70";
          surface1 = "#45475a"; surface0 = "#313244"; base = "#1e1e2e";
          mantle = "#181825"; crust = "#11111b";
        };
      };
    };

    # ==================== Sheldon ====================
    # 当前 HM 版本没有 programs.sheldon.plugins，
    # 使用 xdg.configFile 直接部署 plugins.toml
    programs.sheldon.enable = true;

    xdg.configFile."sheldon/plugins.toml".text = ''
      shell = "zsh"

      [templates]
      # `-p` 关闭 reset-prompt：zsh-defer 默认带 `p` 选项时，若 `$+RPS1 == 0`
      # 会执行 `RPS1=`，而 starship 只写 RPROMPT 不写 RPS1（zsh 对两者
      # 的 set 状态独立记录），导致 right_format（RPROMPT）被清空。
      defer = "{% for file in files %}zsh-defer -p source \"{{ file }}\"\n{% endfor %}"

      [plugins]
      [plugins.zsh-defer]
      github = "romkatv/zsh-defer"

      # zsh-autosuggestions / zsh-syntax-highlighting 已由 programs.zsh 的
      # autosuggestion / syntaxHighlighting 选项加载，此处不再重复 source。

      [plugins.zsh-completions]
      github = "zsh-users/zsh-completions"

      [plugins.you-should-use]
      github = "MichaelAquilina/zsh-you-should-use"

      [plugins.ohmyzsh-plugin]
      github = "ohmyzsh/ohmyzsh"
      dir = "plugins"
      use = ["{command-not-found,git,sudo,systemd,extract,fzf}/*.plugin.zsh"]
      apply = ["defer"]
    '';

    # ==================== Atuin ====================
    programs.atuin = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      settings = {
        update_check = false;
        search_mode = "fuzzy";
        filter_mode = "global";
        style = "compact";
        inline_height = 40;
        sync_frequency = "0";
        sync.records = false;
      };
    };

    # ==================== Direnv ====================
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
