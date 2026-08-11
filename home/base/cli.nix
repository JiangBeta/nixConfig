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
    enable = lib.mkEnableOption "CLI 替代工具（eza, bat, fd, ripgrep, fzf, zoxide, tldr, fastfetch, dust, duf, doggo, aria2）";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      fastfetch   # 系统信息（dotfile/config/fastfetch/config.toml）
      dust        # du 替代
      duf         # df 替代
      doggo       # dig 替代
      aria2       # 多协议下载
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
      config.pager = "less -FR";
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
  };
}
