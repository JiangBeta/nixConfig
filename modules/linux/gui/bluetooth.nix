# modules/linux/gui/bluetooth.nix — 桌面蓝牙（bluez + blueman）
#
# 桌面专属：server 不需要蓝牙，故从 modules/linux/core/base.nix 上移至此。
{ ... }:
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;
}
