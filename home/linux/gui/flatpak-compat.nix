# home/linux/gui/flatpak-compat.nix — Flatpak Wayland/Fcitx5 兼容 + 权限占位
#
# Obsidian（Electron）在 Wayland 下使用 fcitx5 输入法需追加 IME 参数，
# 覆盖 flatpak 自动生成的 .desktop（Exec 改用 nix store 中的 flatpak 绝对路径）。
# 参考：https://www.imxcai.com/linux/flatpak-obsidian-在-wayland-环境下使用-fcitx5-进行中文输入.html
{ config, lib, pkgs, ... }:
let
  cfg = config.modules-home-linux-gui-flatpak-compat;
in
{
  options.modules-home-linux-gui-flatpak-compat = {
    enable = lib.mkEnableOption "Flatpak Wayland/Fcitx5 兼容配置";
  };

  config = lib.mkIf cfg.enable {
    # Obsidian 专属：追加 --enable-wayland-ime --wayland-text-input-version=3 使 fcitx5 生效
    xdg.desktopEntries."md.obsidian.Obsidian" = {
      name = "Obsidian";
      exec = "${pkgs.flatpak}/bin/flatpak run --branch=stable --arch=x86_64 --command=obsidian.sh --file-forwarding md.obsidian.Obsidian @@u %U @@ --enable-wayland-ime --wayland-text-input-version=3";
      icon = "md.obsidian.Obsidian";
      comment = "Obsidian Markdown Notes";
      categories = [ "Office" "Utility" ];
      terminal = false;
      type = "Application";
      settings.StartupWMClass = "obsidian";
    };

    # ⚠️ 文件访问权限占位（待后续按需授权，由 Flatseal 管理）：
    # 部分沙盒应用（WeChat / WPS / Obsidian / Discord 等）默认无法访问宿主文件系统，
    # 后续可用 Flatseal 图形界面或命令行逐个授权，例如：
    #   flatpak override --user --filesystem=home md.obsidian.Obsidian
    # 此处暂不自动授权，避免过度放开沙盒权限。
  };
}
