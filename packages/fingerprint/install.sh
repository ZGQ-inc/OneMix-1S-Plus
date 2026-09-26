#!/usr/bin/env bash
# FocalTech FT9201 / FT9536 (2808:9338) Fingerprint Driver Installer
# Devices: One-Netbook OneMix 1s/1s+/2/3 Series, GPD Series (2808:9338)
# OS Support: Ubuntu / Kubuntu 20.04 / 22.04 / 24.04 / 26.04 & Debian 11/12/13
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEB_FILE="${SCRIPT_DIR}/libfprint-2-2_1.95.1+tod1-9999ft9201~kubuntu_amd64.deb"

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
    echo "FocalTech FT9201 / FT9536 Fingerprint Driver Installer"
    echo "Target: One-Netbook OneMix 1s+ / OneMix Series / GPD (2808:9338)"
    echo "Tested On: Ubuntu / Kubuntu 24.04 / 26.04 LTS (x86_64)"
else
    echo "FocalTech FT9201 / FT9536 指纹驱动一键安装脚本"
    echo "适用设备: 壹号本 OneMix 1s+ / OneMix 全系列 / GPD (2808:9338)"
    echo "测试环境: Ubuntu / Kubuntu 24.04 / 26.04 LTS (x86_64)"
fi

# 1. 检查 root 权限
if [ "$(id -u)" -ne 0 ]; then
    if [[ "$UI_LANG" == "en" ]]; then
        echo "[-] Error: Please run this script with sudo:"
    else
        echo "[-] 错误: 请使用 sudo 权限运行此脚本:"
    fi
    echo "    sudo bash install.sh"
    exit 1
fi

# 2. 检查安装包文件
if [ ! -f "${DEB_FILE}" ]; then
    if [[ "$UI_LANG" == "en" ]]; then
        echo "[-] Error: Driver package not found: ${DEB_FILE}"
    else
        echo "[-] 错误: 未在当前目录找到驱动安装包: ${DEB_FILE}"
    fi
    exit 1
fi

# 3. 检测硬件
echo ""
if [[ "$UI_LANG" == "en" ]]; then
    echo "[1/6] Checking fingerprint sensor hardware..."
    if lsusb | grep -qi "2808:9338"; then
        echo "[+] Detected sensor: FocalTech FT9201/FT9536 (USB ID 2808:9338)"
    elif lsusb | grep -qi "2808:"; then
        echo "[!] Detected other FocalTech device variant:"
        lsusb | grep -i "2808:"
    else
        echo "[!] Notice: 2808:9338 not enumerated (may be sleeping). Continuing installation..."
    fi
    echo ""
    echo "[2/6] Checking and installing runtime dependencies (fprintd, libpam-fprintd)..."
else
    echo "[1/6] 检查指纹传感器硬件..."
    if lsusb | grep -qi "2808:9338"; then
        echo "[+] 检测到指纹传感器: FocalTech FT9201/FT9536 (USB ID 2808:9338)"
    elif lsusb | grep -qi "2808:"; then
        echo "[!] 检测到其他 FocalTech 指纹设备变种:"
        lsusb | grep -i "2808:"
    else
        echo "[!] 提示: 当前 lsusb 未检索到 2808:9338 设备，可能处于深度睡眠。继续执行安装..."
    fi
    echo ""
    echo "[2/6] 检查并安装运行依赖 (fprintd, libpam-fprintd 等)..."
fi

apt-get update -y || echo "[!] Using local apt cache to install dependencies..."
apt-get install -y --no-install-recommends fprintd libpam-fprintd libnss3 libpixman-1-0 libgudev-1.0-0 || true

if apt-cache show libgusb2a >/dev/null 2>&1; then
    apt-get install -y --no-install-recommends libgusb2a || true
elif apt-cache show libgusb2 >/dev/null 2>&1; then
    apt-get install -y --no-install-recommends libgusb2 || true
fi

# 5. 安装定制驱动 DEB
echo ""
if [[ "$UI_LANG" == "en" ]]; then
    echo "[3/6] Installing custom driver package (fixing FT9536 crash & modern library links)..."
else
    echo "[3/6] 安装专用驱动包 (修复 FT9536 芯片崩溃及现代库兼容)..."
fi
dpkg -i "${DEB_FILE}" || apt-get install -f -y

# 6. 版本锁定防止覆盖
echo ""
if [[ "$UI_LANG" == "en" ]]; then
    echo "[4/6] Holding libfprint-2-2 package (preventing apt upgrade overwrite)..."
else
    echo "[4/6] 锁定 libfprint-2-2 版本 (防止 apt upgrade 覆盖定制驱动)..."
fi
apt-mark hold libfprint-2-2

# 7. 刷新 udev 与动态库
echo ""
if [[ "$UI_LANG" == "en" ]]; then
    echo "[5/6] Updating udev rules and dynamic linker cache..."
else
    echo "[5/6] 配置 udev 规则与动态库链接..."
fi
udevadm control --reload-rules || true
udevadm trigger --action=add --attr-match=idVendor=2808 || true
ldconfig

REAL_USER="${SUDO_USER:-}"
if [ -n "${REAL_USER}" ] && [ "${REAL_USER}" != "root" ]; then
    if getent group plugdev >/dev/null 2>&1; then
        usermod -aG plugdev "${REAL_USER}" || true
        if [[ "$UI_LANG" == "en" ]]; then
            echo "[+] Added user ${REAL_USER} to group plugdev"
        else
            echo "[+] 已将用户 ${REAL_USER} 添加至 plugdev 用户组"
        fi
    fi
fi

# 8. 配置 PAM 认证
echo ""
if [[ "$UI_LANG" == "en" ]]; then
    echo "[6/6] Enabling system fingerprint authentication service..."
else
    echo "[6/6] 启用系统指纹认证服务..."
fi

if command -v pam-auth-update >/dev/null 2>&1; then
    pam-auth-update --package --enable fprintd || pam-auth-update --enable fprintd || true
fi

if [ -f /etc/pam.d/sddm ]; then
    if ! grep -q "pam_fprintd.so" /etc/pam.d/sddm; then
        if [[ "$UI_LANG" == "en" ]]; then
            echo "[+] Configuring SDDM login/lockscreen fingerprint authentication..."
        else
            echo "[+] 配置 SDDM 登录/锁屏界面指纹认证..."
        fi
        cp /etc/pam.d/sddm /etc/pam.d/sddm.bak.ft9201
        sed -i '1a auth [success=1 new_authtok_reqd=1 default=ignore] pam_fprintd.so' /etc/pam.d/sddm
    fi
fi

systemctl enable fprintd.service 2>/dev/null || true
systemctl restart fprintd.service 2>/dev/null || true

echo ""
if [[ "$UI_LANG" == "en" ]]; then
    echo " Driver Installed Successfully!"
    echo "Usage Guide:"
    echo ""
    echo "1. Enroll Fingerprint via Terminal (Recommended):"
    echo "   fprintd-enroll"
    echo "   (Touch sensor when prompted, lift and touch repeatedly until completed)"
    echo ""
    echo "2. Verify Fingerprint:"
    echo "   fprintd-verify"
    echo ""
    echo "3. Desktop GUI Enrollment:"
    echo "   - KDE: System Settings -> Users -> Click current account -> Fingerprint"
    echo "   - GNOME: Settings -> Users -> Fingerprint Login"
    echo ""
    echo "4. Lockscreen & Sudo Authentication:"
    echo "   - Terminal sudo: Run 'sudo -v', touch sensor to elevate without password"
    echo "   - Lockscreen: Press Win+L to lock, touch sensor to unlock instantly"
else
    echo "驱动安装成功！"
    echo "使用指南："
    echo ""
    echo "1. 命令行录入指纹 (推荐):"
    echo "   fprintd-enroll"
    echo "   (看到提示后，用手指触摸传感器，反复轻触并抬起数次直到完成)"
    echo ""
    echo "2. 验证指纹:"
    echo "   fprintd-verify"
    echo ""
    echo "3. 桌面图形界面录入:"
    echo "   - KDE: 系统设置 -> 用户 (Users) -> 点击当前账户 -> 指纹"
    echo "   - GNOME: 设置 -> 用户 -> 指纹登录"
    echo ""
    echo "4. 锁屏与提权测试:"
    echo "   - 终端提权: 运行 sudo -v，按压指纹即可完成提权（直接回车可切回密码）"
    echo "   - 锁屏解锁: 锁屏后（Win+L），轻触指纹直接解锁进入桌面"
fi
echo ""
