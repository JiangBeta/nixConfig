# common/options/system.nix — 系统级 Option 声明
{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.mySystem = {
    # 启动方式：UEFI or BIOS
    bootMode = mkOption {
      type = types.enum [ "uefi" "bios" ];
      default = "uefi";
      description = "系统的引导模式：UEFI (systemd-boot) 或 BIOS (GRUB)";
    };

    # 防火墙
    firewall = mkOption {
      type = types.enum [ "nftables" "none" ];
      default = "nftables";
      description = "防火墙类型：nftables（NixOS 原生）或不启用";
    };
  };
}
