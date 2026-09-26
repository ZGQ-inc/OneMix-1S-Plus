#!/usr/bin/env bash
# FocalTech FT9201 / FT9536 指纹驱动一键卸载 / 还原脚本
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
    echo "FocalTech FT9201 / FT9536 Fingerprint Driver Uninstaller"
else
    echo "FocalTech FT9201 / FT9536 指纹驱动卸载 / 还原官方脚本"
fi

if [ "$(id -u)" -ne 0 ]; then
    if [[ "$UI_LANG" == "en" ]]; then
        echo "[-] Error: Please run this script with sudo: sudo bash uninstall.sh"
    else
        echo "[-] 错误: 请使用 sudo 权限运行此脚本: sudo bash uninstall.sh"
    fi
    exit 1
fi

if [[ "$UI_LANG" == "en" ]]; then
    echo "[1/4] Unholding libfprint-2-2 package..."
    apt-mark unhold libfprint-2-2 || true
    echo "[2/4] Reinstalling upstream distribution libfprint-2-2..."
    apt-get install --reinstall -y libfprint-2-2
    echo "[3/4] Cleaning custom udev rules and SDDM configuration..."
    rm -f /usr/lib/udev/rules.d/60-libfprint-2-ft9201.rules /etc/udev/rules.d/60-libfprint-2-ft9201.rules
    if [ -f /etc/pam.d/sddm.bak.ft9201 ]; then
        mv /etc/pam.d/sddm.bak.ft9201 /etc/pam.d/sddm
    fi
    echo "[4/4] Reloading udev and system services..."
    udevadm control --reload-rules || true
    ldconfig
    systemctl restart fprintd.service 2>/dev/null || true
    echo ""
    echo "[+] Custom driver uninstalled and restored to stock distribution packages."
else
    echo "[1/4] 解除 libfprint-2-2 软件包版本锁定..."
    apt-mark unhold libfprint-2-2 || true
    echo "[2/4] 还原系统官方发行版 libfprint-2-2..."
    apt-get install --reinstall -y libfprint-2-2
    echo "[3/4] 清理自定义 udev 规则与 SDDM 配置..."
    rm -f /usr/lib/udev/rules.d/60-libfprint-2-ft9201.rules /etc/udev/rules.d/60-libfprint-2-ft9201.rules
    if [ -f /etc/pam.d/sddm.bak.ft9201 ]; then
        mv /etc/pam.d/sddm.bak.ft9201 /etc/pam.d/sddm
    fi
    echo "[4/4] 重新加载 udev 与系统服务..."
    udevadm control --reload-rules || true
    ldconfig
    systemctl restart fprintd.service 2>/dev/null || true
    echo ""
    echo "[+] 驱动已成功卸载并还原为系统官方版本。"
fi
