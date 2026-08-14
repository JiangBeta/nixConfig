#!/bin/sh
# Xwayland DPI（1.25x）
# X11 应用与 fcitx5 候选框按此 DPI 缩放（原生 Wayland 应用走合成器缩放不受影响）
sleep 3
DISPLAY=:0 xrdb -merge <<'EOF'
Xft.dpi: 120
EOF
