# Secrets 管理 — 设计文档

## 设计理念

**工具选型：agenix + age。** age 是现代加密工具（XChaCha20-Poly1305），比 GPG 更简单、无历史包袱；agenix 是 Nix 生态的事实标准，无缝集成 NixOS / nix-darwin / home-manager。

**核心原则：**

1. 加密后的 `.age` 文件可以安全提交 Git（无密钥无法解密）
2. 解密只在 activation 时发生一次，明文落入 `/run/agenix/`（tmpfs，重启即消失）
3. Nix store 中**永远不出现**明文 secret
4. 每台主机持有独立的 age 密钥对

```
┌────────────┐     age encrypt      ┌──────────────┐     git commit     ┌───────────┐
│  明文 secret │  ───────────────→   │  .age 加密文件  │  ─────────────→    │  Git 仓库  │
│  (本地唯一)  │   + host pubkey     │  (可提交 git)   │                   │  (安全)    │
└────────────┘                      └──────────────┘                    └───────────┘
                                            │
                                    nixos-rebuild
                                            │
                                    ┌───────▼────────┐
                                    │  agenix 解密     │
                                    │  → /run/agenix/ │
                                    │  (tmpfs, 重启消失) │
                                    └───────┬────────┘
                                            │
                                    ┌───────▼────────┐
                                    │  Nix 模块消费    │
                                    │  (读解密后文件)   │
                                    └────────────────┘
```

---

## 密钥体系

### 主机密钥

每台主机生成一对 age 密钥。推荐使用 SSH host key 派生（agenix 默认行为），也可独立生成。

**方式 A：使用 SSH host Ed25519 密钥（推荐）**

```bash
# 查看主机 SSH 公钥（agenix 默认读取 /etc/ssh/ssh_host_ed25519_key）
cat /etc/ssh/ssh_host_ed25519_key.pub
# 转换为 age 公钥
ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
```

**方式 B：独立 age 密钥（更灵活，支持跨主机共享 secret）**

```bash
# 生成 age 密钥对
mkdir -p ~/.config/age
age-keygen -o ~/.config/age/keys.txt
# 公钥: age1...
```

### 密钥注册

在 `.agenix.yaml`（项目根目录）中注册每个主机的 age 公钥：

```yaml
# .agenix.yaml
keys:
  pro13:    age1pro13pubkeyhere...
  macmini:  age1macminipubkeyhere...
  nuc8:     age1nuc8pubkeyhere...
```

### 密钥表

| 主机 | 角色 | 密钥类型 | 公钥 |
|------|------|----------|------|
| pro13 | NixOS 桌面 | SSH host key | `age1...` |
| macmini | macOS AI 服务器 | 独立 age key | `age1...` |
| nuc8-d | NixOS 桌面 | SSH host key | `age1...` |
| nuc8-s | NixOS 服务器 | SSH host key | `age1...` |
| xiaobaonas | ARM NAS | 独立 age key | `age1...` |

---

## 目录结构

```
secrets/                          ← 加密的 .age 文件（可安全提交 git）
├── .gitkeep
├── ai/
│   └── tokens.json.age           ← AI API tokens
├── ssh/
│   ├── id_ed25519.age            ← SSH 私钥
│   └── id_ed25519.pub            ← SSH 公钥（明文，可提交）
├── creds/
│   ├── user-password.age         ← 用户登录密码
│   └── wifi-psk.age              ← WiFi 密码
└── api/
    └── github-token.age          ← GitHub Personal Access Token

common/secrets/
├── README.md                     ← 本文档
└── default.nix                   ← NixOS module：声明所有 age.secrets

.agenix.yaml                      ← 主机 → age 公钥映射（项目根目录）
```

---

## Secret 分类

### 1. AI Tokens（`secrets/ai/`）

```json
// 明文内容（tokens.json）— 本地编辑后加密
{
  "anthropic": "sk-ant-api03-...",
  "deepseek": "sk-...",
  "openai": "sk-proj-..."
}
```

**加密命令：**
```bash
agenix -e secrets/ai/tokens.json.age
# 在编辑器中填入 JSON，保存即自动加密
```

**消费方：**
- `home/base/ai/claude_code/default.nix` → `~/.claude/settings.json`
- `home/base/ai/opencode/default.nix`（将来）

**消费方式：**
```nix
# 在 home-manager activation 中读取解密文件，注入 settings.json
# 或通过 systemd ExecStartPre 脚本处理
```

### 2. SSH Keys（`secrets/ssh/`）

**私钥加密：**
```bash
agenix -e secrets/ssh/id_ed25519.age
# 粘贴 ~/.ssh/id_ed25519 内容
```

**公钥直接提交：**
```bash
cp ~/.ssh/id_ed25519.pub secrets/ssh/
```

**消费方：**
- `modules/base/user.nix` → `users.users.<name>.openssh.authorizedKeys`
- `home/base/core/git.nix` → Git SSH signing
- SSH 客户端配置

### 3. Credentials（`secrets/creds/`）

**用户密码：**
```bash
agenix -e secrets/creds/user-password.age
# 输入 hashed password（mkpasswd -m sha-512）
```

**WiFi PSK：**
```bash
agenix -e secrets/creds/wifi-psk.age
# 输入 WiFi 密码
```

**消费方：**
- `modules/base/user.nix` → `users.users.<name>.hashedPassword`
- `hosts/<hostname>/networking.nix` → `networking.wireless`

### 4. API Keys（`secrets/api/`）

```bash
agenix -e secrets/api/github-token.age
# 输入 GitHub Personal Access Token
```

---

## 操作流程

### 初始化（新主机）

```bash
# 1. 在新主机上生成 age 密钥
age-keygen -o ~/.config/age/keys.txt
# 或使用 SSH host key（agenix 默认）

# 2. 获取公钥
age-keygen -y ~/.config/age/keys.txt
# age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# 3. 在开发机上将新主机公钥加入 .agenix.yaml
# 编辑 .agenix.yaml → 添加新主机的 age 公钥

# 4. 重新加密所有 secret（加入新主机的公钥）
agenix -r  # 重新加密所有 .age 文件

# 5. 提交更新后的 .age 文件
git add secrets/ .agenix.yaml && git commit -m "secrets: add <hostname> key"
```

### 添加新 Secret

```bash
# 1. 创建 .age 文件
agenix -e secrets/ai/tokens.json.age
# 在编辑器中输入明文 JSON → 保存退出（自动加密）

# 2. 在 common/secrets/default.nix 中声明
# age.secrets.ai-tokens = { file = ../../secrets/ai/tokens.json.age; ... };

# 3. 在消费模块中引用
# config.age.secrets.ai-tokens.path → /run/agenix/ai-tokens

# 4. 提交
git add secrets/ai/tokens.json.age common/secrets/default.nix
```

### 轮换 Secret

```bash
# 1. 编辑 .age 文件
agenix -e secrets/ai/tokens.json.age
# 修改内容 → 保存

# 2. 提交新版本
git add secrets/ai/tokens.json.age && git commit -m "secrets: rotate AI tokens"
```

### 删除主机

```bash
# 1. 从 .agenix.yaml 移除对应公钥
# 2. 重新加密所有 secret（该主机的公钥不再参与加密）
agenix -r
# 3. 提交
git add secrets/ .agenix.yaml && git commit -m "secrets: remove <hostname>"
```

---

## 模块集成

### NixOS 层（`common/secrets/default.nix`）

```nix
{ config, lib, ... }:
{
  # 声明所有 secret
  age.secrets = {
    "ai-tokens" = {
      file = ../../secrets/ai/tokens.json.age;
      owner = config.mySystem.user;
      group = "users";
      mode = "400";
    };
    "ssh-key" = {
      file = ../../secrets/ssh/id_ed25519.age;
      owner = config.mySystem.user;
      group = "users";
      mode = "600";
    };
    "user-password" = {
      file = ../../secrets/creds/user-password.age;
      owner = "root";
      group = "root";
      mode = "400";
    };
    "wifi-psk" = {
      file = ../../secrets/creds/wifi-psk.age;
      owner = "root";
      group = "root";
      mode = "400";
    };
    "github-token" = {
      file = ../../secrets/api/github-token.age;
      owner = config.mySystem.user;
      group = "users";
      mode = "400";
    };
  };
}
```

### 消费 Secret（NixOS module）

```nix
# 用户密码（从 agenix 解密读取）
users.users.${config.mySystem.user} = {
  hashedPasswordFile = config.age.secrets.user-password.path;
};

# WiFi
networking.wireless.secretsFile = config.age.secrets.wifi-psk.path;
```

### 消费 Secret（Home Manager）

HM 模块不能直接访问 `config.age.secrets`（那是 NixOS 层的）。需要：

```nix
# output/X86_64-linux 中传入 HM
home-manager.users.${config.mySystem.user} = {
  # 将 agenix 解密路径传入 HM extraSpecialArgs
  extraSpecialArgs.aiTokensPath = config.age.secrets.ai-tokens.path;
};
```

```nix
# home/base/ai/claude_code/default.nix 中消费
{ aiTokensPath ? null, ... }:
# 在 home.activation 中读取解密文件并注入 settings.json
```

---

## AI Token 消费方案

当前过渡期使用 `vars/tokens.nix`（明文，gitignored），目标迁移到 agenix。

### Phase 1（当前）：vars/tokens.nix

```
vars/tokens.nix → myHome.ai.tokens.* (NixOS option)
  → claude_code 读 osConfig.myHome.ai.tokens.*
    → 写入 ~/.claude/settings.json
```

**缺点**：token 明文经过 Nix store（世界可读）。

### Phase 2（目标）：agenix

```
secrets/ai/tokens.json.age → agenix 解密 → /run/agenix/ai-tokens
  → home.activation 脚本读取 JSON
    → 注入 ~/.claude/settings.json (不在 Nix store 中)
```

**实现要点**：

1. `common/secrets/default.nix` 声明 `age.secrets.ai-tokens`
2. `output/X86_64-linux` 将解密路径传入 HM
3. `claude_code/default.nix` 用 `home.activation` 在运行时生成 settings.json：

```nix
home.activation.injectClaudeTokens = lib.hm.dag.entryAfter [ "writeBoundary" ] (
  let
    tokensPath = if aiTokensPath != null
      then aiTokensPath
      else "/dev/null";
  in ''
    if [ -f "${tokensPath}" ]; then
      TOKEN=$(cat ${tokensPath} | ${pkgs.jq}/bin/jq -r '.deepseek')
      # 改写 settings.json 的 ANTHROPIC_AUTH_TOKEN
      ${pkgs.jq}/bin/jq --arg token "$TOKEN" \
        '.env.ANTHROPIC_AUTH_TOKEN = $token' \
        ~/.claude/settings.json > ~/.claude/settings.json.tmp \
        && mv ~/.claude/settings.json.tmp ~/.claude/settings.json
    fi
  ''
);
```

这样 settings.json 模板中不包含真实 token（用占位符），activation 时注入，不入 Nix store。

---

## SSH Key 管理

### 部署

```nix
# 在 output/X86_64-linux 中
home.activation.deploySshKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  if [ ! -f ~/.ssh/id_ed25519 ]; then
    mkdir -p ~/.ssh
    cp ${config.age.secrets.ssh-key.path} ~/.ssh/id_ed25519
    chmod 600 ~/.ssh/id_ed25519
    cp ${../../secrets/ssh/id_ed25519.pub} ~/.ssh/id_ed25519.pub
  fi
'';
```

### Git 签名

```nix
programs.git.extraConfig = {
  commit.gpgSign = true;
  gpg.format = "ssh";
  user.signingKey = "~/.ssh/id_ed25519.pub";
};
```

---

## 安全边界

### Nix Store 中的敏感数据

| 数据类型 | 是否入 store | 说明 |
|----------|-------------|------|
| `.age` 加密文件 | ✅ 是（安全） | 无密钥无法解密 |
| agenix 解密路径 `/run/agenix/` | ❌ 否 | tmpfs，重启消失 |
| `vars/tokens.nix`（过渡期） | ⚠️ 是（不安全） | 明文 key 在 /nix/store，世界可读 |
| `settings.json`（含 token） | ⚠️ 是 | 需用 activation 注入替代 |
| SSH 公钥 | ✅ 是（安全） | 公钥本就可公开 |

### 最小权限

- AI tokens：owner=`beta`, mode=`400`
- SSH 私钥：owner=`beta`, mode=`600`
- 用户密码：owner=`root`, mode=`400`
- WiFi PSK：owner=`root`, mode=`400`

---

## 变更记录

| 日期 | 变更 |
|------|------|
| 2026-08-12 | 初始设计：agenix + age，四类 secret（AI/SSH/Creds/API） |
| | 过渡期保留 `vars/tokens.nix`，标记为 deprecated |
| | 目录结构：`secrets/`(加密) + `common/secrets/`(模块+文档) |
