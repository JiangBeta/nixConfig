# modules/base/ai/default.nix — 系统级 AI 模块聚合入口
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
