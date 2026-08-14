# modules/linux/server/default.nix — Linux 服务器聚合（docker 等）
#
# 仅服务器主机导入（nuc8-s / appgateway / xiaobaonas）。
{ lib, ... }:
let
  custom = import ../../../common/lib { inherit lib; };
in
{
  imports = custom.scanPaths ./.;
}
