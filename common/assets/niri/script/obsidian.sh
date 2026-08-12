#!/bin/bash
# 最简单的启动脚本

env \
    QT_SCALE_FACTOR=1.25 \
    GTK_IM_MODULE=fcitx \
    QT_IM_MODULE=fcitx \
    XMODIFIERS="@im=fcitx" \
    /usr/bin/obsidian "$@"
