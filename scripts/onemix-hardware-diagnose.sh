#!/usr/bin/env bash
# OneMix 1S+ 硬件全景状态检测与诊断脚本 (Hardware Diagnosis Tool)
# Fully Internationalized (i18n): English / 简体中文

set -euo pipefail

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

if [[ "$UI_LANG" == "en" ]]; then
    echo -e "\n${BOLD}${CYAN}OneMix 1S+ Full Hardware & Subsystem Diagnostic Report${RESET}\n"
else
    echo -e "\n${BOLD}${CYAN}壹号本 OneMix 1S+ 硬件状态全景诊断报告 (Hardware Diagnosis)${RESET}\n"
fi

# 1. 主板与 BIOS
if [[ "$UI_LANG" == "en" ]]; then
    echo -e "${BOLD}[1/8] System & Motherboard Information (DMI & BIOS)${RESET}"
else
    echo -e "${BOLD}[1/8] 系统与主板信息 (DMI & BIOS)${RESET}"
fi
SYS_VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "Unknown")
PROD_NAME=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "Unknown")
BIOS_VER=$(cat /sys/class/dmi/id/bios_version 2>/dev/null || echo "Unknown")
BIOS_DATE=$(cat /sys/class/dmi/id/bios_date 2>/dev/null || echo "Unknown")
if [[ "$UI_LANG" == "en" ]]; then
    echo -e "  Vendor / Model: ${GREEN}${SYS_VENDOR} / ${PROD_NAME}${RESET}"
    echo -e "  BIOS Version:   ${GREEN}${BIOS_VER} (${BIOS_DATE})${RESET}"
else
    echo -e "  厂商/型号: ${GREEN}${SYS_VENDOR} / ${PROD_NAME}${RESET}"
    echo -e "  BIOS 版本: ${GREEN}${BIOS_VER} (${BIOS_DATE})${RESET}"
fi

# 2. 处理器
if [[ "$UI_LANG" == "en" ]]; then
    echo -e "\n${BOLD}[2/8] CPU & Thermal Sensors${RESET}"
else
    echo -e "\n${BOLD}[2/8] 处理器状态 (CPU & Temperature)${RESET}"
fi
CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | xargs || echo "Unknown")
CPU_CORES=$(grep -c "^processor" /proc/cpuinfo || echo "0")
if [[ "$UI_LANG" == "en" ]]; then
    echo -e "  Model:       ${GREEN}${CPU_MODEL}${RESET} (${CPU_CORES} logical threads)"
else
    echo -e "  型号:        ${GREEN}${CPU_MODEL}${RESET} (${CPU_CORES} 逻辑核心)"
fi
if ls -d /sys/class/thermal/thermal_zone* &>/dev/null; then
    for tz in /sys/class/thermal/thermal_zone*; do
        TYPE=$(cat "${tz}/type" 2>/dev/null || echo "zone")
        if [[ -f "${tz}/temp" ]]; then
            TEMP_C=$(awk '{print $1 / 1000}' "${tz}/temp")
            if [[ "$UI_LANG" == "en" ]]; then
                echo -e "  Temperature (${TYPE}): ${YELLOW}${TEMP_C} °C${RESET}"
            else
                echo -e "  温度 (${TYPE}): ${YELLOW}${TEMP_C} °C${RESET}"
            fi
        fi
    done
fi

# 3. 屏幕与显示接口
if [[ "$UI_LANG" == "en" ]]; then
    echo -e "\n${BOLD}[3/8] Display Panel & Interface (eDP-1)${RESET}"
    EDP_STATUS="Disconnected"
else
    echo -e "\n${BOLD}[3/8] 显示接口与屏幕朝向 (Display & Panel)${RESET}"
    EDP_STATUS="未连接"
fi
if [[ -f /sys/class/drm/card0-eDP-1/status ]]; then
    EDP_STATUS=$(cat /sys/class/drm/card0-eDP-1/status)
fi
if [[ "$UI_LANG" == "en" ]]; then
    echo -e "  Internal Interface (eDP-1): ${GREEN}${EDP_STATUS}${RESET}"
else
    echo -e "  内部显示通道 (eDP-1): ${GREEN}${EDP_STATUS}${RESET}"
fi
if command -v xrandr &>/dev/null && [[ -n "${DISPLAY:-}" ]]; then
    XR_INFO=$(xrandr --current 2>/dev/null | grep -A1 "eDP-1" || true)
    if [[ "$UI_LANG" == "en" ]]; then
        echo -e "  X11 Display Output:\n    ${XR_INFO}"
    else
        echo -e "  X11 显示状态:\n    ${XR_INFO}"
    fi
fi

# 4. 键盘与 OFN 光学触控板
if [[ "$UI_LANG" == "en" ]]; then
    echo -e "\n${BOLD}[4/8] Keyboard & Optical Mouse (MCU: SH68F83)${RESET}"
    if command -v lsusb &>/dev/null && lsusb | grep -qi "258a:0021"; then
        echo -e "  ${GREEN}✔ Detected MCU controller (USB ID 258a:0021 HAILUCK KEYBOARD)${RESET}"
    else
        echo -e "  ${RED}✘ 258a:0021 controller not found on USB bus${RESET}"
    fi
else
    echo -e "\n${BOLD}[4/8] 键盘与 OFN 触控板 (Keyboard MCU: SH68F83)${RESET}"
    if command -v lsusb &>/dev/null && lsusb | grep -qi "258a:0021"; then
        echo -e "  ${GREEN}✔ 已检测到中颖/海栎创主控 (USB ID 258a:0021 HAILUCK KEYBOARD)${RESET}"
    else
        echo -e "  ${RED}✘ 未检索到 258a:0021 键盘控制器，请检查 USB 链接${RESET}"
    fi
fi

# 5. 指纹传感器
if [[ "$UI_LANG" == "en" ]]; then
    echo -e "\n${BOLD}[5/8] Fingerprint Sensor (FocalTech FT9536W / 2808:9338)${RESET}"
    if command -v lsusb &>/dev/null && lsusb | grep -qi "2808:9338"; then
        echo -e "  ${GREEN}✔ Detected sensor hardware (USB ID 2808:9338 FocalTech Fingerprint)${RESET}"
        if dpkg -s libfprint-2-2 2>/dev/null | grep -q "ft9201"; then
            echo -e "  ${GREEN}✔ Custom patched libfprint-2-2 driver installed${RESET}"
        else
            echo -e "  ${YELLOW}⚠ Custom driver not installed. Run scripts/03-install-fingerprint.sh${RESET}"
        fi
        if systemctl is-active fprintd &>/dev/null; then
            echo -e "  ${GREEN}✔ fprintd daemon service is active${RESET}"
        else
            echo -e "  ${YELLOW}⚠ fprintd service inactive${RESET}"
        fi
    else
        echo -e "  ${YELLOW}⚠ 2808:9338 not enumerated; sensor may be in low-power sleep mode${RESET}"
    fi
else
    echo -e "\n${BOLD}[5/8] 指纹传感器 (FocalTech FT9536W / 2808:9338)${RESET}"
    if command -v lsusb &>/dev/null && lsusb | grep -qi "2808:9338"; then
        echo -e "  ${GREEN}✔ 已检测到指纹硬件 (USB ID 2808:9338 FocalTech Fingerprint)${RESET}"
        if dpkg -s libfprint-2-2 2>/dev/null | grep -q "ft9201"; then
            echo -e "  ${GREEN}✔ 定制修复版 libfprint-2-2 驱动已安装${RESET}"
        else
            echo -e "  ${YELLOW}⚠ 未安装定制驱动包，请运行 scripts/03-install-fingerprint.sh${RESET}"
        fi
        if systemctl is-active fprintd &>/dev/null; then
            echo -e "  ${GREEN}✔ fprintd 守护服务正在运行${RESET}"
        else
            echo -e "  ${YELLOW}⚠ fprintd 服务未激活${RESET}"
        fi
    else
        echo -e "  ${YELLOW}⚠ 未检索到 2808:9338，传感器可能处于待机或休眠状态${RESET}"
    fi
fi

# 6. 重力感应器 (Bosch BMA2x)
if [[ "$UI_LANG" == "en" ]]; then
    echo -e "\n${BOLD}[6/8] Accelerometer & Sensor Subsystem (Bosch BMA2x / BOSC0200)${RESET}"
    if ls -d /sys/bus/iio/devices/iio:device* &>/dev/null; then
        for dev in /sys/bus/iio/devices/iio:device*; do
            NAME=$(cat "${dev}/name" 2>/dev/null || echo "unknown")
            echo -e "  IIO Device: ${GREEN}${NAME}${RESET} (${dev})"
        done
        if [[ -f /etc/udev/hwdb.d/61-sensor-onemix.hwdb ]]; then
            echo -e "  ${GREEN}✔ Found calibrated mounting matrix: /etc/udev/hwdb.d/61-sensor-onemix.hwdb${RESET}"
        else
            echo -e "  ${YELLOW}⚠ Matrix file not found. Run scripts/02-setup-sensor-gyroscope.sh${RESET}"
        fi
    else
        echo -e "  ${RED}✘ No IIO accelerometer device detected in /sys/bus/iio${RESET}"
    fi
else
    echo -e "\n${BOLD}[6/8] 重力感应器 (Bosch BMA2x / BOSC0200)${RESET}"
    if ls -d /sys/bus/iio/devices/iio:device* &>/dev/null; then
        for dev in /sys/bus/iio/devices/iio:device*; do
            NAME=$(cat "${dev}/name" 2>/dev/null || echo "unknown")
            echo -e "  IIO 设备: ${GREEN}${NAME}${RESET} (${dev})"
        done
        if [[ -f /etc/udev/hwdb.d/61-sensor-onemix.hwdb ]]; then
            echo -e "  ${GREEN}✔ 发现已配置的校准矩阵文件: /etc/udev/hwdb.d/61-sensor-onemix.hwdb${RESET}"
        else
            echo -e "  ${YELLOW}⚠ 未找到校准矩阵文件，请运行 scripts/02-setup-sensor-gyroscope.sh${RESET}"
        fi
    else
        echo -e "  ${RED}✘ 未在 /sys/bus/iio 发现重力感应设备${RESET}"
    fi
fi

# 7. 无线与蓝牙 (Intel AC3165)
if [[ "$UI_LANG" == "en" ]]; then
    echo -e "\n${BOLD}[7/8] Wireless & Bluetooth (Intel AC3165)${RESET}"
    if command -v lsusb &>/dev/null && lsusb | grep -qi "8087:0a2a"; then
        echo -e "  ${GREEN}✔ Detected Intel Bluetooth adapter (USB ID 8087:0a2a)${RESET}"
    fi
    if command -v lspci &>/dev/null && lspci | grep -qi "Wireless"; then
        WIFI_NAME=$(lspci | grep -i "Wireless" | cut -d: -f3 | xargs)
        echo -e "  ${GREEN}✔ Detected Wi-Fi adapter: ${WIFI_NAME}${RESET}"
    fi
else
    echo -e "\n${BOLD}[7/8] 无线网络与蓝牙 (Intel AC3165)${RESET}"
    if command -v lsusb &>/dev/null && lsusb | grep -qi "8087:0a2a"; then
        echo -e "  ${GREEN}✔ 已检测到 Intel 蓝牙芯片 (USB ID 8087:0a2a)${RESET}"
    fi
    if command -v lspci &>/dev/null && lspci | grep -qi "Wireless"; then
        WIFI_NAME=$(lspci | grep -i "Wireless" | cut -d: -f3 | xargs)
        echo -e "  ${GREEN}✔ 已检测到 Wi-Fi 网卡: ${WIFI_NAME}${RESET}"
    fi
fi

# 8. 引导器与开机旋转链路
if [[ "$UI_LANG" == "en" ]]; then
    echo -e "\n${BOLD}[8/8] Bootloader & Full Landscape Chain Status${RESET}"
    if grep -q "video=eDP-1:panel_orientation=right_side_up" /proc/cmdline 2>/dev/null; then
        echo -e "  ${GREEN}✔ Kernel cmdline loaded DRM landscape orientation (video=eDP-1:panel_orientation=right_side_up)${RESET}"
    else
        echo -e "  ${YELLOW}⚠ Kernel cmdline missing eDP-1 rotation. Run scripts/01-setup-screen-rotation.sh${RESET}"
    fi

    if [[ -f /boot/efi/EFI/grub-rotated/grubx64.efi ]]; then
        echo -e "  ${GREEN}✔ Standalone Rotated GRUB installed (/boot/efi/EFI/grub-rotated/grubx64.efi)${RESET}"
    else
        echo -e "  ${YELLOW}⚠ Standalone Rotated GRUB not installed. Install via packages/bootloader/install-rotated-grub.sh${RESET}"
    fi

    if command -v efibootmgr &>/dev/null; then
        ROT_BOOT=$(efibootmgr 2>/dev/null | grep -i "grub-rotated" || true)
        if [[ -n "$ROT_BOOT" ]]; then
            echo -e "  ${GREEN}✔ UEFI NVRAM registered Rotated GRUB: ${ROT_BOOT}${RESET}"
            BNEXT=$(efibootmgr 2>/dev/null | grep "^BootNext:" || true)
            if [[ -n "$BNEXT" ]]; then
                echo -e "  ${CYAN}★ ${BNEXT}${RESET}"
            fi
            BORDER=$(efibootmgr 2>/dev/null | grep "^BootOrder:" || true)
            if [[ -n "$BORDER" ]]; then
                echo -e "  ${CYAN}★ ${BORDER}${RESET}"
            fi
        fi
    fi
else
    echo -e "\n${BOLD}[8/8] 引导器与开机全链路旋转状态 (Bootloader & Rotation)${RESET}"
    if grep -q "video=eDP-1:panel_orientation=right_side_up" /proc/cmdline 2>/dev/null; then
        echo -e "  ${GREEN}✔ 内核命令行已加载 DRM 横屏矫正 (video=eDP-1:panel_orientation=right_side_up)${RESET}"
    else
        echo -e "  ${YELLOW}⚠ 当前内核未包含 eDP-1 旋转参数，请运行 scripts/01-setup-screen-rotation.sh${RESET}"
    fi

    if [[ -f /boot/efi/EFI/grub-rotated/grubx64.efi ]]; then
        echo -e "  ${GREEN}✔ 独立横屏 GRUB 已安装 (/boot/efi/EFI/grub-rotated/grubx64.efi)${RESET}"
    else
        echo -e "  ${YELLOW}⚠ 未检测到独立横屏 GRUB，可通过 packages/bootloader/install-rotated-grub.sh 安装${RESET}"
    fi

    if command -v efibootmgr &>/dev/null; then
        ROT_BOOT=$(efibootmgr 2>/dev/null | grep -i "grub-rotated" || true)
        if [[ -n "$ROT_BOOT" ]]; then
            echo -e "  ${GREEN}✔ UEFI NVRAM 已注册横屏 GRUB 项: ${ROT_BOOT}${RESET}"
            BNEXT=$(efibootmgr 2>/dev/null | grep "^BootNext:" || true)
            if [[ -n "$BNEXT" ]]; then
                echo -e "  ${CYAN}★ ${BNEXT}${RESET}"
            fi
            BORDER=$(efibootmgr 2>/dev/null | grep "^BootOrder:" || true)
            if [[ -n "$BORDER" ]]; then
                echo -e "  ${CYAN}★ ${BORDER}${RESET}"
            fi
        fi
    fi
fi

# 附加. 电池健康
if [[ -d /sys/class/power_supply/BAT0 || -d /sys/class/power_supply/BAT1 ]]; then
    BAT_DIR=$(ls -d /sys/class/power_supply/BAT* | head -n1)
    CAP=$(cat "${BAT_DIR}/capacity" 2>/dev/null || echo "Unknown")
    STATUS=$(cat "${BAT_DIR}/status" 2>/dev/null || echo "Unknown")
    if [[ "$UI_LANG" == "en" ]]; then
        echo -e "\n${BOLD}[Battery] Battery Health (${BAT_DIR##*/})${RESET}"
        echo -e "  Charge Level: ${GREEN}${CAP}%${RESET} (${STATUS})"
    else
        echo -e "\n${BOLD}[附加] 电池状态 (${BAT_DIR##*/})${RESET}"
        echo -e "  当前电量: ${GREEN}${CAP}%${RESET} (${STATUS})"
    fi
fi

if [[ "$UI_LANG" == "en" ]]; then
    echo -e "\n${BOLD}${CYAN}Diagnostics Completed${RESET}\n"
else
    echo -e "\n${BOLD}${CYAN}诊断完成${RESET}\n"
fi
