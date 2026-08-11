# common/options/user.nix
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

    myHome.dirs = {
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
}
