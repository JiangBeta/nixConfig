#!/usr/bin/env bash
# ================================================================
# nix-installer/install.sh — NixOS 半自动安装脚本（pro13）
#
# 使用方式:
#   1. 启动 NixOS ISO live 环境
#   2. 将 nixConfig 仓库复制到 live 环境（USB 或网络）
#   3. sudo bash nix-installer/install.sh
#
# 对标 arch-live-install.sh 的功能，流程分为：
#   1. 选择目标磁盘 → 2. disko 分区格式化 → 3. 生成硬件配置
#   4. 复制 flake → 5. nixos-install → 6. 重启
# ================================================================
set -euo pipefail
IFS=$'\n\t'

# ---------- 颜色与样式 ----------
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
DISKO_CONFIG="$SCRIPT_DIR/disko-config.nix"
DISKO_CONFIG_TMP="/tmp/disko-config-pro13.nix"

# ---------- 辅助函数 ----------
print_header() {
    clear
    echo -e "${PURPLE}================================================================${NC}"
    echo -e "${BOLD}${WHITE}              NixOS 自动化安装向导 — pro13                        ${NC}"
    echo -e "${PURPLE}================================================================${NC}"
}

print_step() {
    echo -e "\n${BLUE}┌──────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC} ${BOLD}${WHITE}[步骤 $1]${NC} ${GREEN}$2${NC}"
    echo -e "${BLUE}└──────────────────────────────────────────────────────────────┘${NC}"
}

error_exit() {
    echo -e "\n${RED}✘ 错误: $1${NC}" >&2
    exit 1
}

info()    { echo -e "${CYAN}ℹ $1${NC}"; }
success() { echo -e "${GREEN}✔ $1${NC}"; }
warn()    { echo -e "${YELLOW}! 警告: $1${NC}"; }

confirm() {
    local prompt=$1
    local default=${2:-n}
    local yn
    while true; do
        read -r -p "$(echo -e "${BOLD}${prompt} [y/N]: ${NC}")" yn
        yn=${yn:-$default}
        case $yn in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo -e "${RED}请输入 y 或 n${NC}" ;;
        esac
    done
}

# ---------- 主流程 ----------
main() {
    # 权限检查
    if [ "$EUID" -ne 0 ]; then
        error_exit "此脚本必须使用 Root 权限运行！请用 sudo bash install.sh"
    fi

    print_header

    # ==================== 步骤 1: 选择磁盘 ====================
    print_step "1/6" "选择安装目标磁盘"

    echo -e "\n${CYAN}======================== 存储设备列表 ========================${NC}"
    lsblk -e 7,11 -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS,MODEL | sed 's/^/  /'
    echo -e "${CYAN}==============================================================${NC}"

    # 收集可用磁盘
    mapfile -t disks < <(lsblk -d -n -e 7,11 -o NAME,SIZE,MODEL | grep -v "^$" | awk '{
        disk=$1; size=$2; $1=""; $2=""; sub(/^ +/, "");
        printf "/dev/%s (%s - %s)\n", disk, size, $0
    }')

    if [ ${#disks[@]} -eq 0 ]; then
        error_exit "未检测到可用物理磁盘！"
    fi

    echo -e "\n${CYAN}可用磁盘列表:${NC}"
    for i in "${!disks[@]}"; do
        printf "  ${YELLOW}%2d)${NC} ${WHITE}%s${NC}\n" $((i+1)) "${disks[$i]}"
    done

    local disk_choice
    while true; do
        read -r -p "$(echo -e "${BOLD}请选择目标磁盘编号 [1-${#disks[@]}]: ${NC}")" disk_choice
        if [[ "$disk_choice" =~ ^[0-9]+$ ]] && [ "$disk_choice" -ge 1 ] && [ "$disk_choice" -le "${#disks[@]}" ]; then
            break
        fi
        echo -e "${RED}无效选择，请输入 1-${#disks[@]}${NC}"
    done

    local DISK
    DISK=$(echo "${disks[$((disk_choice-1))]}" | awk '{print $1}')
    info "已选择目标磁盘: ${WHITE}${DISK}${NC}"

    # ==================== 步骤 2: 确认并生成 disko 配置 ====================
    print_step "2/6" "确认分区方案"

    echo -e "\n${CYAN}======================== 安装预检清单 ========================${NC}"
    printf "${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "目标磁盘" "$DISK"
    printf "${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "引导模式" "UEFI (systemd-boot)"
    printf "${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "文件系统" "Btrfs + 子卷"
    printf "${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "SWAP" "16GB (休眠支持)"
    printf "${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "快照" "Snapper (启用)"
    printf "${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "内核" "linux-zen"
    printf "${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "主机名" "pro13"
    echo -e "${CYAN}==============================================================${NC}"

    warn "即将对 ${DISK} 进行清空与重新分区，所有原有数据将丢失！"
    if ! confirm "确认以上配置并立即开始安装？"; then
        error_exit "用户中止了安装流程。"
    fi

    # 替换 disko 配置中的磁盘设备
    cp "$DISKO_CONFIG" "$DISKO_CONFIG_TMP"
    sed -i "s|device = \"/dev/nvme0n1\"|device = \"$DISK\"|" "$DISKO_CONFIG_TMP"
    success "已生成 disko 配置（磁盘: $DISK）"

    # ==================== 步骤 3: 运行 disko 分区 ====================
    print_step "3/6" "磁盘分区与格式化（disko）"

    info "正在清空磁盘并创建分区..."
    nix --experimental-features "nix-command flakes" \
        run github:nix-community/disko -- \
        --mode disko "$DISKO_CONFIG_TMP"

    success "分区与格式化完成，文件系统已挂载至 /mnt"

    # ==================== 步骤 4: 生成硬件配置 ====================
    print_step "4/6" "生成硬件配置"

    info "运行 nixos-generate-config..."
    nixos-generate-config --root /mnt

    # 将生成的硬件配置复制到仓库对应位置
    local generated_hw="/mnt/etc/nixos/hardware-configuration.nix"
    local target_hw="$REPO_DIR/hosts/pro13/hardware.nix"

    if [ -f "$generated_hw" ]; then
        cp "$generated_hw" "$target_hw"
        success "硬件配置已生成并保存至 hosts/pro13/hardware.nix"
    else
        warn "未找到生成的硬件配置文件，请手动运行 nixos-generate-config --root /mnt"
    fi

    # ==================== 步骤 5: 复制 flake 到 /mnt ====================
    print_step "5/6" "准备安装环境"

    info "复制 nixConfig 仓库到 /mnt/etc/nixos..."
    cp -r "$REPO_DIR" /mnt/etc/nixos/

    # 清理临时文件
    rm -f "$DISKO_CONFIG_TMP"

    success "配置已复制到 /mnt/etc/nixos"

    # ==================== 步骤 6: 安装 NixOS ====================
    print_step "6/6" "安装 NixOS 系统"

    info "开始 nixos-install（过程中会提示设置 root 密码）..."
    echo ""
    nixos-install --flake /mnt/etc/nixos#pro13

    success "NixOS 安装完成！"

    # ==================== 完成 ====================
    echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}              🎉 NixOS 系统安装成功！                           ${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e ""
    echo -e "  主机名:     ${WHITE}pro13${NC}"
    echo -e "  用户:       ${WHITE}beta${NC}"
    echo -e "  桌面环境:   ${WHITE}待后续配置（Niri + Noctalia）${NC}"
    echo -e ""
    echo -e "  安装完成后请运行以下命令更新系统："
    echo -e "    ${YELLOW}cd /etc/nixos && nixos-rebuild switch --flake .#pro13${NC}"
    echo -e ""

    if confirm "是否立即重启系统？"; then
        reboot
    else
        info "请在完成后续自定义配置后手动运行 'reboot' 重启。"
    fi
}

main "$@"
