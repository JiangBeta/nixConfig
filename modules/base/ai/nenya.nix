# modules/base/ai/nenya.nix — Nenya AI API 网关（系统服务）
#
# Nenya：轻量级 AI API Gateway/Proxy（Go 编写，零外部依赖），作为本地 AI 编码客户端
# （Claude Code / OpenCode / Cursor 等）与上游 LLM 提供商（Gemini / DeepSeek / Zhipu 等）
# 之间的透明中间件：统一鉴权、限流、熔断、内容过滤、上下文压缩。
#
# 预编译静态二进制（GitHub release，amd64，pro13 / nuc8-d 适用），忠实复刻上游 systemd 单元的安全加固。
#
# 配置 / secrets：
#   /etc/nenya/config.json   — 网关配置（server / agents / providers / governance ...）
#   /etc/nenya/secrets.json  — client_token + provider_keys（经 LoadCredential 注入）
#
# ⚠️  secrets 当前经 environment.etc 落盘（过渡期）；目标迁移到 agenix（见 common/secrets/README.md）。
{ config, lib, pkgs, ... }:

let
  cfg = config.modules-base-ai-nenya;

  # 预编译静态二进制（amd64；arm64 可改用 nenya_0.9.1_linux_arm64.tar.gz）
  nenya-bin = pkgs.stdenv.mkDerivation {
    pname = "nenya";
    version = "0.9.1";
    src = pkgs.fetchurl {
      url = "https://github.com/gumieri/nenya/releases/download/v0.9.1/nenya_0.9.1_linux_amd64.tar.gz";
      hash = "sha256-bKk9XGGgsjja6q/uFvXjXLcCqXTUiWOcMX8B5xEFoxw=";
    };
    sourceRoot = ".";
    installPhase = ''
      runHook preInstall
      install -Dm755 nenya "$out/bin/nenya"
      runHook postInstall
    '';
  };

  # 网关配置：settings 与 server.listen_addr（由 port 决定）合并
  configJson = cfg.settings // {
    server = (cfg.settings.server or { }) // {
      listen_addr = ":${toString cfg.port}";
    };
  };

  # secrets：客户端 token + 上游 provider key
  secretsJson = {
    client_token = cfg.clientToken;
    provider_keys = cfg.providerKeys;
  };

in
{
  options.modules-base-ai-nenya = {
    enable = lib.mkEnableOption "Nenya AI API 网关（系统服务）";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "监听端口（写入 server.listen_addr）";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Nenya 配置（渲染为 /etc/nenya/config.json；server.listen_addr 由 port 覆盖）";
    };

    clientToken = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "客户端访问 token（Authorization: Bearer <token>）。⚠️ 必须非空，否则服务无法启动。生成：nk-$(openssl rand -hex 32)";
    };

    providerKeys = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "上游 provider API key（如 { deepseek = \"...\"; anthropic = \"...\"; }），写入 secrets.provider_keys";
    };
  };

  config = lib.mkIf cfg.enable {
    # 二进制进 PATH（便于手动调试）
    environment.systemPackages = [ nenya-bin ];

    # 网关配置（非密，默认 0444，DynamicUser 可读）
    environment.etc."nenya/config.json" = {
      text = builtins.toJSON configJson;
    };

    # secrets（0600，经 LoadCredential 由 systemd 以 root 读取后注入）
    environment.etc."nenya/secrets.json" = {
      text = builtins.toJSON secretsJson;
      mode = "0600";
    };

    # systemd 服务（安全加固，忠实复刻上游 deploy/nenya.service）
    systemd.services.nenya = {
      description = "Nenya AI Gateway & Bouncer";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${nenya-bin}/bin/nenya";
        ExecReload = "${pkgs.util-linux}/bin/kill -HUP $MAINPID";
        Restart = "on-failure";
        RestartSec = "5s";

        # ---- 权限与能力限制 ----
        DynamicUser = true;
        NoNewPrivileges = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RestrictNamespaces = true;

        # ---- 文件系统与进程隔离 ----
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        ProtectProc = "invisible";
        RemoveIPC = true;
        UMask = "0077";

        # ---- 网络限制 ----
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];

        # ---- 内存保护 ----
        MemoryDenyWriteExecute = true;
        LimitMEMLOCK = "infinity";  # mlock 锁定 token 内存
        LimitCORE = 0;              # 禁止 core dump（防 token 落盘）

        # ---- seccomp 系统调用过滤 ----
        SystemCallFilter = [
          "@system-service"
          "~@mount" "~@privileged" "~@raw-io" "~@reboot" "~@swap"
        ];

        # ---- secrets 经 systemd credential 注入（root 读取 → $CREDENTIALS_DIRECTORY/secrets） ----
        LoadCredential = [ "secrets:/etc/nenya/secrets.json" ];
      };
    };
  };
}
