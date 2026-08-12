# home/linux/Desktop/browsers.nix — 浏览器（Zen Browser）
{ config, lib, pkgs, ... }:
let
  cfg = config.modules-home-linux-desktop-browsers;
in
{
  options.modules-home-linux-desktop-browsers = {
    enable = lib.mkEnableOption "Zen Browser + 中文输入法环境变量";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ zen-browser ];

    # 🌟 Wayland 原生 + Fcitx5 输入法环境变量
    #    确保从 Shell 或桌面启动器启动都能拿到
    home.sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
      SDL_IM_MODULE = "fcitx";
    };

    # 桌面入口注入环境变量（从 Noctalia / Niri 启动时也能拿到 fcitx）
    xdg.desktopEntries.zen-browser = {
      name = "Zen Browser";
      exec = "env MOZ_ENABLE_WAYLAND=1 GTK_IM_MODULE=fcitx QT_IM_MODULE=fcitx XMODIFIERS=@im=fcitx SDL_IM_MODULE=fcitx zen";
      icon = "zen-browser";
      terminal = false;
      categories = [ "Network" "WebBrowser" ];
      mimeType = [ "text/html" "x-scheme-handler/http" "x-scheme-handler/https" ];
    };
  };
}
