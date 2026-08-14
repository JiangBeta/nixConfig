# modules/linux/core/base.nix — Linux 基础设置（对标 Arch 脚本功能）
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

  # ==================== 固件 ====================
  hardware.enableAllFirmware = true;

  # ==================== 系统 CLI 工具（按类别分组） ====================
  environment.systemPackages = with pkgs; [
    # archives 压缩归档
    zip
    xz
    unzip
    p7zip

    # networking tools 网络工具
    curl
    aria2
    mtr          # 路由追踪
    dnsutils     # dig / nslookup
    nmap         # 端口扫描
    tcpdump      # 抓包

    # misc 杂项
    cowsay
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd
    gnupg
    jq           # JSON 处理
    gnugrep      # grep
    rsync        # 文件同步
    git
    vim
    tldr
    bash-completion
    chezmoi
    just

    # system call monitoring 系统调用监控
    lsof

    # system tools 系统工具
    sysstat
    lm_sensors
    ethtool
    pciutils
    usbutils
    openssl      # SSL/TLS 加密工具
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
