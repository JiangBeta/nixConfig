# home/base/tui/apps.nix — TUI 工具集合
#
# Yazi（文件管理器）+ btop（系统监视）+ superfile（文件管理器）
{ config, lib, pkgs, ... }:
let
  cfg = config.modules-home-base-tui-apps;
in
{
  options.modules-home-base-tui-apps = {
    enable = lib.mkEnableOption "TUI 工具（Yazi, btop, superfile）";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      superfile  # 双栏文件管理器
    ];

    # Yazi — 终端文件管理器
    programs.yazi = {
      enable = true;
      enableZshIntegration = true;
      shellWrapperName = "yy";
      settings.mgr = {
        show_hidden = true;
        show_symlink = true;
      };
    };

    # btop — 系统资源监视器
    programs.btop = {
      enable = true;
      settings = {
        theme_background = false;
        vim_keys = true;
      };
    };
  };
}
