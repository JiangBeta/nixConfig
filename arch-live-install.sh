#!/usr/bin/env bash
# ================================================================
# Arch Linux 全自动/半交互安装脚本
# 布局策略: ESP 挂载到 /efi，/boot 为根分区目录 (Btrfs 子卷)
# 特性支持:
#   1. UEFI 强制使用 systemd-boot（已去除 rEFInd）
#   2. 不休眠场景提供显式 SWAP 交互确认
#   3. 安装前展示完整“配置清单”并二次确认
#   4. systemd-boot 控制台模式自适应 (console-mode auto)
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

ICON_CHECK="${GREEN}✔${NC}"
ICON_CROSS="${RED}✘${NC}"
ICON_WARN="${YELLOW}!${NC}"
ICON_INFO="${CYAN}ℹ${NC}"

# ---------- 全局变量 ----------
DISK=""
BOOT_PART=""
SWAP_PART=""
ROOT_PART=""
UEFI_MODE=false
BOOTLOADER="systemd-boot"   # 固定为 systemd-boot (UEFI) 或 grub (BIOS)
MEM_GB=0
NEED_HIBERNATE="no"
SWAP_SIZE=0
HOSTNAME=""
ROOT_PASSWORD=""
USER_NAME=""
USER_PASSWORD=""
KERNEL_PKG="linux-zen"
HEADERS_PKG="linux-zen-headers"
UCODE_PKG=""
AUDIO_SERVER="pipewire"
BLUETOOTH_ENABLED=false
FIREWALL_TOOL="ufw"
PRINT_ENABLED=false
ROOT_SIZE_PERCENT=100
ROOT_SIZE_GB=""
INSTALL_FIRMWARE=true
INSTALL_NVIDIA=false

# ---------- 辅助 UI 函数 ----------
print_header() {
    clear
    echo -e "${PURPLE}================================================================${NC}"
    echo -e "${BOLD}${WHITE}                Arch Linux 自动化安装向导                         ${NC}"
    echo -e "${PURPLE}================================================================${NC}\n"
}

print_step() {
    echo -e "\n${BLUE}┌──────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC} ${BOLD}${WHITE}[步骤 $1]${NC} ${GREEN}$2${NC}"
    echo -e "${BLUE}└──────────────────────────────────────────────────────────────┘${NC}"
}

error_exit() {
    echo -e "\n${RED}[${ICON_CROSS}] 错误: $1${NC}" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}[${ICON_WARN}] 警告: $1${NC}" >&2
}

info() {
    echo -e "${CYAN}[${ICON_INFO}] $1${NC}"
}

success() {
    echo -e "${GREEN}[${ICON_CHECK}] $1${NC}"
}

spin() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf " ${CYAN}[%c]${NC}  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

run_with_spinner() {
    local msg=$1
    shift
    echo -ne "  ${WHITE}${msg}...${NC}"
    ("$@") &
    local pid=$!
    spin $pid
    wait $pid
    local ret=$?
    if [ $ret -eq 0 ]; then
        echo -e " ${GREEN}完成${NC}"
    else
        echo -e " ${RED}失败${NC}"
        error_exit "命令执行出错: $*"
    fi
}

choose_from_menu() {
    local prompt=$1
    shift
    local -a options=("$@")
    local num=${#options[@]}
    if [ $num -eq 0 ]; then
        error_exit "菜单选项为空"
    fi
    echo -e "${CYAN}${prompt}${NC}" >&2
    for i in "${!options[@]}"; do
        printf "  ${BOLD}${YELLOW}%2d)${NC} %s\n" $((i+1)) "${options[$i]}" >&2
    done
    local choice
    while true; do
        read -r -p "$(echo -e "${BOLD}${WHITE}请输入编号 [1-${num}]: ${NC}")" choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$num" ]; then
            echo "$choice"
            return
        else
            echo -e "${RED}输入无效，请在 1 到 ${num} 之间选择。${NC}" >&2
        fi
    done
}

confirm() {
    local prompt=$1
    local default=${2:-n}
    local prompt_suffix="[y/N]"
    [[ "$default" =~ ^[Yy]$ ]] && prompt_suffix="[Y/n]"

    local yn
    while true; do
        read -r -p "$(echo -e "${BOLD}${WHITE}${prompt} ${YELLOW}${prompt_suffix}${NC}: ")" yn
        yn=${yn:-$default}
        case $yn in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo -e "${RED}请输入 y 或 n${NC}" >&2 ;;
        esac
    done
}

read_password() {
    local prompt=$1
    local pw1 pw2
    while true; do
        read -r -s -p "$(echo -e "${BOLD}${WHITE}${prompt}${NC}")" pw1
        echo >&2
        read -r -s -p "$(echo -e "${BOLD}${WHITE}请再次输入以确认: ${NC}")" pw2
        echo >&2
        if [ -n "$pw1" ] && [ "$pw1" = "$pw2" ]; then
            printf "%s" "$pw1"
            return
        else
            echo -e "${RED}两次输入的密码不一致，或密码为空，请重新输入。${NC}" >&2
        fi
    done
}

get_part_name() {
    local disk=$1
    local part_num=$2
    if [[ "$disk" =~ [0-9]$ ]]; then
        echo "${disk}p${part_num}"
    else
        echo "${disk}${part_num}"
    fi
}

# ---------- 信息收集 ----------
gather_info() {
    print_header
    echo -e "${BOLD}${WHITE}>>> 阶段 1: 硬件检测与安装偏好收集${NC}\n"

    if [ -d /sys/firmware/efi ]; then
        UEFI_MODE=true
        BOOTLOADER="systemd-boot"
        success "检测到系统引导模式: UEFI (将使用 systemd-boot)"
    else
        UEFI_MODE=false
        BOOTLOADER="grub"
        info "检测到系统引导模式: Legacy BIOS (自动固定为 GRUB 引导)"
    fi

    # 1. 磁盘选择与详细分区信息展示
    echo -e "\n${CYAN}======================== 存储设备与分区明细 ====================${NC}"
    lsblk -e 7,11 -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS,MODEL | sed 's/^/  /'
    echo -e "${CYAN}================================================================${NC}\n"

    local disks
    mapfile -t disks < <(lsblk -d -n -e 7,11 -o NAME,SIZE,MODEL,TYPE | grep disk | awk '{
        disk=$1; size=$2; $1=""; $2=""; sub(/^ +/, "");
        print "/dev/" disk " (" size " - " $0 ")"
    }')

    if [ ${#disks[@]} -eq 0 ]; then
        error_exit "未检测到可用物理磁盘！"
    fi

    local disk_choice
    disk_choice=$(choose_from_menu "请选择安装目标磁盘 (警告: 该磁盘及其所有分区将被完全抹除!):" "${disks[@]}")
    DISK=$(echo "${disks[$((disk_choice-1))]}" | awk '{print $1}')

    # 3. 内存与 SWAP 逻辑
    echo ""
    local mem_bytes=0
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
        local mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        mem_bytes=$((mem_kb / 1024))
    fi
    local mem_gb_float=$(awk "BEGIN {printf \"%.1f\", $mem_bytes/1024}")
    MEM_GB=$mem_gb_float
    local mem_int=$(printf "%.0f" "$mem_gb_float")
    info "检测到物理内存: ${MEM_GB} GB"

    local hibernate_choice
    hibernate_choice=$(choose_from_menu "是否需要休眠 (Hibernate / Suspend-to-Disk) 支持？" "需要休眠" "不需要休眠")

    local want_swap=true
    local recommended=0

    if [ "$hibernate_choice" -eq 1 ]; then
        NEED_HIBERNATE="yes"
        recommended=$(( mem_int + 2 ))
        info "已启用休眠，建议 SWAP ≥ 物理内存 (${recommended} GB)"
    else
        NEED_HIBERNATE="no"
        echo ""
        info "无需休眠功能。即便无需休眠，SWAP 仍可在物理内存耗尽时防止 OOM Crash。"
        if ! confirm "在不休眠的情况下，是否仍需创建 SWAP 分区？" "y"; then
            want_swap=false
            SWAP_SIZE=0
            success "已跳过 SWAP 分区配置"
        else
            recommended=$(( mem_int / 2 ))
            [ $recommended -lt 1 ] && recommended=1
            info "推荐常规 SWAP 大小: ${recommended} GB"
        fi
    fi

    if [ "$want_swap" = true ]; then
        while true; do
            read -r -p "$(echo -e "${BOLD}${WHITE}请输入 SWAP 分区大小 (GB) [回车默认: ${recommended}]: ${NC}")" swap_input
            swap_input=${swap_input:-$recommended}
            if [[ "$swap_input" =~ ^[0-9]+$ ]] && [ "$swap_input" -ge 0 ]; then
                SWAP_SIZE=$swap_input
                break
            else
                echo -e "${RED}输入无效，请输入正整数或 0。${NC}"
            fi
        done
    fi

    # 4. 根分区大小
    echo ""
    while true; do
        read -r -p "$(echo -e "${BOLD}${WHITE}请输入根分区大小（如 50G 或 80%，回车默认占用剩余全部空间 100%）: ${NC}")" root_input
        root_input=${root_input:-100%}
        if [[ "$root_input" =~ ^[0-9]+%$ ]]; then
            ROOT_SIZE_PERCENT=${root_input%\%}
            ROOT_SIZE_GB=""
            break
        elif [[ "$root_input" =~ ^[0-9]+G$ ]]; then
            ROOT_SIZE_GB=${root_input%G}
            ROOT_SIZE_PERCENT=""
            break
        else
            echo -e "${RED}格式不正确，请输入如 '50G' 或 '80%'。${NC}"
        fi
    done

    # 5. 内核选择
    echo ""
    local kernel_choice
    kernel_choice=$(choose_from_menu "请选择 Linux 内核版本：" \
        "linux-zen (针对桌面交互与游戏调优，推荐)" \
        "linux-lts (长期维护稳定版)")
    if [ "$kernel_choice" -eq 1 ]; then
        KERNEL_PKG="linux-zen"
        HEADERS_PKG="linux-zen-headers"
    else
        KERNEL_PKG="linux-lts"
        HEADERS_PKG="linux-lts-headers"
    fi

    # CPU 微码识别
    local cpu_vendor
    cpu_vendor=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}' || true)
    if echo "$cpu_vendor" | grep -qi "GenuineIntel"; then
        UCODE_PKG="intel-ucode"
    else
        UCODE_PKG="amd-ucode"
    fi
    success "自动识别 CPU 平台: $cpu_vendor (分配微码包: $UCODE_PKG)"

    # 6. 音频与周边服务
    echo ""
    local audio_choice
    audio_choice=$(choose_from_menu "选择音频服务后端：" "pipewire (现代音频框架，推荐)" "pulseaudio" "不安装")
    case $audio_choice in
        1) AUDIO_SERVER="pipewire" ;;
        2) AUDIO_SERVER="pulseaudio" ;;
        3) AUDIO_SERVER="" ;;
    esac

    confirm "是否配置并启用蓝牙 (BlueZ) 支持？" "n" && BLUETOOTH_ENABLED=true || BLUETOOTH_ENABLED=false

    echo ""
    local fw_choice
    fw_choice=$(choose_from_menu "选择默认防火墙管理工具：" "ufw (简单易用)" "firewalld" "不安装")
    case $fw_choice in
        4) FIREWALL_TOOL="ufw" ;;
        5) FIREWALL_TOOL="firewalld" ;;
        6) FIREWALL_TOOL="" ;;
    esac

    confirm "是否配置并启用打印机服务 (CUPS)？" "n" && PRINT_ENABLED=true || PRINT_ENABLED=false

    # 7. 主机名与账号
    echo ""
    while true; do
        read -r -p "$(echo -e "${BOLD}${WHITE}请输入主机名 (Hostname): ${NC}")" HOSTNAME
        if [[ "$HOSTNAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*$ ]]; then
            break
        else
            echo -e "${RED}无效主机名，只能包含字母、数字及连字符(-)。${NC}"
        fi
    done

    while true; do
        read -r -p "$(echo -e "${BOLD}${WHITE}请输入新建普通用户名: ${NC}")" USER_NAME
        if [[ "$USER_NAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
            break
        else
            echo -e "${RED}用户名不合规范 (需以小写字母/下划线开头)。${NC}"
        fi
    done
    USER_PASSWORD=$(read_password "请设置用户 [${USER_NAME}] 的密码: ")

    if confirm "是否将 Root 管理员密码设置为与 [${USER_NAME}] 相同？" "y"; then
        ROOT_PASSWORD="$USER_PASSWORD"
    else
        ROOT_PASSWORD=$(read_password "请设置 Root 管理员密码: ")
    fi

    # 8. 硬件驱动与固件
    confirm "是否安装 linux-firmware 扩展固件包 (推荐)？" "y" && INSTALL_FIRMWARE=true || INSTALL_FIRMWARE=false

    if lspci | grep -i "VGA.*NVIDIA" &>/dev/null; then
        echo ""
        info "检测到设备含有 NVIDIA 独立显卡"
        confirm "是否安装 NVIDIA 专有驱动包？" "y" && INSTALL_NVIDIA=true || INSTALL_NVIDIA=false
    fi

    # ---------- 显示预览清单 ----------
    show_summary
}

show_summary() {
    clear
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${WHITE}                  Arch Linux 安装预检清单 (Pre-Flight)             ${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════${NC}"

    local root_size_disp="${ROOT_SIZE_PERCENT}% (剩余空间)"
    [ -n "$ROOT_SIZE_GB" ] && root_size_disp="${ROOT_SIZE_GB} GB"

    local swap_disp="${SWAP_SIZE} GB"
    [ "$SWAP_SIZE" -eq 0 ] && swap_disp="未启用 (0 GB)"

    printf "${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "安装目标磁盘" "$DISK"
    printf "${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "引导模式/加载器" "$([ "$UEFI_MODE" = true ] && echo "UEFI (systemd-boot)" || echo "Legacy BIOS (GRUB)")"
    printf "${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "SWAP 空间" "$swap_disp (休眠支持: $NEED_HIBERNATE)"
    printf "${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "根分区容量" "$root_size_disp"
    printf "${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "预装 Linux 内核" "$KERNEL_PKG + $UCODE_PKG"
    printf "${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "音频/网络组件" "${AUDIO_SERVER:-None} / ${FIREWALL_TOOL:-No-FW}"
    printf "${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "主机名与账号" "Hostname: $HOSTNAME | User: $USER_NAME"
    printf "${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "硬件驱动" "Firmware: $INSTALL_FIRMWARE | NVIDIA: $INSTALL_NVIDIA"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════${NC}\n"

    warning "注意：即将对磁盘 ${DISK} 进行清空与重新分区，所有原有数据将丢失！"
    if ! confirm "确认以上配置并立即开始安装？" "n"; then
        error_exit "用户中止了安装流程。"
    fi
}

# ---------- 磁盘清理 ----------
clean_disk() {
    local disk=$1
    info "正在释放和卸载磁盘 ${disk} 上的已有占用..."
    for part in $(lsblk -nr -o NAME,MOUNTPOINT | grep "^$(basename "$disk")" | awk '{print $1}'); do
        umount -l "/dev/$part" 2>/dev/null || true
    done
    swapoff -a 2>/dev/null || true
    umount -l /mnt 2>/dev/null || true

    command -v dmsetup &>/dev/null && dmsetup remove_all 2>/dev/null || true
    command -v mdadm &>/dev/null && mdadm --stop --scan 2>/dev/null || true
    command -v fuser &>/dev/null && fuser -km "$disk" 2>/dev/null || true
    sleep 1

    if ! wipefs -a "$disk" 2>/dev/null; then
        error_exit "无法抹除磁盘签名，设备可能仍被进程占用，请重启 Live 环境后再试。"
    fi

    dd if=/dev/zero of="$disk" bs=1M count=10 status=none || true
    partprobe "$disk" 2>/dev/null || true
    sgdisk --zap-all "$disk" 2>/dev/null || true
    partprobe "$disk" 2>/dev/null || true
    sleep 1
}

# ---------- 安装主流程 ----------
do_install() {
    print_step "1/7" "配置网络与软件源镜像"
    if ! command -v reflector &>/dev/null; then
        pacman -Sy --noconfirm reflector &>/dev/null
    fi
    run_with_spinner "筛选并更新中国区高速镜像源" reflector -p https -a 12 -c cn --sort rate --save /etc/pacman.d/mirrorlist
    run_with_spinner "同步 Pacman 软件包数据库" pacman -Sy

    print_step "2/7" "磁盘分区与格式化"
    clean_disk "$DISK"

    if [ "$UEFI_MODE" = true ]; then
        run_with_spinner "建立 GPT 分区表" parted -s "$DISK" mklabel gpt
        run_with_spinner "创建 ESP 引导分区 (512MiB)" parted -s "$DISK" mkpart primary fat32 1MiB 513MiB
        run_with_spinner "标记 ESP 标志" parted -s "$DISK" set 1 esp on
        BOOT_PART=$(get_part_name "$DISK" 1)
        next_start=513
        part_index=2
    else
        run_with_spinner "建立 MBR 分区表" parted -s "$DISK" mklabel msdos
        run_with_spinner "创建 BIOS Boot 分区 (1MiB)" parted -s "$DISK" mkpart primary 1MiB 2MiB
        run_with_spinner "标记 bios_grub 标志" parted -s "$DISK" set 1 bios_grub on
        run_with_spinner "创建 Boot 分区 (1GiB)" parted -s "$DISK" mkpart primary 2MiB 1026MiB
        BOOT_PART=$(get_part_name "$DISK" 2)
        next_start=1026
        part_index=3
    fi

    if [ "$SWAP_SIZE" -gt 0 ]; then
        swap_end=$(( next_start + SWAP_SIZE*1024 ))
        run_with_spinner "创建 SWAP 分区 (${SWAP_SIZE}GB)" parted -s "$DISK" mkpart primary linux-swap ${next_start}MiB ${swap_end}MiB
        SWAP_PART=$(get_part_name "$DISK" "$part_index")
        ((part_index++))
        next_start=$swap_end
    else
        SWAP_PART=""
    fi

    if [ -n "$ROOT_SIZE_PERCENT" ]; then
        run_with_spinner "创建 Btrfs 根分区 (${ROOT_SIZE_PERCENT}%)" parted -s "$DISK" mkpart primary ${next_start}MiB ${ROOT_SIZE_PERCENT}%
    else
        root_end=$(( next_start + ROOT_SIZE_GB*1024 ))
        run_with_spinner "创建 Btrfs 根分区 (${ROOT_SIZE_GB}GB)" parted -s "$DISK" mkpart primary ${next_start}MiB ${root_end}MiB
    fi
    ROOT_PART=$(get_part_name "$DISK" "$part_index")

    partprobe "$DISK" 2>/dev/null || true
    sleep 1

    run_with_spinner "格式化 ESP/Boot (FAT32)" mkfs.fat -F32 "$BOOT_PART"
    [ -n "$SWAP_PART" ] && run_with_spinner "格式化 SWAP 空间" mkswap "$SWAP_PART"
    run_with_spinner "格式化 Btrfs 根分区" mkfs.btrfs -f "$ROOT_PART"

    print_step "3/7" "构建 Btrfs 结构化子卷"
    run_with_spinner "临时挂载根分区" mount "$ROOT_PART" /mnt
    run_with_spinner "创建标准层级子卷 (@, @home, @snapshots...)" bash -c "
        btrfs subvolume create /mnt/@
        btrfs subvolume create /mnt/@home
        btrfs subvolume create /mnt/@var_cache
        btrfs subvolume create /mnt/@var_log
        btrfs subvolume create /mnt/@var_tmp
        btrfs subvolume create /mnt/@docker
        btrfs subvolume create /mnt/@snapshots
        btrfs subvolume create /mnt/@snapshots/root_snap
        btrfs subvolume create /mnt/@snapshots/home_snap
    "
    run_with_spinner "卸载临时根节点" umount /mnt

    print_step "4/7" "挂载系统目录"
    local btrfs_opts="compress=zstd,noatime,space_cache=v2,discard=async"
    run_with_spinner "挂载根子卷 (@)" mount -o "subvol=@,$btrfs_opts" "$ROOT_PART" /mnt
    mkdir -p /mnt/{home,var/{cache,log,tmp,lib/docker},boot,efi,snapshots}
    mount -o "subvol=@home,$btrfs_opts" "$ROOT_PART" /mnt/home
    mount -o "subvol=@var_cache,$btrfs_opts" "$ROOT_PART" /mnt/var/cache
    mount -o "subvol=@var_log,$btrfs_opts" "$ROOT_PART" /mnt/var/log
    mount -o "subvol=@var_tmp,$btrfs_opts" "$ROOT_PART" /mnt/var/tmp
    mount -o "subvol=@docker,$btrfs_opts" "$ROOT_PART" /mnt/var/lib/docker
    mount -o "subvol=@snapshots,$btrfs_opts" "$ROOT_PART" /mnt/snapshots
    mount "$BOOT_PART" /mnt/efi

    [ -n "$SWAP_PART" ] && swapon "$SWAP_PART"

    print_step "5/7" "执行 Pacstrap 安装系统核心"
    local packages=(
        base base-devel
        "$KERNEL_PKG" "$HEADERS_PKG"
        btrfs-progs dosfstools networkmanager iwd
        curl git vim vi sudo tldr dmidecode
        bash-completion terminus-font chezmoi just
    )
    [ -n "$UCODE_PKG" ] && packages+=("$UCODE_PKG")
    [ "$INSTALL_FIRMWARE" = true ] && packages+=("linux-firmware")
    if [ "$INSTALL_NVIDIA" = true ]; then
        if [ "$KERNEL_PKG" = "linux-zen" ]; then
            packages+=("nvidia-dkms" "nvidia-utils" "nvidia-settings")
        else
            packages+=("nvidia" "nvidia-utils" "nvidia-settings")
        fi
    fi
    [ -n "$AUDIO_SERVER" ] && packages+=("$AUDIO_SERVER")
    if [ "$AUDIO_SERVER" = "pipewire" ]; then
        packages+=("wireplumber" "pipewire-pulse" "pipewire-alsa" "pipewire-jack")
    fi
    [ "$BLUETOOTH_ENABLED" = true ] && packages+=("bluez" "bluez-utils")
    [ -n "$FIREWALL_TOOL" ] && packages+=("$FIREWALL_TOOL")
    [ "$PRINT_ENABLED" = true ] && packages+=("cups")

    run_with_spinner "安装基础系统与关键依赖 (时间取决于网速)" pacstrap -K /mnt "${packages[@]}"

    print_step "6/7" "生成挂载表 (fstab)"
    genfstab -U /mnt > /mnt/etc/fstab

    print_step "7/7" "进入 Chroot 配置新系统"
    local root_pass_b64 user_pass_b64
    root_pass_b64=$(printf "%s" "$ROOT_PASSWORD" | base64)
    user_pass_b64=$(printf "%s" "$USER_PASSWORD" | base64)

    cat > /mnt/root/install_vars.sh <<EOF
export USER_NAME="$USER_NAME"
export USER_PASS_B64="$user_pass_b64"
export ROOT_PASS_B64="$root_pass_b64"
export HOSTNAME="$HOSTNAME"
export UEFI_MODE="$UEFI_MODE"
export BOOTLOADER="$BOOTLOADER"
export DISK="$DISK"
export BLUETOOTH_ENABLED="$BLUETOOTH_ENABLED"
export PRINT_ENABLED="$PRINT_ENABLED"
export AUDIO_SERVER="$AUDIO_SERVER"
export ROOT_PART="$ROOT_PART"
export INSTALL_NVIDIA="$INSTALL_NVIDIA"
export KERNEL_PKG="$KERNEL_PKG"
export UCODE_PKG="$UCODE_PKG"
EOF
    chmod 700 /mnt/root/install_vars.sh

    local script_path="${BASH_SOURCE[0]}"
    if [ ! -f "$script_path" ]; then
        error_exit "无法定位安装脚本路径，请将脚本写入文件后运行。"
    fi
    cp "$script_path" /mnt/root/install_script.sh
    chmod +x /mnt/root/install_script.sh

    arch-chroot /mnt /bin/bash /root/install_script.sh --step chroot_auto

    rm -f /mnt/root/install_vars.sh /mnt/root/install_script.sh

    echo -e "\n${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}                恭喜！Arch Linux 系统安装成功！                  ${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}\n"
}

# ---------- Chroot 自动配置段 ----------
chroot_auto() {
    source /root/install_vars.sh

    timedatectl set-timezone Asia/Shanghai 2>/dev/null || ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    hwclock --systohc

    sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    echo "KEYMAP=us" > /etc/vconsole.conf

    echo "$HOSTNAME" > /etc/hostname
    cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF

    echo "root:$(printf "%s" "$ROOT_PASS_B64" | base64 -d)" | chpasswd
    useradd -m -G wheel "$USER_NAME"
    echo "$USER_NAME:$(printf "%s" "$USER_PASS_B64" | base64 -d)" | chpasswd
    echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel

    root_uuid=$(blkid -s UUID -o value "$ROOT_PART")

    # 根据内核选择定位镜像文件名
    case "$KERNEL_PKG" in
        linux-zen)
            kernel_img="vmlinuz-linux-zen"
            initrd_img="initramfs-linux-zen.img"
            initrd_fallback_img="initramfs-linux-zen-fallback.img"
            ;;
        linux-lts)
            kernel_img="vmlinuz-linux-lts"
            initrd_img="initramfs-linux-lts.img"
            initrd_fallback_img="initramfs-linux-lts-fallback.img"
            ;;
        *)
            kernel_img="vmlinuz-linux"
            initrd_img="initramfs-linux.img"
            initrd_fallback_img="initramfs-linux-fallback.img"
            ;;
    esac

    # 构建微码 initrd 参数（若存在 CPU 微码则注入）
    ucode_initrd=""
    if [ -n "$UCODE_PKG" ]; then
        ucode_initrd="initrd=\\boot\\${UCODE_PKG}.img "
    fi

    # ===== 引导程序安装 =====
    if [ "$UEFI_MODE" = true ]; then
        # 强制使用 systemd-boot
        pacman -S --noconfirm efibootmgr
        bootctl --esp-path=/efi install

        # systemd-boot 无法原生读取 Btrfs，故此处仍需将内核复制到 ESP 分区
        mkdir -p /efi/arch
        cp "/boot/${kernel_img}" "/efi/arch/${kernel_img}"
        cp "/boot/${initrd_img}" "/efi/arch/${initrd_img}"
        [ -n "$UCODE_PKG" ] && cp "/boot/${UCODE_PKG}.img" "/efi/arch/${UCODE_PKG}.img"

        mkdir -p /efi/loader/entries

        # 构建 systemd-boot 的 ucode 配置行
        ucode_line=""
        [ -n "$UCODE_PKG" ] && ucode_line="initrd  /arch/${UCODE_PKG}.img"

        cat > /efi/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /arch/${kernel_img}
${ucode_line}
initrd  /arch/${initrd_img}
options root=UUID=$root_uuid rootflags=subvol=@ rw add_efi_memmap
EOF

        cat > /efi/loader/loader.conf <<EOF
default arch
timeout 5
editor 0
console-mode auto
EOF

        # 维护 Pacman Hook 来同步 ESP 中的内核
        mkdir -p /etc/pacman.d/hooks
        cat > /etc/pacman.d/hooks/kernel-esp-copy.hook <<'HOOK'
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = linux
Target = linux-lts
Target = linux-zen
Target = intel-ucode
Target = amd-ucode

[Action]
Description = Copying kernel and initramfs to ESP for systemd-boot...
When = PostTransaction
Exec = /bin/sh -c 'cp /boot/vmlinuz-* /efi/arch/ && cp /boot/initramfs-*.img /efi/arch/ && cp /boot/*-ucode.img /efi/arch/ 2>/dev/null || true'
HOOK
    else
        # BIOS GRUB
        pacman -S --noconfirm grub
        grub-install --target=i386-pc "$DISK"
        sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"$/GRUB_CMDLINE_LINUX_DEFAULT="\1 rootflags=subvol=@"/' /etc/default/grub
        grub-mkconfig -o /boot/grub/grub.cfg
    fi

    # ---------- 服务与 initramfs 配置 ----------
    systemctl enable NetworkManager iwd
    [ "$BLUETOOTH_ENABLED" = true ] && systemctl enable bluetooth
    [ "$PRINT_ENABLED" = true ] && systemctl enable cups

    if ! grep -q "btrfs" /etc/mkinitcpio.conf; then
        sed -i 's/^HOOKS=(.*)/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck btrfs)/' /etc/mkinitcpio.conf
    fi

    if [ "$INSTALL_NVIDIA" = true ]; then
        sed -i 's/^MODULES=(.*)/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
    fi

    mkinitcpio -P

    rm -f /root/install_vars.sh /root/install_script.sh
}

# ---------- 程序入口 ----------
main() {
    if [ "$EUID" -ne 0 ]; then
        error_exit "此脚本必须使用 Root 权限运行！"
    fi

    if [[ "${1:-}" == "--step" ]]; then
        [ -z "${2:-}" ] && error_exit "未指定步骤名称"
        local step_func="$2"
        if declare -f "$step_func" > /dev/null; then
            $step_func
            exit 0
        else
            error_exit "无效步骤: $step_func"
        fi
    fi

    gather_info
    do_install

    if confirm "是否立即重启系统？" "y"; then
        reboot
    else
        info "请在完成后续自定义配置后手动运行 'reboot' 重启。"
        exit 0
    fi
}

main "$@"
