# common/lib/default.nix — 纯 Nix 辅助函数库
#
# 供各类别聚合 default.nix 复用（消除内联 builtins.readDir 重复），用法：
#   { lib, ... }:
#   let
#     custom = import ../../../common/lib { inherit lib; };
#   in { imports = custom.scanPaths ./.; }
{ lib }:
{
  # scanPaths: 自动扫描目录下所有 .nix 文件（排除 default.nix）
  scanPaths = path:
    lib.pipe (builtins.readDir path) [
      (lib.filterAttrs (name: type:
        type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"))
      (lib.mapAttrsToList (name: _: path + "/${name}"))
    ];
}
