# modules/linux/core/btrfs.nix — Btrfs autoScrub + Snapper 定时快照
{ config, pkgs, lib, ... }:

let
  enableSnapper = config.mySystem.hardware.btrfs.enableSnapper;
in
{
  # 启用 Btrfs 定期 Scrub 校验
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  # 1. 只有当开启快照时，才部署软链接与 Snapper 定时服务
  systemd.tmpfiles.rules = lib.mkIf enableSnapper [
    "d /snapper/root_snap 0750 root root -"
    "L+ /.snapshots - - - - /snapper/root_snap"

    "d /snapper/home_snap 0750 root root -"
    "L+ /home/.snapshots - - - - /snapper/home_snap"

    "d /snapper/nix_snap 0750 root root -"
    "L+ /nix/.snapshots - - - - /snapper/nix_snap"
  ];

  # 2. Snapper 快照策略设置
  services.snapper = {
    snapshotInterval = "hourly";
    cleanupInterval = "1d";
    configs = {
      root = {
        SUBVOLUME = "/";
        ALLOW_USERS = [ config.mySystem.user ];
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        NUMBER_LIMIT = "10";
        TIMELINE_LIMIT_HOURLY = "3";
        TIMELINE_LIMIT_DAILY = "1";
        TIMELINE_LIMIT_WEEKLY = "0";
      };
      home = {
        SUBVOLUME = "/home";
        ALLOW_USERS = [ config.mySystem.user ];
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        NUMBER_LIMIT = "10";
        TIMELINE_LIMIT_HOURLY = "3";
        TIMELINE_LIMIT_DAILY = "1";
        TIMELINE_LIMIT_WEEKLY = "0";
      };
      nix = {
        SUBVOLUME = "/nix";
        ALLOW_USERS = [ config.mySystem.user ];
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        NUMBER_LIMIT = "10";
        TIMELINE_LIMIT_HOURLY = "3";
        TIMELINE_LIMIT_DAILY = "1";
        TIMELINE_LIMIT_WEEKLY = "0";
      };
    };
  };
}
