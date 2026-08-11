# home/linux/default.nix — Linux Home Manager 入口
#
# 导入跨平台 home/base/ 模块，并启用所有 base 子模块。
# 被 output/X86_64-linux 通过 home-manager.users.<name> 引用。
{ pkgs, ... }:
{
  imports = [ ../base ];

  # 启用所有 base 模块
  modules-home-base-shell.enable = true;
  modules-home-base-cli.enable = true;
  modules-home-base-git.enable = true;
  modules-home-base-tui.enable = true;
  modules-home-base-neovim.enable = true;

  # XDG 用户目录
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  # Linux 专属用户级包
  home.packages = with pkgs; [
    brightnessctl  # 屏幕亮度控制
  ];
}
