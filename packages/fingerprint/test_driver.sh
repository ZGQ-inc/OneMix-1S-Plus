#!/usr/bin/env bash
# FocalTech FT9201 / FT9536 指纹驱动与硬件诊断脚本
# Fully Internationalized (i18n): English / 简体中文
set -euo pipefail

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
    echo "FocalTech FT9201 / FT9536 Driver & Hardware Diagnostics"
    echo "--- 1. USB Hardware Detection ---"
    if lsusb | grep -i "2808:9338"; then
        echo "[✓] Successfully detected FocalTech 2808:9338 fingerprint sensor"
    elif lsusb | grep -i "2808:"; then
        echo "[!] Detected other FocalTech 2808 device variant:"
        lsusb | grep -i "2808:"
    else
        echo "[X] 2808 hardware not detected (may be asleep, try touching or rebooting)"
    fi

    echo ""
    echo "--- 2. Installed Packages & Driver Versions ---"
    dpkg -l libfprint-2-2 fprintd libpam-fprintd 2>/dev/null | grep '^ii' || true

    echo ""
    echo "--- 3. Dynamic Linker Symbols ---"
    if [ -f /usr/lib/x86_64-linux-gnu/libfprint-2.so.2 ]; then
        UNDEF=$(ldd -r /usr/lib/x86_64-linux-gnu/libfprint-2.so.2 2>&1 | grep -i undefined || true)
        if [ -z "$UNDEF" ]; then
            echo "[✓] All dynamic symbols resolved cleanly (0 undefined symbols)"
        else
            echo "[!] Undefined symbols detected:"
            echo "$UNDEF"
        fi
    else
        echo "[X] /usr/lib/x86_64-linux-gnu/libfprint-2.so.2 not found"
    fi

    echo ""
    echo "--- 4. udev Permissions & Device Properties ---"
    DEV_PATH=$(find /sys/bus/usb/devices/ -maxdepth 2 -name "idVendor" -exec grep -l "2808" {} + 2>/dev/null | head -n1 | sed 's#/idVendor##' || true)
    if [ -n "$DEV_PATH" ]; then
        echo "[✓] Device sysfs path: $DEV_PATH"
        udevadm info -q property -p "$DEV_PATH" | grep -E '(LIBFPRINT|DEVNAME|TAGS)' || true
    else
        echo "[!] 2808 device path not currently found in sysfs"
    fi

    echo ""
    echo "--- 5. fprintd Service Status ---"
    systemctl status fprintd.service --no-pager || true

    echo ""
    echo "--- 6. Fingerprint Enrolled Check ---"
    if [ -n "${USER:-}" ]; then
        fprintd-list "$USER" 2>/dev/null || echo "[Notice] To list enrolled fingers, run: fprintd-list $USER"
    fi

    echo ""
    echo "Diagnostics complete. To enroll fingers, run: fprintd-enroll"
else
    echo "FocalTech FT9201 / FT9536 硬件与驱动状态诊断"
    echo "--- 1. USB 硬件识别检测 ---"
    if lsusb | grep -i "2808:9338"; then
        echo "[✓] 成功检测到 FocalTech 2808:9338 指纹传感器"
    elif lsusb | grep -i "2808:"; then
        echo "[!] 检测到其他 FocalTech 2808 设备:"
        lsusb | grep -i "2808:"
    else
        echo "[X] 未检测到 2808 硬件，可能处于节电关闭状态，请尝试按压或重启"
    fi

    echo ""
    echo "--- 2. 安装包与驱动版本 ---"
    dpkg -l libfprint-2-2 fprintd libpam-fprintd 2>/dev/null | grep '^ii' || true

    echo ""
    echo "--- 3. 驱动符号解析 (是否缺失符号) ---"
    if [ -f /usr/lib/x86_64-linux-gnu/libfprint-2.so.2 ]; then
        UNDEF=$(ldd -r /usr/lib/x86_64-linux-gnu/libfprint-2.so.2 2>&1 | grep -i undefined || true)
        if [ -z "$UNDEF" ]; then
            echo "[✓] 所有动态链接符号完全正常 (0 undefined symbols)"
        else
            echo "[!] 存在未定义符号:"
            echo "$UNDEF"
        fi
    else
        echo "[X] 未找到 /usr/lib/x86_64-linux-gnu/libfprint-2.so.2"
    fi

    echo ""
    echo "--- 4. udev 权限与访问标记 ---"
    DEV_PATH=$(find /sys/bus/usb/devices/ -maxdepth 2 -name "idVendor" -exec grep -l "2808" {} + 2>/dev/null | head -n1 | sed 's#/idVendor##' || true)
    if [ -n "$DEV_PATH" ]; then
        echo "[✓] 设备 sysfs 路径: $DEV_PATH"
        udevadm info -q property -p "$DEV_PATH" | grep -E '(LIBFPRINT|DEVNAME|TAGS)' || true
    else
        echo "[!] 暂未在 sysfs 中定位到 2808 设备"
    fi

    echo ""
    echo "--- 5. fprintd 服务状态 ---"
    systemctl status fprintd.service --no-pager || true

    echo ""
    echo "--- 6. 指纹设备状态检测 ---"
    if [ -n "${USER:-}" ]; then
        fprintd-list "$USER" 2>/dev/null || echo "[提示] 查看指纹列表需在本地图形会话中执行: fprintd-list $USER (或使用 sudo fprintd-list $USER)"
    fi

    echo ""
    echo "诊断完成。如需录入指纹，请直接执行: fprintd-enroll"
fi
