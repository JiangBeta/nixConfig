# common/options/user.nix — 用户与账户相关 Option 声明
{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options = {
    mySystem.user = mkOption {
      type = types.str;
      default = "beta";
      description = "全局主系统的用户名";
    };

    myHome = {
      # 用户身份（Git commit 签名等需要）
      userFullName = mkOption {
        type = types.str;
        default = "Beta";
        description = "用户全名（Git 签名）";
      };
      userEmail = mkOption {
        type = types.str;
        default = "";
        description = "用户邮箱（Git 签名）";
      };

      # XDG 目录
      dirs = {
        enableXDG = mkOption {
          type = types.bool;
          default = true;
          description = "是否自动创建并规范化 XDG 目录";
        };
        projectsDir = mkOption {
          type = types.str;
          default = "Projects";
          description = "自定义项目开发目录名称";
        };
      };
    };
  };
}
