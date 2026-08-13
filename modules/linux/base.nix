# modules/linux/base.nix — Linux 基础设置（对标 Arch 脚本功能）
{ config, pkgs, lib, ... }:

{
  # ==================== 时区与 Locale ====================
  time.timeZone = "Asia/Shanghai";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "zh_CN.UTF-8/UTF-8"
  ];

  # 键盘布局
  console.keyMap = "us";

  # ==================== Nix 核心设置 ====================
  nix.settings = {
    # 中国镜像 substituters（TUNA 镜像 + 官方回退）
    substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
  };

  # 自动垃圾回收
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nixpkgs.config.allowUnfree = true;

  # ==================== 电源管理：power-profiles-daemon ====================
  # 工具由服务自动安装；默认 profile 为 balanced（平衡），随系统服务启动。
  services.power-profiles-daemon.enable = true;

  # ==================== 蓝牙 ====================
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # ==================== 固件 ====================
  hardware.enableAllFirmware = true;

  # ==================== Fcitx5 系统级 — GTK/Qt IM 模块注册 ====================
  # 仅负责注册 IM 模块路径，用户端配置（rime、theme 等）由 HM fcitx5.nix 处理
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5 = {
      waylandFrontend = true; # 走 text-input-v3（waylandim），不强制 GTK/QT_IM_MODULE 环境变量
      addons = with pkgs; [ fcitx5-gtk ];
    };
  };

  # ==================== 基础系统包 ====================
  environment.systemPackages = with pkgs; [
    # 基础工具
    curl
    git
    vim
    tldr
    bash-completion
    chezmoi
    just

    # 文件系统工具
    btrfs-progs
    dosfstools
  ];

  # ==================== FHS 兼容 ====================
  # 让硬编码 /usr/bin 等 FHS 路径的程序（如 meatshell SSH 客户端）能找到系统工具
  services.envfs.enable = true;

  # Bash 补全
  programs.bash.completion.enable = true;

  # 终端字体
  console.font = "${pkgs.terminus_font}/share/consolefonts/ter-132n.psf.gz";

  # ==================== 安全基线 ====================
  # SSH 服务（参考 Arch 脚本，openssh 已作为依赖）
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;  # 等配好 SSH key 后改为 false
    };
  };
}
