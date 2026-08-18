# modules/linux/dev/default.nix — Linux 开发环境聚合（docker 等）
#
# 仅桌面/开发主机导入（pro13 等）。
# 模块用 modules-nixos-dev-<name>.enable 控制开关。
{ lib, ... }:
let
  custom = import ../../../common/lib { inherit lib; };
in
{
  imports = custom.scanPaths ./.;
}
