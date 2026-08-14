# modules/linux/gui/fcitx5.nix — Fcitx5 系统级 IM 模块注册
#
# 桌面专属：仅负责注册 GTK2/3/Qt IM 模块路径（系统级）。
# 用户端配置（rime 数据、主题、session 环境变量）由 home/linux/gui/fcitx5.nix 处理。
{ pkgs, ... }:
{
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5 = {
      waylandFrontend = true; # 走 text-input-v3（waylandim），不强制 GTK/QT_IM_MODULE 环境变量
      addons = with pkgs; [ fcitx5-gtk ];
    };
  };
}
