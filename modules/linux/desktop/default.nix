# modules/linux/desktop/default.nix — Linux 桌面硬件聚合（camera）
#
# 仅桌面主机导入，按 mySystem.desktop.* 选项按主机启用（pro13 启用，nuc8-d 不启用）。
{ lib, ... }:
let
  custom = import ../../../common/lib { inherit lib; };
in
{
  imports = custom.scanPaths ./.;
}
