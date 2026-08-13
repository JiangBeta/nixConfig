#!/bin/sh
# Niri 空闲管理（swayidle）：
#   - 空闲 10 分钟 → 锁定屏幕 + 关闭显示器（再次唤醒需输入密码）
#   - 空闲 20 分钟 → 挂起（systemctl suspend）
while true; do
  swayidle -w \
    timeout 600 'noctalia msg session lock' \
    timeout 600 'niri msg action power-off-monitors' resume 'niri msg action power-on-monitors' \
    timeout 1200 'systemctl suspend'
  sleep 1
done
