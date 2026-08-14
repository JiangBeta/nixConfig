# home/base/tui/default.nix — 终端/TUI 应用聚合（neovim / apps）
{ lib, ... }:
let
  custom = import ../../../common/lib { inherit lib; };
in
{
  imports = custom.scanPaths ./.;
}
