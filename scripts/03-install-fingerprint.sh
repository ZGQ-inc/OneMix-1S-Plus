#!/usr/bin/env bash
# OneMix 1S+ FocalTech FT9536W (2808:9338) 指纹驱动一键安装脚本
# Wraps and invokes packages/fingerprint/install.sh
# Fully Internationalized (i18n): English / 简体中文

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FP_INSTALLER="${REPO_ROOT}/packages/fingerprint/install.sh"
CYAN='\033[36m'
RESET='\033[0m'

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
        echo -e "\033[31m[ERROR]\033[0m This script requires root privileges. Please run with sudo:"
    else
        echo -e "\033[31m[ERROR]\033[0m 本脚本需要 root 权限，请使用 sudo 运行："
    fi
    printf '      %ssudo bash %q' "$CYAN" "$0"
    printf ' %q' "$@"
    printf '%s\n\n' "$RESET"
    exit 1
fi

if [[ ! -f "$FP_INSTALLER" ]]; then
    if [[ "$UI_LANG" == "en" ]]; then
        echo -e "\033[31m[ERROR]\033[0m Fingerprint installer not found: ${FP_INSTALLER}"
    else
        echo -e "\033[31m[ERROR]\033[0m 未找到指纹安装脚本: ${FP_INSTALLER}"
    fi
    exit 1
fi

chmod +x "${REPO_ROOT}/packages/fingerprint/"*.sh
bash "$FP_INSTALLER" "$@"
