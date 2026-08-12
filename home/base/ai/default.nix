# home/base/ai/default.nix — home/base/ai 模块聚合入口
#
# 自动收集当前目录下所有 .nix HM 子模块，再显式导入子目录模块。
# 被 home/linux/default.nix 导入（imports = [ ../base/ai ]）。
# 模块用 modules-home-base-ai-<name>.enable 控制开关。
{ lib, ... }:
{
  imports = lib.pipe (builtins.readDir ./.) [
      (lib.filterAttrs (name: type:
        type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"))
      (lib.mapAttrsToList (name: _: ./. + "/${name}"))
    ]
    # 显式导入子目录模块（不会被自动扫描覆盖）
    ++ [ ./claude_code ];
}
