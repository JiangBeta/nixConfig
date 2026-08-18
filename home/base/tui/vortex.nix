# home/base/tui/vortex.nix — vortex 服务器管理 TUI
#
# vortex：键盘优先的 TUI，通过 SSH 管理 Linux VPS 服务器集群（agentless，远端无需装 agent）。
# 配置：~/.config/vortex/config.yaml（服务器列表/认证/主题/键位，用户自行维护，不入库）。
# 来源：flake 输入 github:berkayyytech/vortex → packages.<system>.default（buildGoModule，二进制名 vortex）。
{ config, lib, pkgs, vortex, ... }:
let
  cfg = config.modules-home-base-tui-vortex;
in
{
  options.modules-home-base-tui-vortex = {
    enable = lib.mkEnableOption "vortex 服务器管理 TUI";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      vortex.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
