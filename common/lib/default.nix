# common/lib/default.nix — 纯 Nix 辅助函数库
{ lib }:
{
  # scanPaths: 自动扫描目录下所有 .nix 文件（排除 default.nix）
  # 用法: imports = lib.custom.scanPaths ./.;
  scanPaths = path:
    lib.pipe (builtins.readDir path) [
      (lib.filterAttrs (name: type:
        type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"))
      (lib.mapAttrsToList (name: _: path + "/${name}"))
    ];
}
