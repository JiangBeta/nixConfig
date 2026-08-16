# modules/linux/gui/pynergy.nix — synergy 协议键鼠共享客户端
#
# pynergy：基于 Synergy 协议的键鼠共享客户端，兼容 Deskflow 等 synergy 软件。
# 作为「被控制端」，接收另一台机器（运行 Deskflow/synergy 服务端）的键鼠输入，
# 通过 uinput 内核模块注入本机（Wayland 下无需 RemoteDesktop portal）。
{ config, lib, pkgs, inputs, ... }:
{
  # uinput 虚拟输入设备支持（pynergy 注入键鼠依赖 /dev/uinput）
  hardware.uinput.enable = true;
  users.users.${config.mySystem.user}.extraGroups = [ "uinput" ];

  # pynergy 客户端包（flake 仅提供 package，无 nixosModule）
  environment.systemPackages = [
    inputs.pynergy-client.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
