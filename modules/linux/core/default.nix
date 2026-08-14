# modules/linux/core/default.nix — Linux 核心系统聚合（base / boot / btrfs / disko）
#
# 所有 Linux 主机（桌面 + 服务器）均导入。
# 自动收集当前目录下所有 .nix 子模块。
{ lib, ... }:
{
  imports = lib.pipe (builtins.readDir ./.) [
    (lib.filterAttrs (name: type:
      type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"))
    (lib.mapAttrsToList (name: _: ./. + "/${name}"))
  ];
}
