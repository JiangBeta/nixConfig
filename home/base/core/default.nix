# home/base/core/default.nix — 基础环境聚合（shell / git / cli）
{ lib, ... }:
let
  custom = import ../../../common/lib { inherit lib; };
in
{
  imports = custom.scanPaths ./.;
}
