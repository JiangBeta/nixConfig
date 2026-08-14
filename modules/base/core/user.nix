# modules/base/core/user.nix — 用户账号与权限（跨 NixOS / nix-darwin 共享）
{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem;
in
{
  # Zsh 系统级启用（配合 users.users.<name>.shell 使用）
  programs.zsh.enable = true;

  # 用户创建（消费 common/options/user.nix 定义的 mySystem.user）
  users.users.${cfg.user} = {
    isNormalUser = true;
    description = cfg.user;
    shell = pkgs.zsh;  # 默认 Shell
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      # "docker" — 后续启用 docker.nix 后取消注释
    ];
    # 密码在安装时通过 nixos-install 交互设置，此处留空
    # 后续可集成 agenix 管理 hashedPassword
  };

  # sudo 权限
  security.sudo = {
    enable = true;
    extraRules = [
      {
        groups = [ "wheel" ];
        commands = [ { command = "ALL"; options = [ "SETENV" ]; } ];
      }
    ];
  };
}
