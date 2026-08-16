# modules/base/gui/default.nix — 跨平台桌面模块聚合（sunshine）
#
# 自动收集当前目录 .nix 子模块。
# 被 modules/base/default.nix 导入。
{ lib, ... }:
let
  custom = import ../../../common/lib { inherit lib; };
in
{
  imports = custom.scanPaths ./.;
}
