# home/base/tui/default.nix — 终端/TUI 应用聚合（neovim / apps）
#
# 自动收集当前目录下所有 .nix 子模块。
{ lib, ... }:
{
  imports = lib.pipe (builtins.readDir ./.) [
    (lib.filterAttrs (name: type:
      type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"))
    (lib.mapAttrsToList (name: _: ./. + "/${name}"))
  ];
}
