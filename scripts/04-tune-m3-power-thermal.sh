#!/usr/bin/env bash
# OneMix 1S+ (Intel Core m3-8100Y) 功耗与温控调优脚本
# CPU: Amber Lake-Y 14nm, 2C/4T, TDP 5W~8W
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
MODE="menu"
for arg in "$@"; do
    case "$arg" in
        --lang=en|-en|--en) UI_LANG="en" ;;
        --lang=zh|-zh|--zh) UI_LANG="zh" ;;
        quiet|battery|save|balanced|default|perf|performance|status|menu) MODE="$arg" ;;
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

show_status() {
    if [[ "$UI_LANG" == "en" ]]; then
        echo -e "\n${BOLD}${CYAN}OneMix 1S+ (m3-8100Y) Current Power & Thermal State${RESET}"
        if [[ -d /sys/devices/system/cpu/cpu0/cpufreq ]]; then
            GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
            echo -e "  CPU Scaling Governor:       ${GREEN}${GOVERNOR}${RESET}"
        fi
        if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference ]]; then
            EPP=$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null || echo "unknown")
            echo -e "  Energy Perf Preference (EPP): ${GREEN}${EPP}${RESET}"
        fi
        RAPL_DIR="/sys/class/powercap/intel-rapl/intel-rapl:0"
        if [[ -d "$RAPL_DIR" ]]; then
            if [[ -f "${RAPL_DIR}/constraint_0_power_limit_uw" ]]; then
                PL1_W=$(awk '{print $1 / 1000000}' "${RAPL_DIR}/constraint_0_power_limit_uw")
                echo -e "  Intel RAPL PL1 (Sustained): ${GREEN}${PL1_W} W${RESET}"
            fi
            if [[ -f "${RAPL_DIR}/constraint_1_power_limit_uw" ]]; then
                PL2_W=$(awk '{print $1 / 1000000}' "${RAPL_DIR}/constraint_1_power_limit_uw")
                echo -e "  Intel RAPL PL2 (Turbo Peak): ${GREEN}${PL2_W} W${RESET}"
            fi
        fi
        if [[ -f /sys/power/mem_sleep ]]; then
            MEM_SLEEP=$(cat /sys/power/mem_sleep 2>/dev/null || echo "unknown")
            echo -e "  Kernel Sleep Mode:          ${GREEN}${MEM_SLEEP}${RESET}"
        fi
    else
        echo -e "\n${BOLD}${CYAN}OneMix 1S+ (m3-8100Y) 当前电源与能耗状态${RESET}"
        if [[ -d /sys/devices/system/cpu/cpu0/cpufreq ]]; then
            GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")
            echo -e "  当前 CPU 调频策略 (Governor): ${GREEN}${GOVERNOR}${RESET}"
        fi
        if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference ]]; then
            EPP=$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null || echo "unknown")
            echo -e "  能量性能偏好 (EPP):         ${GREEN}${EPP}${RESET}"
        fi
        RAPL_DIR="/sys/class/powercap/intel-rapl/intel-rapl:0"
        if [[ -d "$RAPL_DIR" ]]; then
            if [[ -f "${RAPL_DIR}/constraint_0_power_limit_uw" ]]; then
                PL1_W=$(awk '{print $1 / 1000000}' "${RAPL_DIR}/constraint_0_power_limit_uw")
                echo -e "  Intel RAPL PL1 (长时功耗墙):  ${GREEN}${PL1_W} W${RESET}"
            fi
            if [[ -f "${RAPL_DIR}/constraint_1_power_limit_uw" ]]; then
                PL2_W=$(awk '{print $1 / 1000000}' "${RAPL_DIR}/constraint_1_power_limit_uw")
                echo -e "  Intel RAPL PL2 (瞬时睿频墙):  ${GREEN}${PL2_W} W${RESET}"
            fi
        fi
        if [[ -f /sys/power/mem_sleep ]]; then
            MEM_SLEEP=$(cat /sys/power/mem_sleep 2>/dev/null || echo "unknown")
            echo -e "  系统睡眠挂起模式:           ${GREEN}${MEM_SLEEP}${RESET}"
        fi
    fi
}

apply_profile() {
    local pl1_w=$1
    local pl2_w=$2
    local epp=$3
    local profile_name=$4

    if [[ "$UI_LANG" == "en" ]]; then
        log_info "Applying profile: ${BOLD}${profile_name}${RESET} (PL1=${pl1_w}W, PL2=${pl2_w}W, EPP=${epp})..."
    else
        log_info "正在应用模式: ${BOLD}${profile_name}${RESET} (PL1=${pl1_w}W, PL2=${pl2_w}W, EPP=${epp})..."
    fi

    # 1. 设置 EPP
    for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
        if [[ -f "$f" ]]; then
            echo "$epp" > "$f" 2>/dev/null || true
        fi
    done

    # 2. 设置 Intel RAPL 功耗限制
    RAPL_DIR="/sys/class/powercap/intel-rapl/intel-rapl:0"
    if [[ -d "$RAPL_DIR" ]]; then
        local pl1_uw=$((pl1_w * 1000000))
        local pl2_uw=$((pl2_w * 1000000))

        if [[ -f "${RAPL_DIR}/constraint_0_power_limit_uw" ]]; then
            echo "$pl1_uw" > "${RAPL_DIR}/constraint_0_power_limit_uw" 2>/dev/null || true
        fi
        if [[ -f "${RAPL_DIR}/constraint_1_power_limit_uw" ]]; then
            echo "$pl2_uw" > "${RAPL_DIR}/constraint_1_power_limit_uw" 2>/dev/null || true
        fi
    fi

    if [[ "$UI_LANG" == "en" ]]; then
        log_ok "Profile [${profile_name}] applied successfully!"
    else
        log_ok "模式 [${profile_name}] 设置成功！"
    fi
    show_status
}

case "$MODE" in
    quiet|battery|save)
        apply_profile 4 7 "power" "$( [[ "$UI_LANG" == "en" ]] && echo "Battery / Quiet" || echo "省电静音模式" )"
        exit 0
        ;;
    balanced|default)
        apply_profile 7 10 "balance_performance" "$( [[ "$UI_LANG" == "en" ]] && echo "Balanced" || echo "日常均衡模式" )"
        exit 0
        ;;
    perf|performance)
        apply_profile 9 12 "performance" "$( [[ "$UI_LANG" == "en" ]] && echo "Performance" || echo "极致性能模式" )"
        exit 0
        ;;
    status)
        show_status
        exit 0
        ;;
    menu|*)
        show_status
        if [[ "$UI_LANG" == "en" ]]; then
            echo -e "Select Power & Thermal Profile:"
            echo -e "  ${BOLD}[1] Battery / Quiet Mode${RESET}        : PL1=4.5W, PL2=7W  (Low heat, quiet fan, max battery)"
            echo -e "  ${BOLD}[2] Balanced Mode (Recommended)${RESET}  : PL1=7W,   PL2=10W (Snappy 3.4GHz burst & efficiency)"
            echo -e "  ${BOLD}[3] Performance Mode${RESET}            : PL1=9W,   PL2=12W (Plugged in, compilation, benchmarks)"
            echo -e "  ${BOLD}[4] Exit${RESET}"
            echo ""
            read -r -p "Enter choice [1-4]: " choice
            case "$choice" in
                1) apply_profile 4 7 "power" "Battery / Quiet" ;;
                2) apply_profile 7 10 "balance_performance" "Balanced" ;;
                3) apply_profile 9 12 "performance" "Performance" ;;
                *) echo "Exited." ;;
            esac
        else
            echo -e "请选择能耗与温控配置模式："
            echo -e "  ${BOLD}[1] 省电静音模式 (Battery / Quiet)${RESET}    : PL1=4.5W, PL2=7W  (低发热、风扇静音、电池续航长)"
            echo -e "  ${BOLD}[2] 日常均衡模式 (Balanced - 推荐)${RESET} : PL1=7W,   PL2=10W (兼顾单核 3.4GHz 爆发与日常流畅)"
            echo -e "  ${BOLD}[3] 极致性能模式 (Performance)${RESET}     : PL1=9W,   PL2=12W (插电编译、跑分或游戏，发热较高)"
            echo -e "  ${BOLD}[4] 退出${RESET}"
            echo ""
            read -r -p "请输入选项 [1-4]: " choice
            case "$choice" in
                1) apply_profile 4 7 "power" "省电静音模式" ;;
                2) apply_profile 7 10 "balance_performance" "日常均衡模式" ;;
                3) apply_profile 9 12 "performance" "极致性能模式" ;;
                *) echo "已退出。" ;;
            esac
        fi
        ;;
esac
