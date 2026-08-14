# modules/base/default.nix — modules/base 聚合入口（跨平台系统）
#
# 按类别导入：core（核心）/ ai（AI 系统支持）。
# 被 output/X86_64-linux 导入。
{ lib, ... }:
{
  imports = [
    ./core
    ./ai
  ];
}
