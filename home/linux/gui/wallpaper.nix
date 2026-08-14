# home/linux/gui/wallpaper.nix — Bing 每日壁纸
#
# 数据源：Bing 每日壁纸（HPImageArchive），下载后经 awww（swww 改名）设为桌面壁纸。
# - awww-daemon：壁纸渲染守护进程（随 graphical-session.target 启动）
# - bing-wallpaper：获取并设置壁纸（可手动指定 idx=0 今天 / 1 昨天 / …）
# - bing-wallpaper.timer：每日自动轮换（登录后 30 秒先设一次）
{ config, lib, pkgs, ... }:
let
  cfg = config.modules-home-linux-gui-wallpaper;

  # systemd user 服务不在图形会话里，需显式注入 Wayland 环境
  waylandEnv = [
    "WAYLAND_DISPLAY=wayland-1"
    "XDG_RUNTIME_DIR=%t"
  ];

  bing-wallpaper = pkgs.writeShellApplication {
    name = "bing-wallpaper";
    runtimeInputs = with pkgs; [ curl jq coreutils awww ];
    text = ''
      # 获取 Bing 每日壁纸并设为桌面壁纸
      # 用法：bing-wallpaper [idx]   # idx=0 今天，1 昨天，…（默认 0）
      set -euo pipefail
      idx=$1
      [ -z "$idx" ] && idx=0
      mkt=zh-CN
      dir="$HOME/.local/share/wallpapers/bing"
      mkdir -p "$dir"

      # 1. 获取元数据
      json=$(curl -fsS "https://www.bing.com/HPImageArchive.aspx?format=js&idx=$idx&n=1&mkt=$mkt")

      # 2. 提取 urlbase（不含分辨率）+ 壁纸日期
      urlbase=$(printf '%s' "$json" | jq -r '.images[0].urlbase')
      date=$(printf '%s' "$json" | jq -r '.images[0].startdate')

      # 3. 下载（UHD 优先，失败回退 1920x1080）
      out="$dir/$date.jpg"
      base="https://www.bing.com$urlbase"
      curl -fsS -o "$out" "$base"_UHD.jpg || curl -fsS -o "$out" "$base"_1920x1080.jpg

      # 4. 设为壁纸（awww 未运行时忽略）
      if command -v awww >/dev/null 2>&1; then
        awww img "$out" --transition-type any || true
      fi

      printf '%s\n' "$out"
    '';
  };
in
{
  options.modules-home-linux-gui-wallpaper = {
    enable = lib.mkEnableOption "Bing 每日壁纸";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.awww bing-wallpaper ];

    # awww-daemon：壁纸渲染守护进程
    systemd.user.services.awww-daemon = {
      Unit = {
        Description = "awww wallpaper daemon";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${lib.getExe' pkgs.awww "awww-daemon"}";
        Environment = waylandEnv;
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    # bing-wallpaper：设置壁纸（首次 + 每日轮换）
    systemd.user.services.bing-wallpaper = {
      Unit = {
        Description = "Set Bing wallpaper of the day";
        After = [ "awww-daemon.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${lib.getExe bing-wallpaper}";
        Environment = waylandEnv;
      };
    };
    systemd.user.timers.bing-wallpaper = {
      Unit = { Description = "Daily Bing wallpaper update"; };
      Timer = {
        OnActiveSec = "30";      # 登录 30 秒后先设一次
        OnCalendar = "daily";    # 之后每天轮换
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
