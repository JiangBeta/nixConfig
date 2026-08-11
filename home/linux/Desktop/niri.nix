# home/linux/Desktop/niri.nix — Niri 窗口管理器（用户级 config.kdl）
#
# 参考：dotfile/config/niri/*.kdl
{ config, lib, pkgs, ... }:
let
  cfg = config.modules-home-linux-desktop-niri;
in
{
  options.modules-home-linux-desktop-niri = {
    enable = lib.mkEnableOption "Niri 窗口管理器（用户配置）";
  };

  config = lib.mkIf cfg.enable {
    # Wayland 会话文件（Ly 需要）
    home.file.".wayland-session".text = ''
      #!/bin/sh
      exec /run/current-system/sw/bin/niri-session
    '';

    xdg.configFile."niri/config.kdl".text = ''
      include "output.kdl"
      include "miscellaneous.kdl"
      include "input.kdl"
      include "layout.kdl"
      include "windows-rule.kdl"
      include "binds.kdl"
    '';

    xdg.configFile."niri/output.kdl".text = ''
      output "eDP-1" {
          mode 2560x1600@60Hz
      }
    '';

    xdg.configFile."niri/input.kdl".text = ''
      input {
          keyboard {
              xkb_layout "us"
          }
          touchpad {
              tap
              natural-scroll
          }
          mouse {
              natural-scroll
          }
      }
    '';

    xdg.configFile."niri/layout.kdl".text = ''
      default-column-width { proportion 0.5; }
      preset-column-widths {
          proportion 0.33333;
          proportion 0.5;
          proportion 0.66667;
      }
    '';

    xdg.configFile."niri/miscellaneous.kdl".text = ''
      hotkey-overlay {
          skip-at-startup
      }
      spawn-at-startup "fcitx5"
      prefer-no-csd

      environment {
          DISPLAY ":0"
          WAYLAND_DISPLAY "wayland-1"
          XCURSOR_SIZE "24"
      }
    '';

    xdg.configFile."niri/windows-rule.kdl".text = ''
      window-rule {
          match app-id="fcitx5"
          open-floating true
      }
    '';

    xdg.configFile."niri/binds.kdl".text = ''
      binds {
          Ctrl+Alt+Delete { quit; }
          Mod+Slash { show-hotkey-overlay; }
          Mod+Q { close-window; }
          Alt+F4 { close-window; }
          Mod+Return { spawn "kitty"; }
          Mod+Space { spawn-sh "noctalia msg panel-toggle launcher"; }
          Mod+B { spawn "zen-browser"; }
          Mod+F { fullscreen-window; }
          Mod+A { toggle-window-floating; }

          Super+L { spawn "noctalia msg session lock-and-suspend"; }

          Mod+Left  { focus-column-left; }
          Mod+Down  { focus-window-down; }
          Mod+Up    { focus-window-up; }
          Mod+Right { focus-column-right; }

          Mod+Minus { set-column-width "-10%"; }
          Mod+Equal { set-column-width "+10%"; }
          Mod+Shift+Minus { set-window-height "-10%"; }
          Mod+Shift+Equal { set-window-height "+10%"; }

          Mod+Shift+Left  { move-column-left; }
          Mod+Shift+Right { move-column-right; }

          Mod+1 { focus-workspace 1; }
          Mod+2 { focus-workspace 2; }
          Mod+3 { focus-workspace 3; }
          Mod+4 { focus-workspace 4; }
          Mod+5 { focus-workspace 5; }
          Mod+6 { focus-workspace 6; }
          Mod+Ctrl+1 { move-column-to-workspace 1; }
          Mod+Ctrl+2 { move-column-to-workspace 2; }
          Mod+Ctrl+3 { move-column-to-workspace 3; }
          Mod+Ctrl+4 { move-column-to-workspace 4; }
          Mod+Ctrl+5 { move-column-to-workspace 5; }
          Mod+Ctrl+6 { move-column-to-workspace 6; }

          XF86MonBrightnessUp   { spawn-sh "noctalia msg brightness-up"; }
          XF86MonBrightnessDown { spawn-sh "noctalia msg brightness-down"; }
          XF86AudioRaiseVolume  { spawn-sh "noctalia msg volume-up"; }
          XF86AudioLowerVolume  { spawn-sh "noctalia msg volume-down"; }
          XF86AudioMute         { spawn-sh "noctalia msg volume-mute"; }
      }

      switch-events {
          lid-close { spawn "noctalia" "msg" "session" "lock-and-suspend"; }
      }
    '';
  };
}
