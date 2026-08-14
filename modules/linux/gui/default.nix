# modules/linux/gui/default.nix — Linux 桌面系统聚合（audio / bluetooth / fcitx5 / flatpak / ly / niri / noctalia）
#
# 仅桌面主机导入（server 不需要）。
{ lib, ... }:
let
  custom = import ../../../common/lib { inherit lib; };
in
{
  imports = custom.scanPaths ./.;
}
