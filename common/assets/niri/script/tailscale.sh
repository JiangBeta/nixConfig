#!/bin/bash
# Tailscale 启动脚本

# 启动，接受子网路由
tailscale up --accept-routes

# 静态路由
ip route add 192.168.123.0/24 via 100.114.110.16 dev tailscale0 onlink
ip route add 192.168.120.0/24 via 100.114.110.16 dev tailscale0 onlink
ip route add 10.0.10.0/24 via 100.114.110.16 dev tailscale0 onlink
ip route add 10.0.20.0/24 via 100.114.110.16 dev tailscale0 onlink
ip route add 10.0.30.0/24 via 100.114.110.16 dev tailscale0 onlink
