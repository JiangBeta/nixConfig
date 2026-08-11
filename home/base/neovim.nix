# home/base/neovim.nix — Neovim 最小配置
#
# 仅安装 Neovim + 设置默认编辑器别名。
# 详细插件配置（LazyVim）后续迭代。
{ config, lib, ... }:
let
  cfg = config.modules-home-base-neovim;
in
{
  options.modules-home-base-neovim = {
    enable = lib.mkEnableOption "Neovim 编辑器（最小配置）";
  };

  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      vimAlias = true;
      viAlias = true;
    };
  };
}
