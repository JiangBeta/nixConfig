# hosts/pro13/networking.nix — pro13 网络与防火墙配置
{ config, lib, ... }:

let
  cfg = config.mySystem;
in
{
  # ==================== NetworkManager + iwd ====================
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd"; # 使用 iwd 作为 WiFi 后端（对齐 Arch 脚本）
  };

  # iwd 无线守护进程
  networking.wireless.iwd = {
    enable = true;
  };

  # ==================== nftables 防火墙 ====================
  networking.firewall = lib.mkIf (cfg.firewall == "nftables") {
    enable = true;
    # 默认：入站拒绝，出站允许
    allowedTCPPorts = [
      22 #（如需远程访问取消注释）
    ];
    allowedUDPPorts = [ ];
  };
}
