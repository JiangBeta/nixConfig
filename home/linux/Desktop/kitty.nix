# home/linux/Desktop/kitty.nix — Kitty 终端
#
# 参考：dotfile/config/kitty/kitty.conf（One Dark 配色 + Maple Mono 字体）
{ config, lib, pkgs, ... }:
let
  cfg = config.modules-home-linux-desktop-kitty;
in
{
  options.modules-home-linux-desktop-kitty = {
    enable = lib.mkEnableOption "Kitty 终端模拟器";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.kitty ];

    xdg.configFile."kitty/kitty.conf".text = ''
      # ===== 字体 =====
      font_family      Maple Mono NF CN
      bold_font        auto
      italic_font      auto
      bold_italic_font auto
      font_size 14.0
      adjust_line_height 2
      disable_ligatures never

      # ===== 光标 =====
      cursor_shape beam
      cursor_blink_interval 0.5
      cursor_stop_blinking_after 15.0

      # ===== 滚动 =====
      scrollback_lines 10000
      wheel_scroll_multiplier 5.0

      # ===== 鼠标 =====
      open_url_with default
      detect_urls yes
      url_style curly
      url_color #61afef
      mouse_hide_wait 3.0
      copy_on_select clipboard

      # ===== 窗口 =====
      enabled_layouts splits, stack, tall, fat
      window_padding_width 8
      window_border_width 1pt
      active_border_color #61afef
      inactive_border_color #3e4452
      inactive_text_alpha 0.7
      initial_window_width  120c
      initial_window_height 36c

      # ===== 标签栏 =====
      tab_bar_edge bottom
      tab_bar_style powerline
      tab_powerline_style slanted
      tab_title_template "{index}: {title}"
      active_tab_foreground #282c34
      active_tab_background #61afef
      active_tab_font_style bold
      inactive_tab_foreground #abb2bf
      inactive_tab_background #3e4452
      tab_bar_background #21252b

      # ===== One Dark 配色 =====
      foreground #abb2bf
      background #282c34
      background_opacity 0.95
      selection_foreground #282c34
      selection_background #61afef
      color0  #282c34
      color8  #5c6370
      color1  #e06c75
      color9  #e06c75
      color2  #98c379
      color10 #98c379
      color3  #e5c07b
      color11 #e5c07b
      color4  #61afef
      color12 #61afef
      color5  #c678dd
      color13 #c678dd
      color6  #56b6c2
      color14 #56b6c2
      color7  #abb2bf
      color15 #ffffff

      # ===== 快捷键 =====
      map ctrl+shift+c copy_to_clipboard
      map ctrl+shift+v paste_from_clipboard
      map ctrl+shift+equal change_font_size all +1.0
      map ctrl+shift+minus change_font_size all -1.0
      map ctrl+shift+0     change_font_size all 0
      map ctrl+shift+enter new_window_with_cwd
      map ctrl+shift+h neighboring_window left
      map ctrl+shift+l neighboring_window right
      map ctrl+shift+k neighboring_window up
      map ctrl+shift+j neighboring_window down
      map ctrl+shift+r start_resizing_window
      map ctrl+shift+t new_tab_with_cwd
      map ctrl+shift+w close_tab
      map ctrl+shift+right next_tab
      map ctrl+shift+left  previous_tab
      map ctrl+shift+up    scroll_line_up
      map ctrl+shift+down  scroll_line_down
      map ctrl+shift+f5 load_config_file

      # ===== 高级 =====
      shell_integration enabled
      confirm_os_window_close -1
      update_check_interval 0
    '';
  };
}
