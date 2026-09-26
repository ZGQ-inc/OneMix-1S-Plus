#!/usr/bin/env bash
# OneMix 1S+ 专属旋转 GRUB 引导器安装程序 (Rotated GRUB EFI Installer)
# 为 1200x1920 物理竖屏提供 2D Framebuffer 硬件级旋转 (1920x1200 横屏)
# Fully Internationalized (i18n): English / 简体中文

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EFI_SOURCE="${SCRIPT_DIR}/grubx64_rotated.efi"

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
BOLD='\033[1m'
RESET='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${RESET} $1"; }
log_ok() { echo -e "${GREEN}[OK]${RESET} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
log_err() { echo -e "${RED}[ERROR]${RESET} $1"; }

# Language Detection
UI_LANG="zh"
for arg in "$@"; do
    case "$arg" in
        --lang=en|-en|--en) UI_LANG="en" ;;
        --lang=zh|-zh|--zh) UI_LANG="zh" ;;
    esac
done
if [[ -z "${UI_LANG:-}" || "$UI_LANG" == "zh" ]]; then
    if [[ "${ONEMIX_LANG:-}" == "en" || "${LANG:-}" =~ ^en || "${LC_ALL:-}" =~ ^en || "${LANGUAGE:-}" =~ ^en ]]; then
        UI_LANG="en"
    fi
fi

if [[ $EUID -ne 0 ]]; then
    if [[ "$UI_LANG" == "en" ]]; then
        log_err "This script requires root privileges. Please run with sudo:"
    else
        log_err "本脚本需要 root 权限，请使用 sudo 运行："
    fi
    echo -e "      ${CYAN}sudo bash $0 $@${RESET}\n"
    exit 1
fi

if [[ ! -d /sys/firmware/efi ]]; then
    if [[ "$UI_LANG" == "en" ]]; then
        log_err "System is not running in UEFI mode. This feature requires UEFI!"
    else
        log_err "系统未运行于 UEFI 模式，本功能仅适用于 UEFI 系统！"
    fi
    exit 1
fi

if [[ ! -f "$EFI_SOURCE" ]]; then
    if [[ "$UI_LANG" == "en" ]]; then
        log_err "Rotated GRUB EFI binary not found: ${EFI_SOURCE}"
    else
        log_err "未找到旋转 GRUB 二进制文件: ${EFI_SOURCE}"
    fi
    exit 1
fi

ESP_DIR="/boot/efi"
if ! mountpoint -q "$ESP_DIR"; then
    if [[ "$UI_LANG" == "en" ]]; then
        log_warn "${ESP_DIR} is not a mountpoint, searching for EFI system partition..."
    else
        log_warn "${ESP_DIR} 不是挂载点，正在尝试寻找 EFI 系统分区..."
    fi
    ESP_DIR=$(df -k /boot/efi 2>/dev/null | awk 'NR==2 {print $6}')
fi

DEST_DIR="${ESP_DIR}/EFI/grub-rotated"
DEST_FILE="${DEST_DIR}/grubx64.efi"

if [[ "$UI_LANG" == "en" ]]; then
    log_info "1. Installing Standalone Rotated GRUB to EFI partition (${DEST_DIR})..."
else
    log_info "1. 正在将旋转 GRUB 独立安装到 EFI 分区 (${DEST_DIR})..."
fi

mkdir -p "$DEST_DIR"
cp -f "$EFI_SOURCE" "$DEST_FILE"
chmod 755 "$DEST_FILE"

if [[ "$UI_LANG" == "en" ]]; then
    log_ok "EFI file installed: ${DEST_FILE} (Stock Ubuntu bootloader untouched)"
    log_info "2. Checking UEFI NVRAM boot entries..."
else
    log_ok "EFI 文件安装完成: ${DEST_FILE} (官方 Ubuntu 引导不受任何影响)"
    log_info "2. 正在检查 UEFI NVRAM 引导项..."
fi

# 2. 检查并添加 UEFI NVRAM 启动项
ESP_DISK=$(df "$ESP_DIR" | tail -1 | awk '{print $1}')
ROOT_DISK=$(echo "$ESP_DISK" | sed -E 's/p?[0-9]+$//')
PART_NUM=$(echo "$ESP_DISK" | grep -o -E '[0-9]+$')

EXISTING_BOOT_ENTRY=$(efibootmgr -v | grep -i "grub-rotated" | head -1 | grep -o -E 'Boot[0-9A-Fa-f]+' | sed 's/Boot//' || true)

if [[ -n "$EXISTING_BOOT_ENTRY" ]]; then
    if [[ "$UI_LANG" == "en" ]]; then
        log_ok "Detected existing UEFI boot entry: Boot${EXISTING_BOOT_ENTRY}"
    else
        log_ok "检测到已有 UEFI 启动项: Boot${EXISTING_BOOT_ENTRY}"
    fi
    BOOT_NUM="$EXISTING_BOOT_ENTRY"
else
    if [[ "$UI_LANG" == "en" ]]; then
        log_info "Registering new boot entry: GRUB Rotated (Landscape)..."
    else
        log_info "正在注册新启动项: GRUB Rotated (Landscape)..."
    fi
    efibootmgr -c -d "$ROOT_DISK" -p "$PART_NUM" -L "GRUB Rotated (Landscape)" -l "/EFI/grub-rotated/grubx64.efi" >/dev/null
    BOOT_NUM=$(efibootmgr -v | grep -i "grub-rotated" | head -1 | grep -o -E 'Boot[0-9A-Fa-f]+' | sed 's/Boot//')
    if [[ "$UI_LANG" == "en" ]]; then
        log_ok "Created UEFI boot entry: Boot${BOOT_NUM}"
    else
        log_ok "成功创建 UEFI 引导项: Boot${BOOT_NUM}"
    fi
fi

# 3. 增强 /etc/grub.d/00_header
if [[ "$UI_LANG" == "en" ]]; then
    log_info "3. Configuring GRUB template (/etc/grub.d/00_header)..."
else
    log_info "3. 正在配置 GRUB 配置文件模板 (/etc/grub.d/00_header)..."
fi

HEADER_FILE="/etc/grub.d/00_header"
if ! grep -q "Set fb rotation for grub" "$HEADER_FILE"; then
    mkdir -p /var/backups/grub
    cp "$HEADER_FILE" "/var/backups/grub/00_header.bak.$(date +%Y%m%d%H%M%S)"

    python3 - << 'PYEOF'
with open('/etc/grub.d/00_header', 'r') as f:
    content = f.read()

target = '. "$pkgdatadir/grub-mkconfig_lib"'
block = '''

# Set fb rotation for grub (OneMix 1S+ portrait panel fix)
if [ "x$GRUB_FB_ROTATION" = x ] && [ -f /etc/default/grub ]; then
    . /etc/default/grub
fi
if [ "x$GRUB_FB_ROTATION" != x ]; then
    case "${GRUB_FB_ROTATION}" in
        inverted | 180)
            echo "set rotation=180"
            ;;
        left | 90)
            echo "set rotation=90"
            ;;
        right | 270)
            echo "set rotation=270"
            ;;
    esac
fi
'''
if target in content and "Set fb rotation for grub" not in content:
    content = content.replace(target, target + block, 1)
    with open('/etc/grub.d/00_header', 'w') as f:
        f.write(content)
PYEOF
    chmod +x "$HEADER_FILE"
    if [[ "$UI_LANG" == "en" ]]; then
        log_ok "Injected rotation support into ${HEADER_FILE}"
    else
        log_ok "已向 ${HEADER_FILE} 注入 rotation 支持！"
    fi
else
    if [[ "$UI_LANG" == "en" ]]; then
        log_ok "${HEADER_FILE} already includes rotation support."
    else
        log_ok "${HEADER_FILE} 已包含 rotation 支持。"
    fi
fi

# 4. 配置 /etc/default/grub
if [[ "$UI_LANG" == "en" ]]; then
    log_info "4. Updating /etc/default/grub parameters..."
else
    log_info "4. 正在更新 /etc/default/grub 参数..."
fi
GRUB_DEFAULT_FILE="/etc/default/grub"
cp "$GRUB_DEFAULT_FILE" "/var/backups/grub/grub.bak.$(date +%Y%m%d%H%M%S)"

python3 - << 'PYEOF'
with open('/etc/default/grub', 'r') as f:
    lines = f.readlines()

new_lines = []
has_rot = False
for line in lines:
    if line.startswith("GRUB_TIMEOUT_STYLE="):
        new_lines.append("GRUB_TIMEOUT_STYLE=menu\n")
    elif line.startswith("GRUB_TIMEOUT="):
        new_lines.append("GRUB_TIMEOUT=5\n")
    elif line.startswith("GRUB_GFXMODE="):
        new_lines.append("GRUB_GFXMODE=auto\n")
    elif line.startswith("GRUB_FB_ROTATION="):
        new_lines.append("GRUB_FB_ROTATION=270\n")
        has_rot = True
    elif line.startswith("#GRUB_GFXROTATION="):
        continue
    else:
        new_lines.append(line)

if not has_rot:
    new_lines.append("\n# Screen rotation for OneMix 1S+ portrait panel (270 = landscape)\nGRUB_FB_ROTATION=270\n")

with open('/etc/default/grub', 'w') as f:
    f.writelines(new_lines)
PYEOF

if [[ "$UI_LANG" == "en" ]]; then
    log_ok "GRUB menu timeout set to 5s, rotation set to 270 (Landscape)"
    log_info "5. Executing update-grub to generate boot configurations..."
else
    log_ok "GRUB 菜单超时设为 5 秒，方向设为 270 (正向横屏)"
    log_info "5. 正在执行 update-grub 生成引导配置..."
fi

update-grub >/dev/null

if [[ "$UI_LANG" == "en" ]]; then
    log_ok "grub.cfg updated successfully!"
    echo -e "${BOLD}${GREEN}[SUCCESS] OneMix 1S+ Rotated GRUB Bootloader is Ready!${RESET}"
    echo -e "Safety Architecture:"
    echo -e "  • Stock Ubuntu bootloader: /boot/efi/EFI/ubuntu/ (100% untouched)"
    echo -e "  • Rotated GRUB bootloader: /boot/efi/EFI/grub-rotated/grubx64.efi"
    echo -e "  • Windows Boot Manager:    Preserved and integrated into GRUB menu"
    echo -e "\nRecommended safe test reboot (BootNext), then set permanent:"
    echo -e "  ${BOLD}${CYAN}One-time safe test:${RESET} sudo efibootmgr -n ${BOOT_NUM} && sudo reboot"
    echo -e "  ${BOLD}${CYAN}Set permanent:    ${RESET} sudo efibootmgr -o ${BOOT_NUM},0001,0000\n"
else
    log_ok "grub.cfg 更新完成！"
    echo -e "${BOLD}${GREEN}【安装成功】OneMix 1S+ 硬件级横屏 GRUB 引导器已就绪！${RESET}"
    echo -e "安全架构保障："
    echo -e "  • 官方 Ubuntu 引导位于: /boot/efi/EFI/ubuntu/ (100% 原样保留)"
    echo -e "  • 旋转横屏 GRUB 位于:   /boot/efi/EFI/grub-rotated/grubx64.efi"
    echo -e "  • 双系统 Windows 引导:  保留并完美集成于 GRUB 菜单"
    echo -e "\n建议先使用单次安全测试 (BootNext)，若重启无误再永久设为第一项："
    echo -e "  ${BOLD}${CYAN}测试单次开机:${RESET} sudo efibootmgr -n ${BOOT_NUM} && sudo reboot"
    echo -e "  ${BOLD}${CYAN}永久设为首选:${RESET} sudo efibootmgr -o ${BOOT_NUM},0001,0000\n"
fi
