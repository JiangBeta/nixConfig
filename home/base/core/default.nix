# home/base/core/default.nix — 基础环境聚合（shell / git / cli）
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
