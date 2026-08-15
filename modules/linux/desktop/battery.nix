# modules/linux/desktop/battery.nix — 电池监控（upower 守护进程 + CLI 工具）
#
# pro13 为笔记本，内置电池。Noctalia Shell 状态栏的电池模块通过 D-Bus
# 接口 org.freedesktop.UPower 读取电量/充电状态，故需启用 upower 守护进程；
# 另安装 upower / acpi CLI 供命令行查看。
{ config, lib, pkgs, ... }:

let
  cfg = config.mySystem.desktop.battery;
in
{
  config = lib.mkIf cfg.enable {
    # upower 守护进程：提供 org.freedesktop.UPower D-Bus 接口
    #（Noctalia 状态栏电池模块、upower -d 等均依赖）
    services.upower.enable = true;

    # 电池/电源 CLI 工具
    environment.systemPackages = with pkgs; [
      upower   # upower -d / upower -i /org/freedesktop/UPower/devices/battery_BAT0
      acpi     # acpi -V 快速查看电池状态
    ];
  };
}
