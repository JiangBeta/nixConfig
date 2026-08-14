# home/base/ai/default.nix — home/base/ai 模块聚合入口
#
# 自动收集当前目录 .nix 子模块，再显式导入子目录模块 claude_code。
# 被 home/base/default.nix 导入（imports = [ ./ai ]）。
# 模块用 modules-home-base-ai-<name>.enable 控制开关。
{ lib, ... }:
let
  custom = import ../../../common/lib { inherit lib; };
in
{
  imports = custom.scanPaths ./. ++ [ ./claude_code ];
}
