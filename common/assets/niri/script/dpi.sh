#!/bin/sh
# Xwayland DPI（1.25x）：X11 应用与 fcitx5 候选框按此 DPI 缩放
# 重试直到 Xwayland 就绪
i=0
while [ $i -lt 20 ]; do
  echo "Xft.dpi: 120" | DISPLAY=:0 xrdb -merge 2>/dev/null && exit 0
  i=$((i + 1))
  sleep 1
done
