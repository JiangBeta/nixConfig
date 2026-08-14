# modules/linux/server/default.nix — Linux 服务器聚合（docker 等）
#
# 仅服务器主机导入（nuc8-s / appgateway / xiaobaonas）。
# 自动收集当前目录下所有 .nix 子模块。
{ lib, ... }:
{
  imports = lib.pipe (builtins.readDir ./.) [
    (lib.filterAttrs (name: type:
      type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"))
    (lib.mapAttrsToList (name: _: ./. + "/${name}"))
  ];
}
