# home/base/dev/default.nix — 开发环境聚合（go / nodejs）
#
# 跨平台开发工具链（macOS + Linux 共用）。
# 被 home/base/default.nix 导入（imports = [ ./dev ]）。
# 模块用 modules-home-base-dev-<name>.enable 控制开关。
{ lib, ... }:
let
  custom = import ../../../common/lib { inherit lib; };
in
{
  imports = custom.scanPaths ./.;
}
