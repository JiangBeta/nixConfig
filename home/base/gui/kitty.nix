# home/base/gui/kitty.nix — Kitty 终端
#
# 跨平台：Linux 与 macOS 共用（含 macOS 标题栏 / 窗口装饰选项）。
# 参考：dotfile/config/kitty/kitty.conf（One Dark 配色 + Maple Mono 字体）
{ config, lib, pkgs, ... }:
let
  cfg = config.modules-home-base-gui-kitty;
in
{
  options.modules-home-base-gui-kitty = {
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

      font_size 14.0            # 字号大小
      adjust_line_height 2      # 行间距，单位：pt
      adjust_column_width 0     # 字符间距，单位：pt
      disable_ligatures never   # 启用连字支持（-> != >=)

      # ===== 光标 =====
      cursor_shape beam                 # 光标形状：block（方块）| beam（竖线）| underline（下划线）
      cursor_blink_interval 0.5         # 光标闪烁间隔（秒），设为 0 禁用闪烁
      cursor none                       # 光标颜色（none 表示跟随文本前景色）
      cursor_stop_blinking_after 15.0   # Shell 集成时停止闪烁

      # ===== 滚动 =====
      scrollback_lines 10000            # 回滚缓冲区行数（-1 为无限）
      scrollback_pager_history_size 64  # 用于 scrollback_pager 的内存限制（MB）
      scrollback_pager less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER  # 使用 less 作为回滚分页器

      wheel_scroll_multiplier 5.0       # 滚动速度（每次滚轮滚动的行数）
      touch_scroll_multiplier 1.0       # 触控板滚动速度

      # ===== 鼠标 =====
      open_url_with default     # 点击链接时打开浏览器
      detect_urls yes           # 检测 URL 并允许点击打开
      url_style curly           # URL 下划线样式
      url_color #61afef         # 链接颜色
      mouse_hide_wait 3.0       # 鼠标隐藏延迟（秒），0 表示不隐藏
      copy_on_select clipboard  # 复制到剪贴板时同时复制到选区（类 X11 行为）

      # ===== 窗口 =====
      enabled_layouts splits, stack, tall, fat  # 支持的布局：fat, grid, horizontal, splits, stack, tall, vertical
      window_padding_width 8                    # 窗口内边距（pt）
      window_border_width 1pt                   # 窗口边框宽度
      active_border_color #61afef               # 活动窗口边框颜色
      inactive_border_color #3e4452             # 非活动窗口边框颜色
      inactive_text_alpha 0.7                   # 非活动窗口文字透明度（1.0 为不透明）

      remember_window_size  yes                 # 记住窗口尺寸
      initial_window_width  120c                # 新窗口宽度（字符列 x 行）
      initial_window_height 36c                 # 新窗口高度（字符行 x 列）

      hide_window_decorations no                # 窗口装饰（titlebar-only 在 macOS 上仅显示标题栏按钮）
      macos_titlebar_color background           # macOS 标题栏颜色跟随主题

      # ===== 标签栏 =====
      tab_bar_edge bottom                             # 标签栏位置：top | bottom
      tab_bar_style powerline                         # 标签栏样式：fade | slant | separator | powerline | custom | hidden
      tab_powerline_style slanted                     # Powerline 样式的分隔符形状
      tab_title_template "{index}: {title}"           # 标签标题模板
      tab_bar_background #21252b                      # 标签栏背景色

      # 活动标签样式
      active_tab_foreground #282c34
      active_tab_background #61afef
      active_tab_font_style bold
      active_tab_title_template "{index}: {title} *"

      # 活动标签样式
      inactive_tab_foreground #abb2bf
      inactive_tab_background #3e4452
      tab_bar_background #21252b

      # ===== One Dark 配色 =====
      foreground #abb2bf            # 前景色
      background #282c34            # 背景色
      background_opacity 0.95       # 背景透明度（需合成器支持）
      selection_foreground #282c34  # 选区前景色
      selection_background #61afef  # 选区前景色

      # 标准 16 色
      # 黑色
      color0  #282c34
      color8  #5c6370

      # 红色
      color1  #e06c75
      color9  #e06c75

      # 绿色
      color2  #98c379
      color10 #98c379

      # 黄色
      color3  #e5c07b
      color11 #e5c07b

      # 蓝色
      color4  #61afef
      color12 #61afef

      # 品红
      color5  #c678dd
      color13 #c678dd

      # 青色
      color6  #56b6c2
      color14 #56b6c2

      # 白色
      color7  #abb2bf
      color15 #ffffff

      # ===== 声音与通知 ======
      enable_audio_bell no      # 关闭响铃声音
      visual_bell_duration 0.0  # 窗口闪烁提示
      bell_on_tab "🔔 "         # 响铃时在标签栏显示标记

      # ===== 快捷键 =====
      # 清除所有默认快捷键（可选，按需取消注释）
      # clear_all_shortcuts yes

      # -- 剪贴板 --
      map ctrl+shift+c copy_to_clipboard
      map ctrl+shift+v paste_from_clipboard

      # -- 字体缩放 --
      map ctrl+shift+equal change_font_size all +1.0
      map ctrl+shift+minus change_font_size all -1.0
      map ctrl+shift+0     change_font_size all 0

      # -- 窗口管理 --
      # 新建窗口（splits 布局下水平/垂直分屏）
      map ctrl+shift+enter new_window_with_cwd
      map ctrl+shift+\     launch --location=vsplit --cwd=current
      map ctrl+shift+-     launch --location=hsplit --cwd=current

      # 窗口切换（Vim 风格）
      map ctrl+shift+h neighboring_window left
      map ctrl+shift+l neighboring_window right
      map ctrl+shift+k neighboring_window up
      map ctrl+shift+j neighboring_window down

      # 窗口大小调整
      map ctrl+shift+r start_resizing_window

      # 切换布局
      map ctrl+shift+space next_layout

      # -- 标签页管理 --
      map ctrl+shift+t new_tab_with_cwd
      map ctrl+shift+w close_tab
      map ctrl+shift+right next_tab
      map ctrl+shift+left  previous_tab
      map ctrl+shift+.     move_tab_forward
      map ctrl+shift+,     move_tab_backward

      # 按编号切换标签页
      map ctrl+shift+1 goto_tab 1
      map ctrl+shift+2 goto_tab 2
      map ctrl+shift+3 goto_tab 3
      map ctrl+shift+4 goto_tab 4
      map ctrl+shift+5 goto_tab 5

      # -- 滚动 --
      map ctrl+shift+up    scroll_line_up
      map ctrl+shift+down  scroll_line_down
      map ctrl+shift+page_up   scroll_page_up
      map ctrl+shift+page_down scroll_page_down
      map ctrl+shift+home  scroll_home
      map ctrl+shift+end   scroll_end

      # -- 其他 --
      # 重新加载配置
      map ctrl+shift+f5 load_config_file

      # 打开 Kitty Shell（调试用）
      map ctrl+shift+escape kitty_shell window

      # 查看快捷键帮助
      map ctrl+shift+f1 show_kitty_doc overview

      # ===== 高级 =====
      # Shell 集成（提供命令行编辑增强）
      shell_integration enabled

      # 允许远程控制（通过 kitty @ 命令控制 Kitty）
      allow_remote_control socket-only
      listen_on unix:/tmp/mykitty

      # 确认关闭窗口（-1 = 有进程运行时询问）
      confirm_os_window_close -1

      # 剪贴板最大大小（MB）
      clipboard_max_size 512

      # 更新检查间隔（小时），0 禁用
      update_check_interval 0
    '';
  };
}
