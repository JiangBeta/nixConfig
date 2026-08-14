# modules/linux/gui/default.nix — Linux 桌面系统聚合（audio / bluetooth / fcitx5 / flatpak / ly / niri / noctalia）
#
# 仅桌面主机导入（server 不需要）。
# 自动收集当前目录下所有 .nix 子模块。
{ lib, ... }:
{
  imports = lib.pipe (builtins.readDir ./.) [
    (lib.filterAttrs (name: type:
      type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"))
    (lib.mapAttrsToList (name: _: ./. + "/${name}"))
  ];
}
