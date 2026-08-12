# modules/base/ai/default.nix — 系统级 AI 模块聚合入口
#
# 自动收集当前目录下所有 .nix 子模块。
# 被 output/X86_64-linux 通过 modules 列表导入。
{ lib, ... }:
{
  imports = lib.pipe (builtins.readDir ./.) [
    (lib.filterAttrs (name: type:
      type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"))
    (lib.mapAttrsToList (name: _: ./. + "/${name}"))
  ];
}
