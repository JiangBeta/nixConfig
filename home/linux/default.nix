# home/linux/default.nix — Linux Home Manager 入口
#
# 导入跨平台 home/base/（含 core/tui/gui/ai）+ Linux 专属 home/linux/gui/。
# 被 output/X86_64-linux 通过 home-manager.users.<name> 引用。
{ pkgs, ... }:
{
  imports = [
    ../base
    ./gui
  ];

  # ---- base 基础环境 ----
  modules-home-base-core-shell.enable = true;
  modules-home-base-core-git.enable = true;
  modules-home-base-core-cli.enable = true;

  # ---- base TUI 终端应用 ----
  modules-home-base-tui-neovim.enable = true;
  modules-home-base-tui-apps.enable = true;

  # ---- base GUI 图形应用 ----
  modules-home-base-gui-kitty.enable = true;
  modules-home-base-gui-browsers.enable = true;
  modules-home-base-gui-typora.enable = true;
  modules-home-base-gui-fcitx5.enable = true;

  # ---- Linux GUI 桌面 ----
  modules-home-linux-gui-niri.enable = true;
  modules-home-linux-gui-noctalia.enable = true;
  modules-home-linux-gui-fcitx5.enable = true;
  modules-home-linux-gui-gtk.enable = true;
  modules-home-linux-gui-xdg.enable = true;
  modules-home-linux-gui-apps.enable = true;
  modules-home-linux-gui-flatpak-compat.enable = true;
  modules-home-linux-gui-wallpaper.enable = true;

  # ---- AI 工具 ----
  modules-home-base-ai-nodejs.enable = true;

  # 共享 MCP 服务器（所有 AI 工具共用同一份 servers 定义）
  modules-home-base-ai-mcp = {
    enable = true;
    servers = {
      "codebase-memory-mcp" = {
        command = "/home/beta/.local/bin/codebase-memory-mcp";
      };
    };
  };

  # 共享 Skills / Hooks（所有 AI 工具共用，由 claude_code 等工具模块消费）
  modules-home-base-ai-skills.enable = true;
  modules-home-base-ai-hooks.enable = true;

  modules-home-base-ai-claudeCode.enable = true;

  # Linux 专属用户级包
  home.packages = with pkgs; [
    brightnessctl
  ];
}
