# modules/linux/gui/flatpak.nix — Flatpak 应用（Flathub + USTC 镜像）
#
# 系统级：启用 Flatpak 服务，声明式安装桌面应用与工具（稳定版），
# 并做 Wayland/Fcitx5 兼容（Electron 应用强制 ozone 走 Wayland text-input-v3）。
# 用户级 Obsidian 专属 IME 参数见 home/linux/gui/flatpak-compat.nix。
{ config, lib, pkgs, ... }:
let
  # Flathub 官方 remote 文件（首次添加用于拉取 GPG key / collection-id）
  flathubOfficial = "https://dl.flathub.org/repo/flathub.flatpakrepo";
  # USTC 缓存镜像（未命中时 302 回源 Flathub）
  flathubMirror = "https://mirrors.ustc.edu.cn/flathub";

  # 桌面应用（稳定版）
  flatpakApps = [
    "com.tencent.WeChat"              # 微信
    "org.telegram.desktop"            # 电报 Telegram
    "com.discordapp.Discord"          # Discord
    "md.obsidian.Obsidian"            # Obsidian 笔记
    "com.github.johnfactotum.Foliate" # Foliate 电子书阅读
    "com.wps.Office"                  # WPS Office
    "com.microsoft.Edge"              # Microsoft Edge
  ];

  # Flatpak 管理工具
  flatpakTools = [
    "com.github.tchx84.Flatseal"      # 权限管理（Flatseal）
    "io.github.kolunmi.Bazaar"        # 应用商店
    "io.github.flattool.Warehouse"    # 应用管理（彻底卸载）
    "it.mijorus.gearlever"            # AppImage 文件管理
  ];

  refs = flatpakApps ++ flatpakTools;

  # Electron/Chromium 应用（需 ozone 走 Wayland；Qt/GTK 应用原生 text-input-v3 无需处理）
  electronApps = [
    "com.discordapp.Discord"
    "md.obsidian.Obsidian"
    "com.microsoft.Edge"
  ];
in
{
  config = {
    services.flatpak.enable = true;

    # 声明式安装 + 兼容配置（幂等：已安装/已配置则跳过）
    # ⚠️ 用 Type=simple 而非 oneshot：oneshot 会让 systemctl start 阻塞到脚本跑完，
    #    导致 nixos-rebuild switch / boot 卡在安装期间（下载 11 个应用很慢）。
    #    simple 立即返回，安装在后台进行，不阻塞 switch。
    systemd.services.flatpak-setup = {
      description = "Flathub (USTC mirror) install + Wayland compat";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      path = [ config.services.flatpak.package pkgs.gnugrep pkgs.coreutils ];
      serviceConfig = {
        Type = "simple";
      };
      script = ''
        # 1. Flathub remote：先加官方 .flatpakrepo（拉取 GPG key），再切 USTC 镜像加速
        if ! flatpak remotes --system | grep -q '^flathub'; then
          flatpak remote-add --if-not-exists --system flathub ${flathubOfficial}
        fi
        flatpak remote-modify --system flathub --url=${flathubMirror}

        # 2. 逐个安装（已安装则跳过）
        for app in ${lib.concatStringsSep " " refs}; do
          if ! flatpak info --system "$app" >/dev/null 2>&1; then
            flatpak install --system --noninteractive --assumeyes flathub "$app"
          fi
        done

        # 3. Wayland 兼容：Electron/Chromium 应用强制 ozone=auto（启用 text-input-v3 输入法前端）
        ${lib.concatMapStringsSep "\n" (app: "flatpak override --system --env=ELECTRON_OZONE_PLATFORM_HINT=auto ${app}") electronApps}
      '';
    };
  };
}
