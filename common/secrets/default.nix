# common/secrets/default.nix — agenix Secret 声明模块
#
# 统一声明所有 age.secrets，定义解密路径、权限、owner。
# 消费方（NixOS / HM 模块）通过 config.age.secrets.<name>.path 读取。
#
# 使用方法：
#   1. output/X86_64-linux 中导入此模块 + agenix.nixosModules.age
#   2. 各模块通过 config.age.secrets.<name>.path 读取解密后文件
#   3. HM 中通过 extraSpecialArgs 传入路径
{ config, lib, ... }:

let
  user = config.mySystem.user or "beta";
in
{
  # ============================================
  # AI Tokens
  # ============================================
  age.secrets."ai-tokens" = lib.mkIf (builtins.pathExists ../../secrets/ai/tokens.json.age) {
    file = ../../secrets/ai/tokens.json.age;
    owner = user;
    group = "users";
    mode = "400";
  };

  # ============================================
  # SSH 私钥
  # ============================================
  age.secrets."ssh-key" = lib.mkIf (builtins.pathExists ../../secrets/ssh/id_ed25519.age) {
    file = ../../secrets/ssh/id_ed25519.age;
    owner = user;
    group = "users";
    mode = "600";
  };

  # ============================================
  # 用户登录密码（hashed）
  # ============================================
  age.secrets."user-password" = lib.mkIf (builtins.pathExists ../../secrets/creds/user-password.age) {
    file = ../../secrets/creds/user-password.age;
    owner = "root";
    group = "root";
    mode = "400";
  };

  # ============================================
  # WiFi PSK
  # ============================================
  age.secrets."wifi-psk" = lib.mkIf (builtins.pathExists ../../secrets/creds/wifi-psk.age) {
    file = ../../secrets/creds/wifi-psk.age;
    owner = "root";
    group = "root";
    mode = "400";
  };

  # ============================================
  # GitHub Personal Access Token
  # ============================================
  age.secrets."github-token" = lib.mkIf (builtins.pathExists ../../secrets/api/github-token.age) {
    file = ../../secrets/api/github-token.age;
    owner = user;
    group = "users";
    mode = "400";
  };
}
