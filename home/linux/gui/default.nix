# home/linux/gui/default.nix — Linux 桌面 GUI 聚合入口
#
# 自动收集当前目录下所有 .nix 子模块。
# 被 home/linux/default.nix 导入。
{ lib, ... }:
{
  imports = lib.pipe (builtins.readDir ./.) [
    (lib.filterAttrs (name: type:
      type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"))
    (lib.mapAttrsToList (name: _: ./. + "/${name}"))
  ];
}
