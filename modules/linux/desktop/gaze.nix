# modules/linux/desktop/gaze.nix — Gaze 人脸识别登录（daemon + PAM + GUI）
#
# 消费 mySystem.desktop.faceAuth.enable；导入 GunduLabs/gaze 官方 NixOS 模块。
# 安装后运行 `gaze add-face` 录入人脸，`gaze-gui` 图形化管理，`gaze doctor` 自检。
{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.mySystem.desktop.faceAuth;
in
{
  imports = [ inputs.gaze.nixosModules.default ];

  config = lib.mkIf cfg.enable {
    services.gaze = {
      enable = true;
      gui.enable = true;

      # 人脸认证的 PAM 服务：sudo / polkit / login
      # login 用于 Ly（显示管理器）登录界面的人脸识别，失败回退密码
      pam.defaultServices = [
        "sudo"
        "polkit-1"
        "login"
      ];
    };
  };
}
