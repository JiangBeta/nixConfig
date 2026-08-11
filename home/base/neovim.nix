# home/base/neovim.nix — Neovim + LazyVim
{ config, lib, pkgs, ... }:
let
  cfg = config.modules-home-base-neovim;
in
{
  options.modules-home-base-neovim = {
    enable = lib.mkEnableOption "Neovim 编辑器（LazyVim）";
  };

  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      vimAlias = true;
      viAlias = true;
      withNodeJs = true;  # LazyVim 需要 Node.js
    };

    # LazyVim 最小 bootstrap（首次启动 nvim 时自动安装插件）
    xdg.configFile."nvim/init.lua".text = ''
      -- LazyVim bootstrap
      local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
      if not (vim.uv or vim.loop).fs_stat(lazypath) then
        local lazyrepo = "https://github.com/folke/lazy.nvim.git"
        local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
        if vim.v.shell_error ~= 0 then
          vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
          }, true, {})
          vim.fn.getchar()
          os.exit(1)
        end
      end
      vim.opt.rtp:prepend(lazypath)

      require("lazy").setup({
        spec = {
          { "LazyVim/LazyVim", import = "lazyvim.plugins" },
        },
        defaults = {
          lazy = true,
          version = false,
        },
        install = { colorscheme = { "tokyonight", "habamax" } },
        checker = { enabled = true, notify = false },
        performance = {
          rtp = {
            disabled_plugins = {
              "gzip",
              "matchit",
              "matchparen",
              "netrwPlugin",
              "tarPlugin",
              "tohtml",
              "tutor",
              "zipPlugin",
            },
          },
        },
      })
    '';
  };
}
