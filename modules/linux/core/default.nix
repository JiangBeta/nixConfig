# modules/linux/core/default.nix — Linux 核心系统聚合（base / boot / btrfs / disko）
#
# 所有 Linux 主机（桌面 + 服务器）均导入。
{ lib, ... }:
let
  custom = import ../../../common/lib { inherit lib; };
in
{
  imports = custom.scanPaths ./.;
}
