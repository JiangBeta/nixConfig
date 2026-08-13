# home/base/cli.nix — CLI 替代工具集合
#
# 参考：
#   - dotfile/zshrc（别名映射 ls→eza, cat→bat, du→dust）
#   - dotfile/config/fastfetch/config.toml（系统信息展示）
#   - 旧 home/base/cli.nix（mkEnableOption 模式）
{ config, lib, pkgs, ... }:
let
  cfg = config.modules-home-base-cli;
in
{
  options.modules-home-base-cli = {
    enable = lib.mkEnableOption "CLI 替代工具（eza, bat, fd, ripgrep, fzf, zoxide, tldr, fastfetch, dust, duf, doggo, tmux）";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      fastfetch   # 系统信息（dotfile/config/fastfetch/config.toml）
      dust        # du 替代
      duf         # df 替代
      doggo       # dig 替代
    ];

    # eza — ls 替代
    programs.eza = {
      enable = true;
      git = true;
      icons = "auto";
    };

    # bat — cat 替代
    programs.bat = {
      enable = true;
      config = {
        pager = "less -FR";
        theme = "TwoDark";
        map-syntax = [
          "*.conf:INI"
          ".ignore:Git Ignore"
        ];
      };
    };

    # fzf — 模糊搜索
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      # 来自 dotfile/zshrc
      defaultOptions = [
        "--preview 'cat {}'"
        "--preview-window right:50%"
      ];
    };

    # zoxide — cd 替代
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
    };

    # tealdeer — tldr 客户端
    programs.tealdeer = {
      enable = true;
      enableAutoUpdates = true;
      settings = {
        display = { compact = false; use_pager = true; };
        updates = { auto_update = false; auto_update_interval_hours = 720; };
      };
    };

    # ripgrep — grep 替代
    programs.ripgrep.enable = true;

    # fd — find 替代
    programs.fd.enable = true;

    # tmux — 终端复用器
    programs.tmux = {
      enable = true;
      shortcut = "a";            # prefix 键 Ctrl-a（替代默认 Ctrl-b）
      baseIndex = 1;             # 窗口/面板编号从 1 开始
      escapeTime = 0;            # 消除 Esc 延迟（vi 模式响应）
      keyMode = "vi";            # vi 风格 copy-mode
      terminal = "screen-256color";
      historyLimit = 50000;
      mouse = true;
      clock24 = true;

      extraConfig = ''
        set -g pane-base-index 1
        set -g renumber-windows on
        bind -r | split-window -h -c "#{pane_current_path}"
        bind -r - split-window -v -c "#{pane_current_path}"
      '';
    };
  };
}
