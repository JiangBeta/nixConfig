# home/base/gui/typora.nix — Typora Markdown 编辑器
#
# 跨平台：Linux 与 macOS 均可用（nixpkgs 提供双平台包）。
{ config, lib, pkgs, ... }:
let
  cfg = config.modules-home-base-gui-typora;
in
{
  options.modules-home-base-gui-typora = {
    enable = lib.mkEnableOption "Typora Markdown 编辑器";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.typora ];
  };
}
