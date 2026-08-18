# home/base/dev/go.nix — Go 工具链（Go + gopls + golangci-lint + delve）
#
# 项目开发用 Go 编译与运行环境：
#   - go            — Go 编译器（默认最新稳定版，可经 package 选项固定版本）
#   - gopls         — Go 语言服务器（编辑器补全 / 跳转 / 重构）
#   - golangci-lint — Go 代码检查（静态分析 + lint）
#   - delve         — Go 调试器（命令 dlv）
#
# ⚠️ 当前 nixpkgs 已移除 go_1_22 / go_1_23（EOL），可选固定版本仅 go_1_26 / go_1_27(rc)。
{ config, lib, pkgs, ... }:

let
  cfg = config.modules-home-base-dev-go;
in
{
  options.modules-home-base-dev-go = {
    enable = lib.mkEnableOption "Go 工具链（go + gopls + golangci-lint + delve）";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.go;
      description = "Go 编译器包。默认 pkgs.go（最新稳定版）；可改 pkgs.go_1_26 固定版本。";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
      pkgs.gopls           # Go 语言服务器
      pkgs.golangci-lint   # Go 代码检查
      pkgs.delve           # Go 调试器（dlv）
    ];
  };
}
