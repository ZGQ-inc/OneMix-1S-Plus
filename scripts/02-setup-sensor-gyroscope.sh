#!/usr/bin/env bash
# OneMix 1S+ 重力感应校准与自动旋转脚本 (Sensor & Gyroscope Calibration)
# 传感器芯片: Bosch BMA2x (ACPI ID: BOSC0200)
# Fully Internationalized (i18n): English / 简体中文

set -euo pipefail

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
    printf '      %ssudo bash %q' "$CYAN" "$0"
    printf ' %q' "$@"
    printf '%s\n\n' "$RESET"
    exit 1
fi

if [[ "$UI_LANG" == "en" ]]; then
    echo -e "${BOLD}${CYAN}[OneMix 1S+] Accelerometer Calibration & Auto-Rotation Setup${RESET}"
else
    echo -e "${BOLD}${CYAN}【OneMix 1S+】重力感应器校准与自动旋转配置${RESET}"
fi

# 1. 检查并安装 iio-sensor-proxy
if [[ "$UI_LANG" == "en" ]]; then
    log_info "1/3 Checking and installing iio-sensor-proxy daemon..."
else
    log_info "1/3 正在检查并安装 iio-sensor-proxy 守护进程..."
fi
if ! command -v monitor-sensor &>/dev/null; then
    apt-get update -qq
    apt-get install -y iio-sensor-proxy
    if [[ "$UI_LANG" == "en" ]]; then
        log_ok "iio-sensor-proxy installed successfully!"
    else
        log_ok "iio-sensor-proxy 安装完成！"
    fi
else
    if [[ "$UI_LANG" == "en" ]]; then
        log_ok "iio-sensor-proxy is already installed."
    else
        log_ok "iio-sensor-proxy 已经安装。"
    fi
fi

# 2. 写入 udev 硬件数据库校准规则
if [[ "$UI_LANG" == "en" ]]; then
    log_info "2/3 Writing Bosch BMA2x (BOSC0200) calibrated mounting matrix..."
else
    log_info "2/3 正在写入 Bosch BMA2x (BOSC0200) 精确安装矩阵..."
fi
HWDB_FILE="/etc/udev/hwdb.d/61-sensor-onemix.hwdb"
mkdir -p /etc/udev/hwdb.d

cat << 'EOF' > "$HWDB_FILE"
# One-Netbook OneMix 1S+ Gyroscope / Accelerometer Calibration
# Sensor: Bosch Sensortec BMA2x (ACPI ID: BOSC0200)
# Resolves 90-degree phase shift and inverse orientation in Linux/KDE
# Note: Indentation on ACCEL_MOUNT_MATRIX must be exactly one space.
sensor:modalias:acpi:BOSC0200*:dmi:*
 ACCEL_MOUNT_MATRIX=0, 1, 0; 1, 0, 0; 0, 0, 1
EOF

if [[ "$UI_LANG" == "en" ]]; then
    log_ok "Hardware database rule written: ${HWDB_FILE}"
    log_info "3/3 Updating systemd-hwdb and reloading device triggers..."
else
    log_ok "规则已写入: ${HWDB_FILE}"
    log_info "3/3 正在更新 systemd-hwdb 并重载设备触发器..."
fi

systemd-hwdb update
udevadm trigger -v --sysname-match=iio:device* || true
systemctl restart iio-sensor-proxy

if [[ "$UI_LANG" == "en" ]]; then
    log_ok "Hardware database reloaded successfully!"
    echo -e "${BOLD}${GREEN}[COMPLETED] Accelerometer calibrated successfully!${RESET}"
    echo -e "To enable auto-rotation:"
    echo -e "  1. Open [System Settings] -> [Display and Monitor]"
    echo -e "  2. Check [Automatic screen rotation]"
    echo -e "  3. Rotate your OneMix 1S+ (landscape, portrait, inverted); screen will adapt 360°!"
    echo -e "\nTo monitor real-time sensor orientation events in terminal, run:"
    echo -e "      ${CYAN}monitor-sensor${RESET}\n"
else
    log_ok "硬件数据库更新并重载成功！"
    echo -e "${BOLD}${GREEN}【完成】重力感应器已成功校准！${RESET}"
    echo -e "启用自动转屏步骤："
    echo -e "  1. 打开【系统设置 (System Settings)】 -> 【显示和监视器 (Display and Monitor)】"
    echo -e "  2. 勾选【根据方向传感器自动旋转 (Automatic screen rotation)】"
    echo -e "  3. 旋转你的 OneMix 1S+（横屏、竖屏、倒置），屏幕将 360° 自适应精准对齐！"
    echo -e "\n如需在终端实时监控重力姿态数据，可运行："
    echo -e "      ${CYAN}monitor-sensor${RESET}\n"
fi
