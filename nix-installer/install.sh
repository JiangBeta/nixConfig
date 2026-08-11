#!/usr/bin/env bash
# ================================================================
# nix-installer/install.sh — NixOS 交互式安装脚本
#
# 使用方式:
#   1. 启动 NixOS ISO live 环境，连接网络
#   2. git clone 本仓库，cd 到仓库根目录
#   3. sudo bash nix-installer/install.sh
#
# 交互流程：
#   主机选择 → 磁盘选择 → 根分区大小 → 休眠/SWAP → 快照 → 内核
#   → 汇总确认 → disko 分区 → 硬件配置 → nixos-install
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
DISKO_TMP="/tmp/disko-config.nix"
HOST_DEFAULT_BAK=""

# ---------- 用户选择变量 ----------
CHOSEN_HOST=""          # 主机名
CHOSEN_DISK=""          # 目标磁盘设备（如 /dev/nvme0n1）
ROOT_SIZE=""            # 根分区大小（如 "80%" 或 "50G"）
SWAP_ENABLE=""          # yes / no
SWAP_SIZE=""            # 数字，单位 GiB
HIBERNATE=""            # yes / no
SNAPPER_ENABLE=""       # yes / no
KERNEL_CHOICE=""        # zen / lts
MEM_GB=0                # 物理内存 GiB

# ---------- 辅助函数 ----------
print_header() {
    clear
    echo -e "${PURPLE}================================================================${NC}"
    echo -e "${BOLD}${WHITE}              NixOS 交互式安装向导                               ${NC}"
    echo -e "${PURPLE}================================================================${NC}"
}

print_step() {
    echo -e "\n${BLUE}┌──────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC} ${BOLD}${WHITE}[$1]${NC} ${GREEN}$2${NC}"
    echo -e "${BLUE}└──────────────────────────────────────────────────────────────┘${NC}"
}

error_exit()  { echo -e "\n${RED}✘ 错误: $1${NC}" >&2; exit 1; }
info()        { echo -e "${CYAN}ℹ $1${NC}"; }
success()     { echo -e "${GREEN}✔ $1${NC}"; }
warn()        { echo -e "${YELLOW}! 警告: $1${NC}"; }

confirm() {
    local prompt=$1; local default=${2:-n}
    local yn prompt_suffix="[y/N]"
    [[ "$default" =~ ^[Yy]$ ]] && prompt_suffix="[Y/n]"
    while true; do
        read -r -p "$(echo -e "${BOLD}${prompt} ${YELLOW}${prompt_suffix}${NC}: ")" yn
        yn=${yn:-$default}
        case $yn in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo -e "${RED}请输入 y 或 n${NC}" ;;
        esac
    done
}

# ---------- 生成 disko 配置 ----------
generate_disko_config() {
    local disk=$1 root_size=$2 swap_enable=$3 swap_size=$4 snapper=$5

    # 生成 SWAP 分区块
    local swap_block=""
    if [ "$swap_enable" = "yes" ]; then
        swap_block="
            # --------- SWAP ----------
            swap = {
              size = \"${swap_size}G\";
              content = {
                type = \"swap\";
                randomEncryption = false;
                resumeDevice = true;
              };
            };"
    fi

    # 生成 Snapper 子卷块
    local snapper_block=""
    if [ "$snapper" = "yes" ]; then
        snapper_block='
                  # 快照子卷
                  "@snapper" = {
                    mountpoint = "/snapper";
                    mountOptions = [ "compress=zstd" "noatime" "space_cache=v2" "discard=async" ];
                  };
                  "@snapper/root_snap" = {
                    mountpoint = "/snapper/root_snap";
                    mountOptions = [ "compress=zstd" "noatime" "space_cache=v2" "discard=async" ];
                  };
                  "@snapper/home_snap" = {
                    mountpoint = "/snapper/home_snap";
                    mountOptions = [ "compress=zstd" "noatime" "space_cache=v2" "discard=async" ];
                  };
                  "@snapper/nix_snap" = {
                    mountpoint = "/snapper/nix_snap";
                    mountOptions = [ "compress=zstd" "noatime" "space_cache=v2" "discard=async" ];
                  };'
    fi

    cat > "$DISKO_TMP" <<EOF
# 由 nix-installer/install.sh 动态生成
{
  disko.devices = {
    disk = {
      main = {
        device = "${disk}";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            # --------- UEFI ESP ----------
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/efi";
                mountOptions = [ "fmask=0077" "dmask=0077" ];
              };
            };
${swap_block}
            # --------- Btrfs 根分区 ----------
            root = {
              size = "${root_size}";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  # 需要快照的子卷
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" "space_cache=v2" "discard=async" ];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" "noatime" "space_cache=v2" "discard=async" ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" "space_cache=v2" "discard=async" ];
                  };

                  # 不进行快照的子卷
                  "@var_log" = {
                    mountpoint = "/var/log";
                    mountOptions = [ "compress=zstd" "noatime" "space_cache=v2" "discard=async" ];
                  };
                  "@var_cache" = {
                    mountpoint = "/var/cache";
                    mountOptions = [ "compress=zstd" "noatime" "space_cache=v2" "discard=async" ];
                  };
                  "@var_tmp" = {
                    mountpoint = "/var/tmp";
                    mountOptions = [ "compress=zstd" "noatime" "space_cache=v2" "discard=async" ];
                  };
                  "@docker" = {
                    mountpoint = "/var/lib/docker";
                    mountOptions = [ "compress=zstd" "noatime" "space_cache=v2" "discard=async" ];
                  };
${snapper_block}
                };
              };
            };
          };
        };
      };
    };
  };
}
EOF
    success "Disko 配置已生成"
}

# ---------- 步骤 1: 选择主机 ----------
choose_host() {
    print_step "1/7" "选择目标主机"
    local hosts
    mapfile -t hosts < <(ls -d "$REPO_DIR"/hosts/*/ 2>/dev/null | xargs -n1 basename | sort)

    if [ ${#hosts[@]} -eq 0 ]; then
        error_exit "未找到 hosts/ 下的主机目录"
    fi

    echo -e "\n${CYAN}可用主机:${NC}"
    for i in "${!hosts[@]}"; do
        printf "  ${YELLOW}%2d)${NC} ${WHITE}%s${NC}\n" $((i+1)) "${hosts[$i]}"
    done

    local choice
    while true; do
        read -r -p "$(echo -e "${BOLD}请选择主机编号 [1-${#hosts[@]}]: ${NC}")" choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#hosts[@]} ]; then
            CHOSEN_HOST="${hosts[$((choice-1))]}"
            break
        fi
        echo -e "${RED}无效选择，请输入 1-${#hosts[@]}${NC}"
    done
    success "已选择主机: ${WHITE}${CHOSEN_HOST}${NC}"
}

# ---------- 步骤 2: 选择磁盘 ----------
choose_disk() {
    print_step "2/7" "选择目标磁盘"

    echo -e "\n${CYAN}======================== 存储设备列表 ========================${NC}"
    lsblk -e 7,11 -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS,MODEL | sed 's/^/  /'
    echo -e "${CYAN}==============================================================${NC}"

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

    local choice
    while true; do
        read -r -p "$(echo -e "${BOLD}请选择目标磁盘编号 [1-${#disks[@]}]: ${NC}")" choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#disks[@]} ]; then
            CHOSEN_DISK=$(echo "${disks[$((choice-1))]}" | awk '{print $1}')
            break
        fi
        echo -e "${RED}无效选择，请输入 1-${#disks[@]}${NC}"
    done
    success "已选择目标磁盘: ${WHITE}${CHOSEN_DISK}${NC}"
}

# ---------- 步骤 3: 根分区大小 ----------
choose_root_size() {
    print_step "3/7" "根分区大小"

    echo -e "\n${CYAN}输入格式：${NC}"
    echo -e "  ${WHITE}100%${NC}       — 占用磁盘全部剩余空间（默认）"
    echo -e "  ${WHITE}数字G${NC}     — 固定大小，单位 GiB（如 50G）"
    echo -e "  ${WHITE}纯数字${NC}   — 视为 GiB（如 50）"

    while true; do
        read -r -p "$(echo -e "${BOLD}请输入根分区大小 [回车默认 100%]: ${NC}")" root_input
        root_input=${root_input:-100%}
        if [ "$root_input" = "100%" ]; then
            ROOT_SIZE="$root_input"
            break
        elif [[ "$root_input" =~ ^[0-9]+G$ ]]; then
            ROOT_SIZE="$root_input"
            break
        elif [[ "$root_input" =~ ^[0-9]+$ ]]; then
            # 纯数字 → 视为 GiB
            ROOT_SIZE="${root_input}G"
            break
        else
            echo -e "${RED}格式不正确。disko 仅支持 100%（全部剩余空间）或固定 GiB 大小。${NC}"
        fi
    done
    success "根分区大小: ${WHITE}${ROOT_SIZE}${NC}"
}

# ---------- 步骤 4: 休眠与 SWAP ----------
choose_swap() {
    print_step "4/7" "休眠与 SWAP 配置"

    # 检测物理内存（优先 dmidecode 读取 DIMM 硬件规格，回退 /proc/meminfo）
    local mem_bytes=0

    if ! command -v dmidecode &>/dev/null; then
        info "正在安装 dmidecode（读取 DIMM 硬件信息）..."
        nix --extra-experimental-features "nix-command flakes" \
            profile install nixpkgs#dmidecode 2>/dev/null || true
    fi

    if command -v dmidecode &>/dev/null; then
        while read -r line; do
            if [[ "$line" =~ ^[[:space:]]+Size:[[:space:]]+([0-9]+)[[:space:]]+(MB|GB) ]]; then
                local size="${BASH_REMATCH[1]}"
                local unit="${BASH_REMATCH[2]}"
                [[ "$unit" == "GB" ]] && size=$((size * 1024))
                mem_bytes=$((mem_bytes + size))
            fi
        done < <(dmidecode -t memory 2>/dev/null | grep -E '^[[:space:]]+Size:')
    fi

    if [ "$mem_bytes" -eq 0 ]; then
        warn "dmidecode 不可用或未检测到 DIMM 信息，回退到 /proc/meminfo"
        local mem_kb
        mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        mem_bytes=$((mem_kb / 1024)) # KB → MB
    fi

    MEM_GB=$(awk "BEGIN {printf \"%.1f\", $mem_bytes/1024}")
    local mem_int
    mem_int=$(awk "BEGIN {printf \"%.0f\", $mem_bytes/1024}")
    # 向上取整
    if [ "$mem_int" -lt "$MEM_GB" ] || [ "$mem_int" -eq 0 ]; then
        mem_int=$((mem_int + 1))
    fi

    info "检测到物理内存: ${WHITE}${MEM_GB} GB${NC}"

    # --- 休眠 ---
    if confirm "是否需要休眠（Suspend-to-Disk）支持？" "y"; then
        HIBERNATE="yes"
        SWAP_ENABLE="yes"
    else
        HIBERNATE="no"
        # --- 不休眠：是否要 SWAP ---
        if confirm "是否仍需创建 SWAP 分区（防止 OOM）？" "y"; then
            SWAP_ENABLE="yes"
        else
            SWAP_ENABLE="no"
            SWAP_SIZE="0"
            success "已跳过 SWAP 分区"
            return
        fi
    fi

    # --- 输入 SWAP 大小 ---
    local recommended=$mem_int
    [ "$HIBERNATE" = "yes" ] && recommended=$((mem_int + 2))

    if [ "$HIBERNATE" = "yes" ]; then
        info "休眠开启：SWAP 大小需 >= 物理内存 (${mem_int} GB)，推荐 ${recommended} GB"
    else
        info "不休眠：SWAP 大小无硬性要求，推荐 ${recommended} GB"
    fi

    while true; do
        read -r -p "$(echo -e "${BOLD}请输入 SWAP 大小（GiB）[回车默认: ${recommended}]: ${NC}")" swap_input
        swap_input=${swap_input:-$recommended}

        if ! [[ "$swap_input" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}请输入正整数。${NC}"
            continue
        fi

        if [ "$swap_input" -eq 0 ]; then
            SWAP_ENABLE="no"
            SWAP_SIZE="0"
            success "已跳过 SWAP 分区"
            return
        fi

        # 休眠场景：SWAP 必须 >= 物理内存
        if [ "$HIBERNATE" = "yes" ] && [ "$swap_input" -lt "$mem_int" ]; then
            echo -e "${RED}休眠模式下 SWAP 大小 (${swap_input}G) 小于物理内存 (${mem_int}G)，请重新输入。${NC}"
            continue
        fi

        SWAP_SIZE="$swap_input"
        break
    done
    success "SWAP 大小: ${WHITE}${SWAP_SIZE}G${NC} (休眠: ${HIBERNATE})"
}

# ---------- 步骤 5: 快照 ----------
choose_snapper() {
    print_step "5/7" "Btrfs 快照（Snapper）"

    if confirm "是否启用 Snapper 定时快照？" "y"; then
        SNAPPER_ENABLE="yes"
    else
        SNAPPER_ENABLE="no"
    fi
    success "Snapper 快照: ${WHITE}${SNAPPER_ENABLE}${NC}"
}

# ---------- 步骤 6: 内核 ----------
choose_kernel() {
    print_step "6/7" "Linux 内核版本"

    echo -e "\n${CYAN}可选内核:${NC}"
    echo -e "  ${YELLOW}1)${NC} ${WHITE}linux-zen${NC} — 桌面交互与游戏优化（推荐）"
    echo -e "  ${YELLOW}2)${NC} ${WHITE}linux-lts${NC}  — 长期维护稳定版"

    local choice
    while true; do
        read -r -p "$(echo -e "${BOLD}请选择内核 [1-2，回车默认 1]: ${NC}")" choice
        choice=${choice:-1}
        case $choice in
            1) KERNEL_CHOICE="zen"; break ;;
            2) KERNEL_CHOICE="lts"; break ;;
            *) echo -e "${RED}请输入 1 或 2${NC}" ;;
        esac
    done
    success "内核: ${WHITE}linux-${KERNEL_CHOICE}${NC}"
}

# ---------- 步骤 7: 汇总确认 ----------
show_summary() {
    print_step "7/7" "安装预检清单"

    local swap_disp="未启用"
    [ "$SWAP_ENABLE" = "yes" ] && swap_disp="${SWAP_SIZE}G (休眠: ${HIBERNATE})"

    echo ""
    printf "${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "主机" "$CHOSEN_HOST"
    printf "${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "目标磁盘" "$CHOSEN_DISK"
    printf "${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "根分区大小" "$ROOT_SIZE"
    printf "${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "SWAP" "$swap_disp"
    printf "${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "Snapper 快照" "$SNAPPER_ENABLE"
    printf "${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "内核" "linux-${KERNEL_CHOICE}"
    printf "${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "引导模式" "UEFI (systemd-boot)"
    printf "${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "文件系统" "Btrfs"
    printf "${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "物理内存" "${MEM_GB} GB"
    echo ""

    warn "即将对磁盘 ${CHOSEN_DISK} 进行清空与重新分区，所有原有数据将丢失！"
    if ! confirm "确认以上配置并立即开始安装？" "n"; then
        error_exit "用户中止了安装流程。"
    fi
}

# ---------- 修改主机配置 ----------
apply_host_config() {
    local host_file="$REPO_DIR/hosts/${CHOSEN_HOST}/default.nix"

    # 备份原文件
    HOST_DEFAULT_BAK="${host_file}.bak"
    cp "$host_file" "$HOST_DEFAULT_BAK"

    # 替换磁盘设备
    sed -i "s|diskDevice = \"/dev/[^\"]*\"|diskDevice = \"${CHOSEN_DISK}\"|" "$host_file"

    # 替换内核
    sed -i "s|kernel = \"[^\"]*\"|kernel = \"${KERNEL_CHOICE}\"|" "$host_file"

    # 替换 SWAP 块（上下文：swap = { ... };）
    if [ "$SWAP_ENABLE" = "yes" ]; then
        sed -i "/swap = {/,/};/ s|enable = [^;]*;|enable = true;|" "$host_file"
        sed -i "/swap = {/,/};/ s|size = \"[^\"]*\";|size = \"${SWAP_SIZE}G\";|" "$host_file"
        if [ "$HIBERNATE" = "yes" ]; then
            sed -i "/swap = {/,/};/ s|enableHibernation = [^;]*;|enableHibernation = true;|" "$host_file"
        else
            sed -i "/swap = {/,/};/ s|enableHibernation = [^;]*;|enableHibernation = false;|" "$host_file"
        fi
    else
        sed -i "/swap = {/,/};/ s|enable = [^;]*;|enable = false;|" "$host_file"
        sed -i "/swap = {/,/};/ s|enableHibernation = [^;]*;|enableHibernation = false;|" "$host_file"
    fi

    # 替换 Snapper（上下文：btrfs = { ... };）
    if [ "$SNAPPER_ENABLE" = "yes" ]; then
        sed -i "/btrfs = {/,/};/ s|enableSnapper = [^;]*;|enableSnapper = true;|" "$host_file"
    else
        sed -i "/btrfs = {/,/};/ s|enableSnapper = [^;]*;|enableSnapper = false;|" "$host_file"
    fi

    success "主机配置已更新"
}

restore_host_config() {
    if [ -n "$HOST_DEFAULT_BAK" ] && [ -f "$HOST_DEFAULT_BAK" ]; then
        mv "$HOST_DEFAULT_BAK" "$REPO_DIR/hosts/${CHOSEN_HOST}/default.nix"
    fi
}

# ---------- 主流程 ----------
main() {
    if [ "$EUID" -ne 0 ]; then
        error_exit "此脚本必须使用 Root 权限运行！请用 sudo bash install.sh"
    fi

    print_header

    # ============ 信息收集 ============
    choose_host
    choose_disk
    choose_root_size
    choose_swap
    choose_snapper
    choose_kernel
    show_summary

    # ============ 修改主机配置 ============
    apply_host_config

    # ============ 生成 disko 配置 ============
    generate_disko_config "$CHOSEN_DISK" "$ROOT_SIZE" "$SWAP_ENABLE" "$SWAP_SIZE" "$SNAPPER_ENABLE"

    # ============ 执行 disko 分区 ============
    echo ""
    print_step "执行" "磁盘分区与格式化（disko）"

    info "正在清空磁盘并创建分区..."
    if ! nix --experimental-features "nix-command flakes" \
        run github:nix-community/disko -- \
        --mode disko "$DISKO_TMP"; then
        restore_host_config
        error_exit "disko 分区失败"
    fi
    success "分区与格式化完成，文件系统已挂载至 /mnt"

    # ============ 生成硬件配置 ============
    print_step "执行" "生成硬件配置"

    info "运行 nixos-generate-config..."
    nixos-generate-config --root /mnt

    local generated_hw="/mnt/etc/nixos/hardware-configuration.nix"
    local target_hw="$REPO_DIR/hosts/${CHOSEN_HOST}/hardware.nix"

    if [ -f "$generated_hw" ]; then
        # 剔除 fileSystems / swapDevices（disko 管理这两项，避免冲突）
        # sed 范围删除：fileSystems 每项以 "  fileSystems." 开头、"    };" 结尾
        # swapDevices 为单行，直接删
        sed -e '/^  fileSystems\./,/^    };/d' \
            -e '/^  swapDevices/d' \
            "$generated_hw" > "$target_hw"
        success "硬件配置已保存（已剔除 fileSystems/swapDevices，由 disko 管理）"
    else
        warn "未找到生成的硬件配置，请手动运行 nixos-generate-config --root /mnt"
    fi

    # ============ 复制 flake ============
    print_step "执行" "准备安装环境"

    info "复制 nixConfig 仓库到 /mnt/etc/nixos..."
    cp -r "$REPO_DIR" /mnt/etc/nixos/
    rm -f "$DISKO_TMP"
    success "配置已复制"

    # ============ nixos-install ============
    print_step "执行" "安装 NixOS 系统"

    info "开始 nixos-install（过程中会提示设置 root 密码）..."
    echo ""

    if ! nixos-install --flake /mnt/etc/nixos#${CHOSEN_HOST}; then
        restore_host_config
        error_exit "nixos-install 失败"
    fi

    success "NixOS 安装完成！"

    # ============ 恢复仓库文件 ============
    restore_host_config

    # ============ 完成 ============
    local swap_final_disp="未启用"
    [ "$SWAP_ENABLE" = "yes" ] && swap_final_disp="${SWAP_SIZE}G"

    echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}           NixOS 系统安装成功！${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e ""
    printf "  ${CYAN}%-12s${NC} : ${WHITE}%s${NC}\n" "主机名" "$CHOSEN_HOST"
    printf "  ${CYAN}%-12s${NC} : ${WHITE}%s${NC}\n" "磁盘" "$CHOSEN_DISK"
    printf "  ${CYAN}%-12s${NC} : ${WHITE}%s${NC}\n" "根分区" "$ROOT_SIZE"
    printf "  ${CYAN}%-12s${NC} : ${WHITE}%s${NC}\n" "SWAP" "$swap_final_disp"
    printf "  ${CYAN}%-12s${NC} : ${WHITE}%s${NC}\n" "快照" "$SNAPPER_ENABLE"
    printf "  ${CYAN}%-12s${NC} : ${WHITE}%s${NC}\n" "内核" "linux-${KERNEL_CHOICE}"
    echo -e ""
    echo -e "  安装后更新系统："
    echo -e "    ${YELLOW}cd /etc/nixos && nixos-rebuild switch --flake .#${CHOSEN_HOST}${NC}"
    echo -e ""

    if confirm "是否立即重启系统？" "y"; then
        reboot
    else
        info "请在完成后续配置后手动运行 'reboot' 重启。"
    fi
}

main "$@"
