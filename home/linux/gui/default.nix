# home/linux/gui/default.nix — Linux 桌面 GUI 聚合入口
#
# 被 home/linux/default.nix 导入。
{ lib, ... }:
let
  custom = import ../../../common/lib { inherit lib; };
in
{
  imports = custom.scanPaths ./.;
}
