#!/usr/bin/env bash
# OneMix 1S+ 屏幕开机与登录横屏修复脚本 (Screen & Boot Rotation Setup)
# 适用系统: Ubuntu / Kubuntu 22.04, 24.04, 26.04 (KDE Plasma Wayland / X11)
# Fully Internationalized (i18n): English / 简体中文

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

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
FORCE_FLAG=0
for arg in "$@"; do
    case "$arg" in
        --force|-y) FORCE_FLAG=1 ;;
        --lang=en|-en|--en) UI_LANG="en" ;;
        --lang=zh|-zh|--zh) UI_LANG="zh" ;;
    esac
done
if [[ -z "${UI_LANG:-}" || "$UI_LANG" == "zh" ]]; then
    if [[ "${ONEMIX_LANG:-}" == "en" || "${LANG:-}" =~ ^en || "${LC_ALL:-}" =~ ^en || "${LANGUAGE:-}" =~ ^en ]]; then
        UI_LANG="en"
    fi
fi

check_root() {
    if [[ $EUID -ne 0 ]]; then
        if [[ "$UI_LANG" == "en" ]]; then
            log_err "This script requires root privileges. Please run with sudo:"
        else
            log_err "本脚本需要 root 权限，请使用 sudo 运行："
        fi
        echo -e "      ${CYAN}sudo bash $0 $@${RESET}\n"
        exit 1
    fi
}

check_root

# 极其关键的前提操作提示 (Mandatory Prerequisite Notice)
if [[ "$UI_LANG" == "en" ]]; then
    echo -e "${BOLD}${RED}【MANDATORY PREREQUISITE BEFORE PROCEEDING】${RESET}"
    echo -e "The OneMix 1S+ LCD panel has a native hardware portrait scan order (eDP-1)."
    echo -e "Before saving display rotation to system boot (GRUB/Plymouth) and SDDM,"
    echo -e "you MUST ensure the desktop environment is currently in proper landscape:\n"
    echo -e "  ${BOLD}${CYAN}Step 1: Open [System Settings] -> [Display and Monitor]${RESET}"
    echo -e "  ${BOLD}${CYAN}Step 2: In [Orientation], select the 4th option: [Counterclockwise 90°]${RESET}"
    echo -e "  ${BOLD}${CYAN}Step 3: Click [Apply], and verify the display is properly in landscape${RESET}\n"
    echo -e "${YELLOW}Reason: KDE Plasma only creates your user display config file${RESET}"
    echo -e "${YELLOW}(~/.config/kwinoutputconfig.json) after this step. This script syncs it to SDDM!${RESET}"
else
    echo -e "${BOLD}${RED}【重要前提操作 / MANDATORY PREREQUISITE】${RESET}"
    echo -e "OneMix 1S+ 的屏幕物理原生扫描方向为竖屏 (eDP-1)。"
    echo -e "在将旋转配置固化到系统引导 (GRUB/Plymouth) 和登录管理器 (SDDM) 之前，"
    echo -e "必须先确保桌面环境已经处于正确的正向横屏状态：\n"
    echo -e "  ${BOLD}${CYAN}步骤 1：打开【系统设置 (System Settings)】 -> 【显示和监视器 (Display and Monitor)】${RESET}"
    echo -e "  ${BOLD}${CYAN}步骤 2：在【方向 (Orientation)】下拉列表中，手动选择第 4 个选项：【逆时针转 90°】${RESET}"
    echo -e "  ${BOLD}${CYAN}步骤 3：点击【应用 (Apply)】，确认此时桌面显示方向完全正常（正向横屏）${RESET}\n"
    echo -e "${YELLOW}原因：只有手动完成此操作，KDE Plasma 才会生成正确的当前用户显示输出配置${RESET}"
    echo -e "${YELLOW}(~/.config/kwinoutputconfig.json)。本脚本会读取并同步该文件到 SDDM！${RESET}"
fi

if [[ $FORCE_FLAG -ne 1 ]]; then
    prompt_q="你是否已经在系统设置中将方向调整为【逆时针转 90°】并应用成功？[y/N]: "
    if [[ "$UI_LANG" == "en" ]]; then
        prompt_q="Have you set orientation to [Counterclockwise 90°] in System Settings and applied? [y/N]: "
    fi
    read -r -p "$prompt_q" confirm
    if [[ ! "$confirm" =~ ^[yY](es)?$ ]]; then
        if [[ "$UI_LANG" == "en" ]]; then
            log_warn "Operation cancelled. Please set orientation in System Settings first, then re-run."
        else
            log_warn "已取消操作。请先进入系统设置手动调整方向为逆时针 90° 后再次运行本脚本。"
        fi
        exit 0
    fi
fi

# 获取真实调用用户（避免在 sudo 下将 HOME 解析为 /root）
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

if [[ "$UI_LANG" == "en" ]]; then
    log_info "Target user: ${REAL_USER} (Home: ${REAL_HOME})"
else
    log_info "目标用户: ${REAL_USER} (家目录: ${REAL_HOME})"
fi

# 1. 配置内核参数与开机 Plymouth Logo (GRUB & Initramfs)
if [[ "$UI_LANG" == "en" ]]; then
    log_info "1/4 Configuring kernel cmdline and Plymouth boot splash parameters..."
else
    log_info "1/4 正在配置内核命令行与 Plymouth 开机动画参数..."
fi

GRUB_FILE="/etc/default/grub"
if [[ -f "$GRUB_FILE" ]]; then
    if grep -q "video=eDP-1:panel_orientation=right_side_up" "$GRUB_FILE"; then
        if [[ "$UI_LANG" == "en" ]]; then
            log_ok "eDP-1 orientation parameter already present in GRUB, skipping."
        else
            log_ok "GRUB 配置中已存在 eDP-1 旋转参数，跳过修改。"
        fi
    else
        cp "$GRUB_FILE" "${GRUB_FILE}.bak.$(date +%Y%m%d%H%M%S)"
        CURRENT_CMDLINE=$(grep '^GRUB_CMDLINE_LINUX_DEFAULT=' "$GRUB_FILE" | sed -E 's/^GRUB_CMDLINE_LINUX_DEFAULT="(.*)"/\1/')
        CLEANED_CMDLINE=$(echo "$CURRENT_CMDLINE" | sed -E 's/video=eDP-1:[^ ]*//g; s/fbcon=rotate:[0-9]//g; s/  +/ /g' | xargs)
        NEW_CMDLINE="${CLEANED_CMDLINE} video=eDP-1:panel_orientation=right_side_up fbcon=rotate:1"
        NEW_CMDLINE=$(echo "$NEW_CMDLINE" | xargs)
        sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"${NEW_CMDLINE}\"|" "$GRUB_FILE"
        if [[ "$UI_LANG" == "en" ]]; then
            log_ok "Updated ${GRUB_FILE} -> ${NEW_CMDLINE}"
            log_info "Updating GRUB boot files and Initramfs (may take a few seconds)..."
        else
            log_ok "已更新 ${GRUB_FILE} -> ${NEW_CMDLINE}"
            log_info "正在更新 GRUB 引导文件与 Initramfs (这可能需要十几秒)..."
        fi
        update-grub
        update-initramfs -u
        if [[ "$UI_LANG" == "en" ]]; then
            log_ok "GRUB and initramfs synchronization completed!"
        else
            log_ok "GRUB 与 initramfs 同步完成！"
        fi
    fi
else
    if [[ "$UI_LANG" == "en" ]]; then
        log_warn "${GRUB_FILE} not found, skipping kernel cmdline configuration."
    else
        log_warn "未找到 ${GRUB_FILE}，跳过 GRUB 参数配置。"
    fi
fi

# 2. 配置 SDDM 登录界面 (X11 Xsetup 兜底)
if [[ "$UI_LANG" == "en" ]]; then
    log_info "2/4 Configuring SDDM (X11) login startup script..."
else
    log_info "2/4 正在配置 SDDM (X11) 登录界面启动脚本..."
fi
SDDM_SCRIPT_DIR="/usr/share/sddm/scripts"
SDDM_XSETUP="${SDDM_SCRIPT_DIR}/Xsetup"

mkdir -p "$SDDM_SCRIPT_DIR"
touch "$SDDM_XSETUP"
chmod +x "$SDDM_XSETUP"

if grep -q "xrandr --output eDP-1 --rotate right" "$SDDM_XSETUP"; then
    if [[ "$UI_LANG" == "en" ]]; then
        log_ok "SDDM Xsetup already contains eDP-1 rotation rule, skipping."
    else
        log_ok "SDDM Xsetup 中已存在 eDP-1 旋转规则，跳过。"
    fi
else
    echo -e "\n# OneMix 1S+ Display Rotation\nxrandr --output eDP-1 --rotate right" >> "$SDDM_XSETUP"
    if [[ "$UI_LANG" == "en" ]]; then
        log_ok "Appended rule to ${SDDM_XSETUP}: xrandr --output eDP-1 --rotate right"
    else
        log_ok "已向 ${SDDM_XSETUP} 写入: xrandr --output eDP-1 --rotate right"
    fi
fi

# 3. 同步 KDE Plasma Wayland 显示配置至 SDDM
if [[ "$UI_LANG" == "en" ]]; then
    log_info "3/4 Synchronizing KDE Plasma Wayland screen config to SDDM system space..."
else
    log_info "3/4 正在同步 KDE Plasma Wayland 屏幕配置至 SDDM 系统空间..."
fi
USER_KWIN_CONFIG="${REAL_HOME}/.config/kwinoutputconfig.json"
SDDM_CONFIG_DIR="/var/lib/sddm/.config"
SDDM_KWIN_CONFIG="${SDDM_CONFIG_DIR}/kwinoutputconfig.json"

if [[ -f "$USER_KWIN_CONFIG" ]]; then
    mkdir -p "$SDDM_CONFIG_DIR"
    cp -f "$USER_KWIN_CONFIG" "$SDDM_KWIN_CONFIG"
    if id sddm &>/dev/null; then
        chown -R sddm:sddm "$SDDM_CONFIG_DIR"
    fi
    if [[ "$UI_LANG" == "en" ]]; then
        log_ok "Synchronized ${USER_KWIN_CONFIG} to ${SDDM_KWIN_CONFIG}"
    else
        log_ok "成功同步 ${USER_KWIN_CONFIG} 到 ${SDDM_KWIN_CONFIG}"
    fi
else
    if [[ "$UI_LANG" == "en" ]]; then
        log_warn "Config file not found at ${USER_KWIN_CONFIG}."
        log_warn "Ensure you clicked [Apply] in KDE System Settings. X11 Xsetup rule is active."
    else
        log_warn "未在 ${USER_KWIN_CONFIG} 检测到配置文件。"
        log_warn "请确认你已在 KDE 系统设置中点击【应用】。若使用 X11 会话，Xsetup 规则已生效。"
    fi
fi

# 4. 安装硬件级横屏 GRUB 引导器 (Kyle Bader 2D Framebuffer 补丁)
INSTALL_GRUB_SCRIPT="${REPO_ROOT}/packages/bootloader/install-rotated-grub.sh"
if [[ -f "$INSTALL_GRUB_SCRIPT" ]]; then
    echo ""
    if [[ "$UI_LANG" == "en" ]]; then
        log_info "4/4 Checking Hardware-Rotated GRUB Bootloader..."
        if [[ $FORCE_FLAG -eq 1 ]]; then
            bash "$INSTALL_GRUB_SCRIPT" --lang="${UI_LANG}"
        else
            read -r -p "Install OneMix 1S+ Rotated GRUB Bootloader (Standalone EFI, 100% safe dual-boot)? [Y/n]: " grub_confirm
            grub_confirm="${grub_confirm:-y}"
            if [[ "$grub_confirm" =~ ^[yY](es)?$ ]]; then
                bash "$INSTALL_GRUB_SCRIPT" --lang="${UI_LANG}"
            else
                log_info "Skipped rotated GRUB install. You can install it later via packages/bootloader/install-rotated-grub.sh"
            fi
        fi
    else
        log_info "4/4 硬件级横屏 GRUB 引导器..."
        if [[ $FORCE_FLAG -eq 1 ]]; then
            bash "$INSTALL_GRUB_SCRIPT" --lang="${UI_LANG}"
        else
            read -r -p "是否同时安装 OneMix 1S+ 专属横屏 GRUB 引导器 (独立 EFI，100% 不破坏原有 Ubuntu/Windows 引导)？[Y/n]: " grub_confirm
            grub_confirm="${grub_confirm:-y}"
            if [[ "$grub_confirm" =~ ^[yY](es)?$ ]]; then
                bash "$INSTALL_GRUB_SCRIPT" --lang="${UI_LANG}"
            else
                log_info "已跳过横屏 GRUB 安装。如需稍后单独安装，可运行 packages/bootloader/install-rotated-grub.sh"
            fi
        fi
    fi
fi

if [[ "$UI_LANG" == "en" ]]; then
    echo -e "${BOLD}${GREEN}[COMPLETED] Full Boot-to-Desktop Landscape Configuration Applied!${RESET}"
    echo -e "Configured components:"
    echo -e "  ✔ Kernel cmdline: video=eDP-1:panel_orientation=right_side_up fbcon=rotate:1"
    echo -e "  ✔ SDDM X11 script: /usr/share/sddm/scripts/Xsetup"
    echo -e "  ✔ SDDM Wayland: /var/lib/sddm/.config/kwinoutputconfig.json"
    echo -e "  ✔ Rotated GRUB: packages/bootloader/grubx64_rotated.efi (Standalone EFI)"
    echo -e "\nRecommended: Reboot to verify Plymouth splash, SDDM, and desktop landscape:"
    echo -e "      ${CYAN}sudo reboot${RESET}\n"
else
    echo -e "${BOLD}${GREEN}【完成】屏幕开机全链路横屏配置已成功写入！${RESET}"
    echo -e "配置清单："
    echo -e "  ✔ 内核启动参数: video=eDP-1:panel_orientation=right_side_up fbcon=rotate:1"
    echo -e "  ✔ SDDM X11 脚本: /usr/share/sddm/scripts/Xsetup"
    echo -e "  ✔ SDDM Wayland: /var/lib/sddm/.config/kwinoutputconfig.json"
    echo -e "  ✔ 专属横屏 GRUB: packages/bootloader/grubx64_rotated.efi (独立 EFI 项)"
    echo -e "\n建议重启设备以检验开机 Logo、登录界面与桌面的完整横屏效果："
    echo -e "      ${CYAN}sudo reboot${RESET}\n"
fi
