# modules/base/core/default.nix — 跨平台系统核心聚合（user / fonts）
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
