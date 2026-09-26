#!/usr/bin/env bash
# OneMix 1S+ 专属优化工具箱 (OneMix-1S-Plus Master Toolkit CLI)
# Deep hardware tuning for One-Netbook OneMix 1S+ (Intel Core m3-8100Y)
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
export ONEMIX_LANG="$UI_LANG"

print_banner() {
    clear 2>/dev/null || true
    echo -e "${CYAN}"
    echo "  ██████╗ ███╗   ██╗███████╗███╗   ███╗██╗██╗  ██╗       ██╗███████╗   ██╗   "
    echo " ██╔═══██╗████╗  ██║██╔════╝████╗ ████║██║╚██╗██╔╝      ███║██╔════╝   ██║   "
    echo " ██║   ██║██╔██╗ ██║█████╗  ██╔████╔██║██║ ╚███╔╝ █████╗╚██║███████╗████████╗"
    echo " ██║   ██║██║╚██╗██║██╔══╝  ██║╚██╔╝██║██║ ██╔██╗ ╚════╝ ██║╚════██║╚══██╔══╝"
    echo " ╚██████╔╝██║ ╚████║███████╗██║ ╚═╝ ██║██║██╔╝ ██╗      ██║███████║   ██║   "
    echo "  ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝     ╚═╝╚═╝╚═╝  ╚═╝      ╚═╝╚══════╝   ╚═╝   "
    echo -e "${RESET}"
    if [[ "$UI_LANG" == "en" ]]; then
        echo -e "${BOLD}     One-Netbook OneMix 1S+ (m3-8100Y) Dedicated Optimization Toolkit${RESET}"
        echo -e "                   https://github.com/ZGQ-inc/OneMix-1S-Plus\n"
    else
        echo -e "${BOLD}         壹号本 OneMix 1S+ (m3-8100Y) 专属优化与避坑工具箱${RESET}"
        echo -e "                   https://github.com/ZGQ-inc/OneMix-1S-Plus\n"
    fi
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        if [[ "$UI_LANG" == "en" ]]; then
            echo -e "${RED}[ERROR]${RESET} This action requires root privileges. Please run with sudo:"
        else
            echo -e "${RED}[ERROR]${RESET} 本功能需要 root 权限，请重新使用 sudo 运行："
        fi
        echo -e "      ${CYAN}sudo bash $0 --lang=${UI_LANG}${RESET}\n"
        exit 1
    fi
}

show_menu() {
    print_banner
    if [[ "$UI_LANG" == "en" ]]; then
        echo -e "${BOLD}${BLUE}Select an operation to perform:${RESET}"
        echo -e "  ${BOLD}[1] End-to-End Boot & Screen Rotation Setup${RESET} (GRUB / Plymouth / SDDM)"
        echo -e "      ${YELLOW}* Mandatory: Open System Settings -> Display and set Counterclockwise 90° first!${RESET}"
        echo -e "  ${BOLD}[2] Accelerometer Calibration & Auto-Rotation${RESET} (Bosch BMA2x / BOSC0200 hwdb)"
        echo -e "  ${BOLD}[3] FocalTech FT9536W Fingerprint Driver Installation${RESET} (Modern Linux / 2808:9338)"
        echo -e "  ${BOLD}[4] Intel m3-8100Y TDP & Thermal Profile Tuning${RESET} (Quiet 4.5W / Balanced 7W / Perf 10W)"
        echo -e "  ${BOLD}[5] Run Full Hardware Diagnostics${RESET} (Screen, Board, MCU, Fingerprint, Sensors)"
        echo -e "  ${BOLD}[6] View Keyboard Firmware & Windows Driver Guide${RESET} (OFN Fix & Official Links)"
        echo -e "  ${BOLD}[7] Hardware Rotated GRUB Bootloader Installer${RESET} (Standalone EFI / 2D Framebuffer)"
        echo -e "  ${BOLD}[L] Switch Language / 切换语言${RESET} [Current: ${GREEN}English${RESET}]"
        echo -e "  ${BOLD}[0] Exit${RESET}"
    else
        echo -e "${BOLD}${BLUE}请选择要执行的操作：${RESET}"
        echo -e "  ${BOLD}[1] 屏幕开机与登录横屏修复${RESET} (GRUB / Plymouth / SDDM 完整横屏)"
        echo -e "      ${YELLOW}* 运行前请务必先在【系统设置->显示】手动选第4个【逆时针转90°】应用${RESET}"
        echo -e "  ${BOLD}[2] 重力感应校准与自动转屏${RESET} (Bosch BMA2x / BOSC0200 hwdb 矩阵修复)"
        echo -e "  ${BOLD}[3] FocalTech FT9536W 指纹驱动安装${RESET} (USB ID 2808:9338 现代 Linux 驱动)"
        echo -e "  ${BOLD}[4] Intel m3-8100Y 功耗墙与温控调节${RESET} (省电 4.5W / 均衡 7W / 性能 10W)"
        echo -e "  ${BOLD}[5] 运行硬件全景体检与诊断${RESET} (屏幕、主板、键盘MCU、指纹、传感器)"
        echo -e "  ${BOLD}[6] 查看键盘固件与 Windows 驱动指南${RESET} (OFN 修复说明与官方直链)"
        echo -e "  ${BOLD}[7] 安装/管理横屏 GRUB 引导器${RESET} (独立 EFI / 2D Framebuffer 硬件级旋转)"
        echo -e "  ${BOLD}[L] 切换语言 / Switch Language${RESET} [当前: ${GREEN}简体中文${RESET}]"
        echo -e "  ${BOLD}[0] 退出${RESET}"
    fi
    echo ""
}

view_firmware_guide() {
    clear 2>/dev/null || true
    if [[ "$UI_LANG" == "en" ]]; then
        echo -e "${BOLD}${CYAN}OneMix 1S+ Keyboard Firmware & Windows Driver Guide${RESET}\n"
        echo -e "${BOLD}${YELLOW}1. Hardware Platform & Windows Drivers:${RESET}"
        echo -e "   - The OneMix 1S+ motherboard uses the 2nd-gen Core m3-8100Y architecture."
        echo -e "   - Under Windows, for all hardware (chipset, GPU, audio, Wi-Fi, BT, sensor),"
        echo -e "     download the official 2nd-generation driver suite:"
        echo -e "     ${BOLD}${CYAN}Direct Link: https://download.one-netbook.com/驱动/二代驱动/二代完整驱动包.rar${RESET}\n"
        echo -e "${BOLD}${YELLOW}2. Keyboard Flex Cable & OFN Optical Mouse Firmware Issue:${RESET}"
        echo -e "   - The 1S+ chassis internal keyboard PCB uses 1st-gen matrix routing with 2nd-gen board control."
        echo -e "   - Official FW1 swaps Fn and Ctrl keys; official FW2 scrambles top numbers and rotates mouse 90°."
        echo -e "   - This repository provides the fully reverse-engineered & verified custom firmware:"
        echo -e "     ${GREEN}firmware/OFN_1S+_Perfect_Final.hex${RESET}"
        echo -e "   - The Windows flashing tool is included:"
        echo -e "     ${GREEN}firmware/Hailuck_KeyBoard_Update_Tool_for_68F83.exe${RESET}"
        echo -e "   - Result: Ctrl/Fn restored, 100% keycap match, true mouse navigation, Fn+Esc backlight support.\n"
        read -r -p "Press Enter to return to menu..."
    else
        echo -e "${BOLD}${CYAN}OneMix 1S+ 键盘固件与 Windows 驱动说明指南${RESET}\n"
        echo -e "${BOLD}${YELLOW}1. 硬件本质与 Windows 驱动：${RESET}"
        echo -e "   - OneMix 1S+ 的主板核心实际上是【二代架构 (m3-8100Y)】，而非一代 (Atom/3965Y)。"
        echo -e "   - 在 Windows 系统下，除键盘固件外，所有驱动（主板芯片组、显卡、声卡、无线网卡、"
        echo -e "     指纹、红外/蓝牙等）请直接使用壹号本官方二代完整驱动包："
        echo -e "     ${BOLD}${CYAN}官方直链下载：https://download.one-netbook.com/驱动/二代驱动/二代完整驱动包.rar${RESET}\n"
        echo -e "${BOLD}${YELLOW}2. 键盘与 OFN 光学触控板固件问题：${RESET}"
        echo -e "   - 1S+ 内部键盘 PCB 物理走线采用的是 1S 的矩阵走线，但搭配了 2 代主板控制，"
        echo -e "     导致原厂固件出现 Fn 与 Ctrl 颠倒、二代固件数字键与符号键错位、触控板 90° 旋转。"
        echo -e "   - 本仓库已提供逆向反汇编并彻底修复的完美固件："
        echo -e "     ${GREEN}firmware/OFN_1S+_Perfect_Final.hex${RESET}"
        echo -e "   - 刷写工具直接存放在本仓库："
        echo -e "     ${GREEN}firmware/Hailuck_KeyBoard_Update_Tool_for_68F83.exe${RESET}"
        echo -e "   - 刷写效果：Ctrl/Fn 归位、所有键位 100% 对应键帽、触控板上下左右完全同步、"
        echo -e "     保留 Fn+Esc 翻转 P3.1 引脚背光控制。\n"
        read -r -p "按回车键返回主菜单..."
    fi
}

main() {
    while true; do
        show_menu
        prompt_text="请输入选项 [0-7, L]: "
        if [[ "$UI_LANG" == "en" ]]; then
            prompt_text="Enter your choice [0-7, L]: "
        fi
        read -r -p "$prompt_text" choice
        case "$choice" in
            1)
                check_root
                bash "${SCRIPT_DIR}/01-setup-screen-rotation.sh" --lang="${UI_LANG}"
                read -r -p "$( [[ "$UI_LANG" == "en" ]] && echo "Press Enter to return..." || echo "按回车键返回主菜单..." )"
                ;;
            2)
                check_root
                bash "${SCRIPT_DIR}/02-setup-sensor-gyroscope.sh" --lang="${UI_LANG}"
                read -r -p "$( [[ "$UI_LANG" == "en" ]] && echo "Press Enter to return..." || echo "按回车键返回主菜单..." )"
                ;;
            3)
                check_root
                bash "${SCRIPT_DIR}/03-install-fingerprint.sh" --lang="${UI_LANG}"
                read -r -p "$( [[ "$UI_LANG" == "en" ]] && echo "Press Enter to return..." || echo "按回车键返回主菜单..." )"
                ;;
            4)
                check_root
                bash "${SCRIPT_DIR}/04-tune-m3-power-thermal.sh" --lang="${UI_LANG}"
                read -r -p "$( [[ "$UI_LANG" == "en" ]] && echo "Press Enter to return..." || echo "按回车键返回主菜单..." )"
                ;;
            5)
                bash "${SCRIPT_DIR}/onemix-hardware-diagnose.sh" --lang="${UI_LANG}"
                read -r -p "$( [[ "$UI_LANG" == "en" ]] && echo "Press Enter to return..." || echo "按回车键返回主菜单..." )"
                ;;
            6)
                view_firmware_guide
                ;;
            7)
                check_root
                bash "${REPO_ROOT}/packages/bootloader/install-rotated-grub.sh" --lang="${UI_LANG}"
                read -r -p "$( [[ "$UI_LANG" == "en" ]] && echo "Press Enter to return..." || echo "按回车键返回主菜单..." )"
                ;;
            l|L)
                if [[ "$UI_LANG" == "en" ]]; then
                    UI_LANG="zh"
                else
                    UI_LANG="en"
                fi
                export ONEMIX_LANG="$UI_LANG"
                ;;
            0|q|Q)
                if [[ "$UI_LANG" == "en" ]]; then
                    echo -e "\nThank you for using OneMix 1S+ Toolkit. Goodbye!\n"
                else
                    echo -e "\n感谢使用 OneMix 1S+ 专属优化工具箱，再见！\n"
                fi
                exit 0
                ;;
            *)
                if [[ "$UI_LANG" == "en" ]]; then
                    echo -e "${RED}Invalid option. Please try again.${RESET}"
                else
                    echo -e "${RED}无效选项，请重新输入。${RESET}"
                fi
                sleep 1
                ;;
        esac
    done
}

main "$@"
