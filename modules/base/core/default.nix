# modules/base/core/default.nix — 跨平台系统核心聚合（user / fonts）
{ lib, ... }:
let
  custom = import ../../../common/lib { inherit lib; };
in
{
  imports = custom.scanPaths ./.;
}
