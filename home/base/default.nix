# home/base/default.nix — home/base 聚合入口（跨平台）
#
# 按类别导入：core（基础环境）/ tui（终端应用）/ gui（图形应用）/ ai（AI 工具）。
# 被 home/linux/default.nix 与（未来的）home/darwin/default.nix 导入。
{ lib, ... }:
{
  imports = [
    ./core
    ./tui
    ./gui
    ./ai
    ./dev
  ];

  home.stateVersion = "26.05";
}
