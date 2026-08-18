# modules/linux/dev/docker.nix — Docker 支持（开发环境）
#
# 项目开发用容器环境：
#   - docker           — 容器引擎（守护进程 + CLI + docker compose 插件）
#   - docker-compose   — 独立 compose 工具（命令 docker-compose，v2 独立包）
#
# 启用后把当前用户加入 docker 组，免 sudo 使用 docker。
{ config, lib, pkgs, ... }:

let
  cfg = config.modules-nixos-dev-docker;
in
{
  options.modules-nixos-dev-docker = {
    enable = lib.mkEnableOption "Docker（守护进程 + docker + docker-compose）";
  };

  config = lib.mkIf cfg.enable {
    # Docker 守护进程（NixOS 原生）
    virtualisation.docker.enable = true;

    # 用户加入 docker 组（免 sudo）
    users.users.${config.mySystem.user}.extraGroups = [ "docker" ];

    # CLI + 独立 docker-compose 命令
    environment.systemPackages = with pkgs; [
      docker          # docker CLI + docker compose 插件
      docker-compose  # 独立 docker-compose 命令
    ];
  };
}
