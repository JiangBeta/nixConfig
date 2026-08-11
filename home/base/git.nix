# home/base/git.nix — Git 全局配置 + Delta + LazyGit + GitHub CLI
#
# 参考：
#   - 旧 home/base/git.nix（mkEnableOption 模式 + 详细别名）
{ config, lib, ... }:
let
  cfg = config.modules-home-base-git;
in
{
  options.modules-home-base-git = {
    enable = lib.mkEnableOption "Git 全局配置 + Delta + LazyGit + GitHub CLI";
  };

  config = lib.mkIf cfg.enable {
    # 删除旧版 ~/.gitconfig，让 HM 管理 ~/.config/git/config
    home.activation.removeExistingGitconfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      rm -f ${config.home.homeDirectory}/.gitconfig
    '';

    programs.gh.enable = true;

    # ⚠️ userName / userEmail 由 NixOS 层配置注入
    #    因为在 HM 子模块中 config 指向 HM config，无法访问 NixOS config.myHome.*
    #    详见 output/X86_64-linux/default.nix 中的 home-manager.users.beta 块
    programs.git = {
      enable = true;
      lfs.enable = true;

      extraConfig.init.defaultBranch = "main";
      extraConfig.push.autoSetupRemote = true;
      extraConfig.pull.rebase = true;

      aliases = {
        br = "branch"; co = "checkout"; st = "status";
        ls = "log --pretty=format:\"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]\" --decorate";
        ll = "log --pretty=format:\"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]\" --decorate --numstat";
        cm = "commit -m"; ca = "commit -am"; dc = "diff --cached";
        amend = "commit --amend -m";
        unstage = "reset HEAD --";
        merged = "branch --merged"; unmerged = "branch --no-merged";
        nonexist = "remote prune origin --dry-run";
        delmerged = ''! git branch --merged | egrep -v "(^\*|main|master|dev|staging)" | xargs git branch -d'';
        delnonexist = "remote prune origin";
        update = "submodule update --init --recursive";
        foreach = "submodule foreach";
      };
    };

    # Delta — Git diff 美化
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        diff-so-fancy = true;
        line-numbers = true;
        true-color = "always";
      };
    };

    # Lazygit — Git TUI
    programs.lazygit.enable = true;
  };
}
