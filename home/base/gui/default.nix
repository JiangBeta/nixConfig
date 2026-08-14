# home/base/gui/default.nix — 图形界面应用聚合（kitty / browsers / typora / fcitx5）
{ lib, ... }:
let
  custom = import ../../../common/lib { inherit lib; };
in
{
  imports = custom.scanPaths ./.;
}
