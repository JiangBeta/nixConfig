# home/linux/default.nix — Linux Home Manager 入口
#
# 导入跨平台 home/base/ + Linux 桌面 GUI 模块。
# 被 output/X86_64-linux 通过 home-manager.users.<name> 引用。
{ pkgs, ... }:
{
  imports = [
    ../base
    ../base/ai
    ./Desktop
  ];

  # 启用 base 模块
  modules-home-base-shell.enable = true;
  modules-home-base-cli.enable = true;
  modules-home-base-git.enable = true;
  modules-home-base-tui.enable = true;
  modules-home-base-neovim.enable = true;
  modules-home-base-kitty.enable = true;
  modules-home-base-browsers.enable = true;
  modules-home-base-fcitx5.enable = true;

  # 启用桌面 GUI 模块
  modules-home-linux-desktop-niri.enable = true;
  modules-home-linux-desktop-noctalia.enable = true;
  modules-home-linux-desktop-fcitx5.enable = true;
  modules-home-linux-desktop-gtk.enable = true;
  modules-home-linux-desktop-xdg.enable = true;

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
